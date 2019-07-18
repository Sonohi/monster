classdef Monster3GPP38901 < matlab.mixin.Copyable
	% Monster3GPP38901 defines a class for the 3GPP channel model specified in 38.901
	%
	% :StationConfigs:
	% :Channel:
	% :TempSignalVariables:
	% :Pairings:
	% :LinkConditions:
	%
	
	properties
		StationConfigs;
		Channel;
		TempSignalVariables = struct();
		Pairings = [];
		LinkConditions = struct();
	end
	
	methods
		function obj = Monster3GPP38901(MonsterChannel, Stations)
			obj.Channel = MonsterChannel;
			obj.setupStationConfigs(Stations);
			obj.createSpatialMaps();
			obj.LinkConditions.downlink = [];
			obj.LinkConditions.uplink = [];
		end
		
		function setupStationConfigs(obj, Stations)
			% Setup structure for Station configs
			% 
			% :obj:
			% :Stations
			%

			for stationIdx = 1:length(Stations)
				station = Stations(stationIdx);
				stationString = sprintf('station%i',station.NCellID);
				obj.StationConfigs.(stationString) = struct();
				obj.StationConfigs.(stationString).Tx = station.Tx;
				obj.StationConfigs.(stationString).Position = station.Position;
				obj.StationConfigs.(stationString).Seed = station.Seed;
				obj.StationConfigs.(stationString).LSP = lsp3gpp38901(obj.Channel.getAreaType(station));
			end
		end
		
		function propagateWaveforms(obj, Stations, Users, Mode)
			% propagateWaveforms
			%
			% :onj:
			%	:Stations:
			% :Users:
			% :Mode:
			%
			
			Pairing = obj.Channel.getPairing(Stations, Mode);
			obj.Pairings = Pairing;
			numLinks = length(Pairing(1,:));
			
			obj.LinkConditions.(Mode) = cell(numLinks,1);
				
			for i = 1:numLinks
				obj.clearTempVariables()
				% Local copy for mutation
				station = Stations([Stations.NCellID] == Pairing(1,i));
				user = Users(find([Users.NCellID] == Pairing(2,i))); %#ok
				
				% Set waveform to be manipulated
				switch Mode
					case 'downlink'
						obj.setWaveform(station)
					case 'uplink'
						obj.setWaveform(user)
				end
				
				% Calculate recieved power between station and user
				[receivedPower, receivedPowerWatt] = obj.computeLinkBudget(station, user, Mode);
				obj.TempSignalVariables.RxPower = receivedPower;

				% Calculate SNR using thermal noise
				[SNR, SNRdB, noisePower] = obj.computeSNR();
				obj.TempSignalVariables.RxSNR = SNR;
				obj.TempSignalVariables.RxSNRdB = SNRdB;

				% Add/compute interference
				SINR = obj.computeSINR(station, user, Stations, receivedPowerWatt, noisePower, Mode);
				obj.TempSignalVariables.RxSINR = SINR;
				obj.TempSignalVariables.RxSINRdB = 10*log10(SINR);

				% Compute N0
				N0 = obj.computeSpectralNoiseDensity(station, Mode);

				% Add AWGN
				noise = N0*complex(randn(size(obj.TempSignalVariables.RxWaveform)), randn(size(obj.TempSignalVariables.RxWaveform)));
				rxSig = obj.TempSignalVariables.RxWaveform + noise;
				obj.TempSignalVariables.RxWaveform = rxSig;

				% Add fading
				if obj.Channel.enableFading
					obj.addFading(station, user, Mode);
				end

				% Receive signal at Rx module
				switch Mode
					case 'downlink'
						obj.setReceivedSignal(user);
					case 'uplink'
						obj.setReceivedSignal(station, user);
				end

				% Store in channel variable
				obj.storeLinkCondition(i, Mode)
				
			end
		end
		
		function N0 = computeSpectralNoiseDensity(obj, Station, Mode)
			% Compute spectral noise density NO	
			%
			% :param obj:
			% :param Station:
			% :param Mode:
			% :returns N0:
			%
			% TODO: Find citation for this computation. It's partly taken from matworks - however there is a theoretical equation for the symbol energy of OFDM signals.
			%

			switch Mode
				case 'downlink'
					Es = sqrt(2.0*Station.CellRefP*double(obj.TempSignalVariables.RxWaveformInfo.Nfft));
					N0 = 1/(Es*sqrt(obj.TempSignalVariables.RxSINR));
				case 'uplink'
					N0 = 1/(sqrt(obj.TempSignalVariables.RxSINR)  * sqrt(double(obj.TempSignalVariables.RxWaveformInfo.Nfft)))/sqrt(2);
			end

		end 

		function [SNR, SNRdB, thermalNoise] = computeSNR(obj)
			% Calculate SNR using thermal noise. Thermal noise is bandwidth dependent.
			%
			% :param obj:
			% :returns SNR:
			% :returns SNRdB:
			% :returns thermalNoise: 
			%

			[thermalLossdBm, thermalNoise] = thermalLoss(obj.TempSignalVariables.RxWaveform, obj.TempSignalVariables.RxWaveformInfo.SamplingRate);
			rxNoiseFloor = thermalLossdBm;
			SNRdB = obj.TempSignalVariables.RxPower-rxNoiseFloor;
			SNR = 10.^((SNRdB)./10);
		end


		function receivedPower = getreceivedPowerMatrix(obj, station, user, sampleGrid)
			% Used for obtaining a SINR estimation of a given position
			%
			% :param obj:
			% :param station:
			% :param user:
			% :param sampleGrid:
			% :returns receivedPower:
			%

			obj.TempSignalVariables.RxWaveform = station.Tx.Waveform; % Temp variable for BW indication
			obj.TempSignalVariables.RxWaveformInfo = station.Tx.WaveformInfo; % Temp variable for BW indication
			[receivedPower, receivedPowerWatt] = obj.computeLinkBudget(station, user, 'downlink', sampleGrid);
			%obj.TempSignalVariables.RxPower = receivedPower;
			%[SNR, ~, noisePower] = obj.computeSNR();
			%TODO: make computeSINR matrix compatible
			%SINR = obj.computeSINR(station, user, Stations, receivedPowerWatt, noisePower, 'downlink');
			obj.clearTempVariables();
		end

		function [SINR] = computeSINR(obj, station, user, Stations, receivedPowerWatt, noisePower, Mode)
			% Compute SINR using received power and the noise power.
			% Interference is given as the power of the received signal, given the power of the associated base station, over the power of the neighboring base stations.
			% 
			% :param obj:
			% :param station:
			% :param user:
			% :param Stations:
			% :param receivedPowerWatt:
			% :param noisePower:
			% :param Mode:
			% :returns SINR:
			%
			% v1. InterferenceType Full assumes full power, thus the SINR computation can be done using just the link budget.
			% TODO: Add waveform type interference. 
			% TODO: clean up function arguments.
			%

			if strcmp(obj.Channel.InterferenceType,'Full')
				interferingStations = obj.Channel.getInterferingStations(station, Stations);
				listCellPower = obj.listCellPower(user, interferingStations, Mode);
				
				intStations  = fieldnames(listCellPower);
				intPower = 0;
				% Sum power from interfering stations
				for intStation = 1:length(fieldnames(listCellPower))
					intPower = intPower + listCellPower.(intStations{intStation}).receivedPowerWatt;
				end

				SINR = obj.Channel.calculateSINR(receivedPowerWatt, intPower, noisePower);
			else
				SINR = obj.TempSignalVariables.RxSNR;
			end
		end

		function SINR = listSINR(obj, User, Stations, Mode)
			% Get list of SINR for all stations, assuming they all interfere.
			% TODO: Find interfering stations based on class
			% 
			% :param User: One user
			% :param Stations: Multiple eNB's
			% :param Mode: Mode of transmission.
			% :returns SINR: List of SINR for each station

			obj.Channel.Logger.log('func listSINR: Interference is considered intra-class eNB stations','WRN')


			% Get received power for each station
			for iStation = 1:length(Stations)
				station = Stations(iStation);
				[~, receivedPower(iStation)] = obj.computeLinkBudget(station, User, Mode);
			end

			% Compute SINR from each station
			for iStation = 1:length(Stations)
				station = Stations(iStation);
				stationPower = receivedPower(iStation);
				interferingPower = sum(receivedPower(1:end ~= iStation));
				[~, thermalNoise] = thermalLoss();
				SINR(iStation) = 10*log10(obj.Channel.calculateSINR(stationPower, interferingPower, thermalNoise));
			end

		end

		function list = listCellPower(obj, User, Stations, Mode)
			% Get list of recieved power from all stations
			%
			% :param obj:
			% :param User:
			% :param Stations:
			% :param Mode:
			% :returns list:
			%

			list = struct();
			for iStation = 1:length(Stations)
				station = Stations(iStation);
				stationStr = sprintf('stationNCellID%i',station.NCellID);
				list.(stationStr).receivedPowerdBm = obj.computeLinkBudget(station, User, Mode);
				list.(stationStr).receivedPowerWatt = 10^((list.(stationStr).receivedPowerdBm-30)/10);
				list.(stationStr).NCellID = station.NCellID;
			end
			
		end


		
		function [receivedPower, receivedPowerWatt] = computeLinkBudget(obj, Station, User, mode, varargin)
			% Compute link budget for Tx -> Rx
			% 
			% :param obj:
			% :param Station:
			% :param User:
			% :param mode:
			% :returns receivedPower:
			% :returns receivedPowerWatt:
			%
			% This requires a :meth:`computePathLoss` method, which is supplied by child classes.
			% returns updated RxPwdBm of RxNode.Rx
			% The channel is reciprocal in terms of received power, thus the path
			% loss is extracted from channel conditions provided by
			%

			% construct a structure for handling variables
			rxConfig = struct()
			txConfig = struct()

			% Check if the link budget is required f or a single tx -> rx, or a grid of positions
			% TODO: add Z value (height)
			if isempty(varargin)
				[X, Y] = meshgrid(varargin{1}(1,:), varargin{1}(2,:));
			else
				X = User.Position(1);
				Y = User.Position(2);
			end

			positions = [X Y];
				
			rxConfig.d2d = arrayfun(@(x,y) obj.Channel.getDistance(Station.Position(1:2),[x y]), X, Y);
			rxConfig.d3d = arrayfun(@(x,y) obj.Channel.getDistance(Station.Position(1:3),[x y User.Position(3)]), X, Y);

			
			% TODO: fix
			[rxConfig.LOS, prop] = obj.Channel.isLinkLOS(Station, User, false, rxConfig.d2d);
			if ~isnan(prop)
				rxConfig.LOS = obj.spatialLOSstate(Station, [X Y], prop);
			end

			switch mode
				case 'downlink'
					txConfig.hBs = Station.Position(3);
					txConfig.areaType = obj.Channel.getAreaType(Station);
					txConfig.seed = obj.Channel.getLinkSeed(User, Station);
					txConfig.freq = Station.Tx.Freq;

				case 'uplink'
					txConfig.hBs = Station.Position(3);
					txConfig.areaType = obj.Channel.getAreaType(Station);
					txConfig.seed = obj.Channel.getLinkSeed(User, Station);
					txConfig.Freq = User.Tx.Freq;
					
			end

			shadowing = obj.Channel.enableShadowing;
			if shadowing
				%find XCorr for each position
				rxConfig.xCorr = arrayfun(@(x,y,z) obj.computeShadowingLoss(TxNode, [x y], z), reshape(positions(:,1),size(LOS)), reshape(positions(:,2),size(LOS)), LOS );
			else 
				rxConfig.xCorr = 0;
			end

			EIRPdBm = arrayfun(@(x,y) Station.Tx.getEIRPdBm(Station.Position, [x y]), X, Y);
			DownlinkUeLoss = arrayfun(@(x,y) User.Rx.getLoss(Station.Position, [x y]), X, Y);
			lossdBm = obj.computePathLoss(txConfig, rxConfig);


			switch mode
				case 'downlink'
					receivedPower = EIRPdBm-lossdB+DownlinkUeLoss; %dBm
				case 'uplink'
					EIRPdBm = User.Tx.getEIRPdBm;
					receivedPower = EIRPdBm-lossdB-Station.Rx.NoiseFigure; %dBm
			end

			receivedPowerWatt = 10^((receivedPower-30)./10);
		end
		


		function [lossdB] = computePathLoss(obj, txConfig, rxConfig)
			% Computes path loss. uses the following parameters
			% TODO revise function documentation format
			% ..todo:: Compute indoor depth from mobility class
			%
			% * `f` - Frequency in GHz
			% * `hBs` - Height of Tx
			% * `hUt` - height of Rx
			% * `d2d` - Distance in 2D
			% * `d3d` - Distance in 3D
			% * `LOS` - Link LOS boolean, determined by :meth:`ch.SonohiChannel.isLinkLOS`
			% * `shadowing` - Boolean for enabling/disabling shadowing using log-normal distribution
			% * `avgBuilding` - Average height of buildings
			% * `avgStreetWidth` - Average width of the streets
			% * `varargin` -matrix forms of distance 2D, 3D and grid of positions 
			
			% Extract transmitter configurations. All scalar values.
			hBs = txConfig.hBs;
			freq = txConfig.freq;
			areaType = txConfig.areaType;
			
			% Extract receiver configuration, can be arrays.
			hUt = rxConfig.hUt;
			distance2d = rxConfig.d2d;
			distance3d = rxConfig.d3d;
			LOS = rxConfig.LOS;
			LOSprop = rxConfig.LOSprop;
			xCorr = rxConfig.shadowingLoss; 

			assert(length(hUt) == length(distance2d))
			assert(length(hUt) == length(distance3d))
			assert(length(hUt) == length(LOS))
			
			
			% Check whether we have buildings in the scenario
			if ~isempty(obj.Channel.BuildingFootprints)
				avgBuilding = mean(obj.Channel.BuildingFootprints(:,5));
				avgStreetWidth = obj.Channel.BuildingFootprints(2,2)-obj.Channel.BuildingFootprints(1,4);
			else
				avgBuilding = 0;
				avgStreetWidth = 0;
			end
			
			try
				lossdB = loss3gpp38901(areatype, distance2d, distance3d, f, hBs, hUt, avgBuilding, avgStreetWidth, LOS);
			catch ME
				if strcmp(ME.identifier,'Pathloss3GPP:Range')
						minRange = 10;
						lossdB = loss3gpp38901(areatype, minRange, distance3d, f, hBs, hUt, avgBuilding, avgStreetWidth, LOS);
				end
			end
			
			if RxNode.Mobility.Indoor
				% Low loss model consists of LOS
				materials = {'StandardGlass', 'Concrete'; 0.3, 0.7};
				sigma_P = 4.4;
				
				% High loss model consists of
				%materials = {'IIRGlass', 'Concrete'; 0.7, 0.3}
				%sigma_P = 6.5;
				
				PL_tw = buildingloss3gpp38901(materials, f);
				
				% If indoor depth can be computed
				%PL_in = indoorloss3gpp38901('', 2d_in);
				% Otherwise sample from uniform
				PL_in  = indoorloss3gpp38901(areatype);
				indoorLosses = PL_tw + PL_in + randn(1, 1)*sigma_P;
				lossdB = lossdB + indoorLosses;
			end
			
			% Add possible shadowing loss
			lossdB = lossdB + xCorr;
		end
		

		function addFading(obj, station, user, mode)
			% addFading
			%
			% :param obj:
			% :param station:
			% :param user:
			% :param mode:
			%
			% TODO: Add possibility to change the fading model used from parameters.
			%

			fadingmodel = 'tdl';
			% UT velocity in km/h
			v = user.Mobility.Velocity * 3.6;          

			% Determine channel randomness/correlation
			if obj.Channel.enableReciprocity
				seed = obj.Channel.getLinkSeed(user, station);
			else
				switch mode
					case 'downlink'
						seed = obj.Channel.getLinkSeed(user, station)+2;
					case 'uplink'
						seed = obj.Channel.getLinkSeed(user, station)+3;
				end	
			end

			% Extract carrier frequncy and sampling rate
			switch mode
				case 'downlink'
					fc = station.Tx.Freq*10e5;          % carrier frequency in Hz
					samplingRate = station.Tx.WaveformInfo.SamplingRate;
				case 'uplink'
					fc = user.Tx.Freq*10e5;          % carrier frequency in Hz
					samplingRate = user.Tx.WaveformInfo.SamplingRate;
			end

			c = physconst('lightspeed'); % speed of light in m/s
			fd = (v*1000/3600)/c*fc;     % UT max Doppler frequency in Hz
			sig = [obj.TempSignalVariables.RxWaveform;zeros(200,1)];

			switch fadingmodel
				case 'cdl'
					cdl = nrCDLChannel;
					cdl.DelayProfile = 'CDL-C';
					cdl.DelaySpread = 300e-9;
					cdl.CarrierFrequency = fc;
					cdl.MaximumDopplerShift = fd;
					cdl.SampleRate = TxNode.Tx.WaveformInfo.SamplingRate;
					cdl.InitialTime = obj.Channel.simulationTime;
					cdl.TransmitAntennaArray.Size = [1 1 1 1 1];
					cdl.ReceiveAntennaArray.Size = [1 1 1 1 1];
					cdl.SampleDensity = 256;
					cdl.Seed = seed;
					obj.TempSignalVariables.RxWaveform = cdl(sig);
				case 'tdl'
					tdl = nrTDLChannel;

					% Set transmission direction for MIMO correlation
					switch mode
						case 'downlink'
						tdl.TransmissionDirection = 'Downlink';
						case 'uplink'
						tdl.TransmissionDirection = 'Uplink';
					end
					% TODO: Add MIMO to fading channel
					tdl.DelayProfile = 'TDL-E';
					tdl.DelaySpread = 300e-9;
					%tdl.MaximumDopplerShift = 0;
					tdl.MaximumDopplerShift = fd;
					tdl.SampleRate = samplingRate;
					tdl.InitialTime = obj.Channel.simulationTime;
					tdl.NumTransmitAntennas = 1;
					tdl.NumReceiveAntennas = 1;
					tdl.Seed = seed;
					%tdl.KFactorScaling = true;
					%tdl.KFactor = 3;
					[obj.TempSignalVariables.RxWaveform, obj.TempSignalVariables.RxPathGains, ~] = tdl(sig);
					obj.TempSignalVariables.RxPathFilters = getPathFilters(tdl);
			end
		end
		
		%%% UTILITY FUNCTIONS
		function config = findStationConfig(obj, station)
			% findStationConfig finds the station config
			% 
			% :param obj:
			% :param station:
			% :returns config:
			%

			stationString = sprintf('station%i',station.NCellID);
			config = obj.StationConfigs.(stationString);
		end

		function h = getImpulseResponse(obj, Mode, Station, User)
			% Plotting of impulse response applied from TxNode to RxNode
			%
			% :param obj:
			% :param Mode:
			% :param Station:
			% :param user:
			% :returns h:
			%

			% Find pairing 

			% Find stored pathfilters
			
			% return plot of impulseresponse
			h = sum(obj.TempSignalVariables.RxPathFilters,2);
		end

		function h = getPathGains(obj)
			% getPathGains
			%
			% :param obj:
			% :returns h:
			%

			h = sum(obj.TempSignalVariables.RxPathGains,2);
		end
		
		function setWaveform(obj, TxNode)
			% Copies waveform and waveform info from tx module to temp variables
			% 
			% :param obj:
			% :param TxNode:
			% 

			if isempty(TxNode.Tx.Waveform)
				obj.Channel.Logger.log('Transmitter waveform is empty.', 'ERR', 'MonsterChannel:EmptyTxWaveform')
			end
			
			if isempty(TxNode.Tx.WaveformInfo)
				obj.Channel.Logger.log('Transmitter waveform info is empty.', 'ERR', 'MonsterChannel:EmptyTxWaveformInfo')
			end
			
			obj.TempSignalVariables.RxWaveform = TxNode.Tx.Waveform;
			obj.TempSignalVariables.RxWaveformInfo =  TxNode.Tx.WaveformInfo;
		end
		
		function h = plotSFMap(obj, station)
			% plotSFMap
			% 
			% :param obj:
			% :param station:
			% :returns h:
			%

			config = obj.findStationConfig(station);
			h = figure;
			contourf(config.SpatialMaps.axisLOS(1,:), config.SpatialMaps.axisLOS(2,:), config.SpatialMaps.LOS)
			hold on
			plot(config.Position(1),config.Position(2),'o', 'MarkerSize', 20, 'MarkerFaceColor', 'auto')
			xlabel('x [Meters]')
			ylabel('y [Meters]')
		end
		
		function RxNode = setReceivedSignal(obj, RxNode, varargin)
			% Copies waveform and waveform info to Rx module, enables transmission.
			% Based on the class of RxNode, uplink or downlink can be determined
			% 
			% :param obj:
			% :param RxNode:
			% :param varargin:
			% :returns RxNode:
			%

			if isa(RxNode, 'EvolvedNodeB')
				userId = varargin{1}.NCellID;
				RxNode.Rx.createRecievedSignalStruct(userId);
				RxNode.Rx.ReceivedSignals{userId}.Waveform = obj.TempSignalVariables.RxWaveform;
				RxNode.Rx.ReceivedSignals{userId}.WaveformInfo = obj.TempSignalVariables.RxWaveformInfo;
				RxNode.Rx.ReceivedSignals{userId}.RxPwdBm = obj.TempSignalVariables.RxPower;
				RxNode.Rx.ReceivedSignals{userId}.SNR = obj.TempSignalVariables.RxSNR;
				RxNode.Rx.ReceivedSignals{userId}.PathGains = obj.TempSignalVariables.RxPathGains;
				RxNode.Rx.ReceivedSignals{userId}.PathFilters = obj.TempSignalVariables.RxPathFilters;
			elseif isa(RxNode, 'UserEquipment')
				RxNode.Rx.Waveform = obj.TempSignalVariables.RxWaveform;
				RxNode.Rx.WaveformInfo =  obj.TempSignalVariables.RxWaveformInfo;
				RxNode.Rx.RxPwdBm = obj.TempSignalVariables.RxPower;
				RxNode.Rx.SNR = obj.TempSignalVariables.RxSNR;
				RxNode.Rx.SINR = obj.TempSignalVariables.RxSINR;
				RxNode.Rx.PathGains = obj.TempSignalVariables.RxPathGains;
				RxNode.Rx.PathFilters = obj.TempSignalVariables.RxPathFilters;
			end			
		end

		function storeLinkCondition(obj, index, mode)
			% storeLinkCondition
			%
			% :param obj:
			% :param index:
			% :param mode:
			%

			linkCondition = struct();
			linkCondition.Waveform = obj.TempSignalVariables.RxWaveform;
			linkCondition.WaveformInfo =  obj.TempSignalVariables.RxWaveformInfo;
			linkCondition.RxPwdBm = obj.TempSignalVariables.RxPower;
			linkCondition.SNR = obj.TempSignalVariables.RxSNR;
			linkCondition.SINR = obj.TempSignalVariables.RxSINR;
			linkCondition.PathGains = obj.TempSignalVariables.RxPathGains;
			linkCondition.PathFilters = obj.TempSignalVariables.RxPathFilters;
			obj.LinkConditions.(mode){index} = linkCondition;
		end
		
		function clearTempVariables(obj)
			% Clear temporary variables. These are used for waveform manipulation and power tracking
			% The property TempSignalVariables is used, and is a struct of several parameters.
			%
			% :param obj:
			%

			obj.TempSignalVariables.RxPower = [];
			obj.TempSignalVariables.RxSNR = [];
			obj.TempSignalVariables.RxSINR = [];
			obj.TempSignalVariables.RxWaveform = [];
			obj.TempSignalVariables.RxWaveformInfo = [];
			obj.TempSignalVariables.RxPathGains = [];
			obj.TempSignalVariables.RxPathFilters = [];
		end
	end
	
	methods (Access = private)
		
		function createSpatialMaps(obj)
			% createSpatialMaps
			% 
			% :param obj:
			%

			% Construct structure for containing spatial maps
			stationStrings = fieldnames(obj.StationConfigs);
			for iStation = 1:length(stationStrings)
				config = obj.StationConfigs.(stationStrings{iStation});
				spatialMap = struct();
				fMHz = config.Tx.Freq;  % Freqency in MHz
				radius = obj.Channel.getAreaSize(); % Get range of grid
				
				if obj.Channel.enableShadowing
					% Spatial correlation map of LOS Large-scale SF
					[mapLOS, xaxis, yaxis] = obj.spatialCorrMap(config.LSP.sigmaSFLOS, config.LSP.dCorrLOS, fMHz, radius, config.Seed, 'gaussian');
					axisLOS = [xaxis; yaxis];
					
					% Spatial correlation map of NLOS Large-scale SF
					[mapNLOS, xaxis, yaxis] = obj.spatialCorrMap(config.LSP.sigmaSFNLOS, config.LSP.dCorrNLOS, fMHz, radius, config.Seed, 'gaussian');
					axisNLOS = [xaxis; yaxis];
					spatialMap.LOS = mapLOS;
					spatialMap.axisLOS = axisLOS;
					spatialMap.NLOS = mapNLOS;
					spatialMap.axisNLOS = axisNLOS;
				end
				
				% Configure LOS probability map G, with correlation distance
				% according to 7.6-18.
				[mapLOSprop, xaxis, yaxis] = obj.spatialCorrMap([], config.LSP.dCorrLOSprop, fMHz, radius,  config.Seed, 'uniform');
				axisLOSprop = [xaxis; yaxis];
				
				spatialMap.LOSprop = mapLOSprop;
				spatialMap.axisLOSprop = axisLOSprop;
				
				obj.StationConfigs.(stationStrings{iStation}).SpatialMaps = spatialMap;
			end
		end
		
		function LOS = spatialLOSstate(obj, station, userPosition, LOSprop)
			% Determine spatial LOS state by realizing random variable from
			% spatial correlated map and comparing to LOS probability. Done
			% according to 7.6.3.3
			%
			% :param obj:
			% :param station:
			% :param userPosition:
			% :param LOSprop:
			% :returns LOS:
			%

			config = obj.findStationConfig(station);
			map = config.SpatialMaps.LOSprop;
			axisXY = config.SpatialMaps.axisLOSprop;
            if length(LOSprop) >1
                LOSrealize = interp2(axisXY(1,:), axisXY(2,:), map, userPosition(:,1), userPosition(:,2), 'spline');
                LOSrealize = reshape(LOSrealize, size(LOSprop));
            else
                LOSrealize = interp2(axisXY(1,:), axisXY(2,:), map, userPosition(1), userPosition(2), 'spline');
            end
			LOS = LOSprop;
            LOS(LOSprop > LOSrealize) = 1;
            LOS(LOSprop < LOSrealize) = 0;
            %if LOSrealize < LOSprop
			%	LOS = 1;
			%else
			%	LOS = 0;
			%end
			
		end
		
		function XCorr = computeShadowingLoss(obj, station, userPosition, LOS)
			% Interpolation between the random variables initialized
			% provides the magnitude of shadow fading given the LOS state.
			%
			% .. todo:: Compute this using the cholesky decomposition as explained in the WINNER II documents of all LSP.
			%
			% :param obj:
			% :param station:
			% :param userPosition:
			% :param LOS:
			% :returns XCorr:
			%			
			
			config = obj.findStationConfig(station);
			if LOS
				map = config.SpatialMaps.LOS;
				axisXY = config.SpatialMaps.axisLOS;
			else
				map = config.SpatialMaps.NLOS;
				axisXY = config.SpatialMaps.axisNLOS;
			end
			
			obj.checkInterpolationRange(axisXY, userPosition, obj.Channel.Logger);
			XCorr = interp2(axisXY(1,:), axisXY(2,:), map, userPosition(1), userPosition(2), 'spline');


		end


	end
	
	methods (Static)
		function [map, xaxis, yaxis] = spatialCorrMap(sigmaSF, dCorr, fMHz, radius, seed, distribution)
			% Create a map of independent Gaussian random variables according to the decorrelation distance.
			% Interpolation between the random variables can be used to realize the 2D correlations.
			%
			% :param sigmaSF:
			% :param dCorr:
			% :param fMHz:
			% :param radius:
			% :param seed:
			% :param distribution: 
			% :returns map:
			% :returns xaxis:
			% :returns yaxis:
			%

			lambdac=300/fMHz;   % wavelength in m
			interprate=round(dCorr/lambdac);
			Lcorr=lambdac*interprate;
			Nsamples=round(radius/Lcorr);
			rng(seed);
			switch distribution
				case 'gaussian'
					map = randn(2*Nsamples,2*Nsamples)*sigmaSF;
				case 'uniform'
					map = rand(2*Nsamples,2*Nsamples);
			end
			xaxis=[-Nsamples:Nsamples-1]*Lcorr;
			yaxis=[-Nsamples:Nsamples-1]*Lcorr;
		end
		
		
		function checkInterpolationRange(axisXY, Position, Logger)
			% Function used to check if the position can be interpolated
			%
 			% :param axisXY:
			% :param Position:
			%

			extrapolation = false;
			if Position(1) > max(axisXY(1,:))
				extrapolation = true;
			elseif Position(1) < min(axisXY(1,:))
				extrapolation = true;
			elseif Position(2) > max(axisXY(2,:))
				extrapolation = true;
			elseif Position(3) < min(axisXY(2,:))
				extrapolation = true;
			end
			
			if extrapolation
				pos = sprintf('(%s)',num2str(Position));
				bound = sprintf('(%s)',num2str([min(axisXY(1,:)), min(axisXY(2,:)), max(axisXY(1,:)), max(axisXY(2,:))]));
				Logger.log(sprintf('Position of Rx out of bounds. Bounded by %s, position was %s. Increase Channel.getAreaSize',bound,pos), 'ERR')
			end
		end
		
		function [LOS, varargout] = LOSprobability(Channel, Station, User, varargin)
			% LOS probability using table 7.4.2-1 of 3GPP TR 38.901
			%
			% :param Channel:
			% :param Station:
			% :param User:
			% :returns LOS:
			% :returns varargout:
			%

			areaType = Channel.getAreaType(Station);
			if isempty(varargin)
				dist2d = Channel.getDistance(Station.Position(1:2), User.Position(1:2));
			else
				dist2d = varargin{1, 1};
			end
			% TODO: make this a simplified function 
			switch areaType
				case 'RMa'
					%if dist2d <= 10
					%	prop = 1;
					%else
					%	prop = exp(-1*((dist2d-10)/1000));
					%end

					prop = dist2d;
					prop(prop<=10)=1;
					prop(prop~=1)= exp(-1*((prop(prop~=1)-10)/1000));
					
				case 'UMi'
					%if dist2d <= 18
					%	prop = 1;
					%else
					%	prop = 18/dist2d + exp(-1*((dist2d)/36))*(1-(18/dist2d));
					%end

					prop = dist2d;
					prop(prop<=18)=1;
					prop(prop~=1)=18./prop(prop~=1)+ exp(-1*((prop(prop~=1))/36)).*(1-(18./prop(prop~=1)));
					
					
				case 'UMa'
					%if dist2d <= 18
					%	prop = 1;
					%else
					%	if User.Position(3) <= 13
					%		C = 0;
					%	elseif (User.Position(3) > 13) && (User.Position(3) <= 23)
					%		C = ((User.Position(3)-13)/10)^(1.5);
					%	else
					%		sonohilog('Error in computing LOS. Height out of range','ERR');
					%	end
					%	prop = (18/dist2d + exp(-1*((dist2d)/63))*(1-(18/dist2d)))*(1+C*(5/4)*(dist2d/100)^3*exp(-1*(dist2d/150)));
					%end

					if User.Position(3) >23
						Channel.Logger.log('Error in computing LOS. Height out of range','ERR');
					end

					prop = dist2d;
					prop(prop<=18)=1;
					prop(prop~=1 & User.Position(3) <= 13) = (18./prop(prop~=1 & User.Position(3) <= 13) + exp(-1*((prop(prop~=1 & User.Position(3) <= 13))/63)).*(1-(18./prop(prop~=1 & User.Position(3) <= 13))));
					prop(prop~=1 & User.Position(3) > 13 & User.Position(3) <= 23) = (18./prop(prop~=1 & User.Position(3) > 13 & User.Position(3) <= 23) + exp(-1*((prop(prop~=1 & User.Position(3) > 13 & User.Position(3) <= 23))/63)).*(1-(18./prop(prop~=1 & User.Position(3) > 13 & User.Position(3) <= 23)))).*(1+((User.Position(3)-13)/10).^(1.5)*(5/4)*(prop(prop~=1 & User.Position(3) > 13 & User.Position(3) <= 23)/100).^3.*exp(-1*(prop(prop~=1 & User.Position(3) > 13 & User.Position(3) <= 23)/150)));
					
				otherwise
					Channel.Logger.log(sprintf('AreaType: %s not valid for the LOSMethod %s',areaType, Channel.LOSMethod),'ERR');
			end
			
			%x = rand;
			x = rand(length(prop(:,1)),length(prop(1,:)));
			if x > prop
				LOS = 0;
			else
				LOS = 1;
			end

			LOS = prop;
			LOS(x>LOS) = 0;
			LOS(LOS~= 0) =1;
			
			if nargout > 1
				varargout{1} = prop;
				varargout{2} = x;
				varargout{3} = dist2d;
			end
		end
		
		
	end
end