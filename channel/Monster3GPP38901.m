classdef Monster3GPP38901 < matlab.mixin.Copyable
	% Monster3GPP38901 defines a class for the 3GPP channel model specified in 38.901
	%
	% :CellConfigs:
	% :Channel:
	% :TempSignalVariables:
	% :Pairings:
	% :LinkConditions:
	%
	
	properties
		CellConfigs;
		Channel;
		Pairings = [];
		LinkConditions = struct();
		SignalPadding = 200;
	end
	
	methods
		function obj = Monster3GPP38901(MonsterChannel, Cells)
			obj.Channel = MonsterChannel;
			obj.setupCellConfigs(Cells);
			obj.createSpatialMaps();
			obj.LinkConditions.downlink = [];
			obj.LinkConditions.uplink = [];
		end
		
		function setupCellConfigs(obj, Cells)
			% Setup structure for Cell configs
			%
			% :obj:
			% :Cells
			%
			
			for iCell = 1:length(Cells)
				Cell = Cells(iCell);
				cellString = sprintf('Cell%i',Cell.NCellID);
				obj.CellConfigs.(cellString) = struct();
				obj.CellConfigs.(cellString).Tx = Cell.Tx;
				obj.CellConfigs.(cellString).Position = Cell.Position;
				obj.CellConfigs.(cellString).Seed = Cell.Seed;
				obj.CellConfigs.(cellString).LSP = lsp3gpp38901(obj.Channel.getAreaType(Cell));
			end
		end

		% rename to propagate link and traverse for all waveforms in a link
		function tempVar = propagateWaveform(obj, Cell, User, Cells, Users, Mode)
			tempVar = obj.TempVariables();
			% Set waveform to be manipulated
			switch Mode
				case 'downlink'
					tempVar = obj.setWaveform(Cell, tempVar);
				case 'uplink'
					tempVar = obj.setWaveform(User, tempVar);
			end
			
			% Calculate recieved power between Cell and User
			[receivedPower, receivedPowerWatt] = obj.computeLinkBudget(Cell, User, Mode);
			tempVar.RxPower = receivedPower;
			tempVar.RxPowerWatt = receivedPowerWatt;
			
			% Calculate SNR using thermal noise
			[SNR, SNRdB, noisePower] = obj.Channel.calculateSNR(tempVar.Waveform, tempVar.WaveformInfo.SamplingRate, tempVar.RxPower);
			tempVar.RxSNR = SNR;
			tempVar.RxSNRdB = SNRdB;
			tempVar.noisePower = noisePower;
			
			% If Interference is assumed to be worst case, e.g. 'Power' or 'None', the SINR
			% define how much noise is to be added
			if ~strcmp(obj.Channel.InterferenceType, 'Frequency')
				[tempVar] = obj.computeSINR(Cell, User, Cells, Users, Mode, tempVar);
				SNR = tempVar.RxSINR;
			end
			
			noisySignal = obj.Channel.AddAWGN(Cell, Mode, SNR, tempVar.WaveformInfo.Nfft, tempVar.Waveform);
			tempVar.RxWaveform = noisySignal;
			
			% Add fading
			if obj.Channel.enableFading
				tempVar = obj.addFading(Cell, User, Mode, tempVar);
			end
		end
		
		function propagateWaveforms(obj, Cells, Users, Mode)
			% Loop through all links given the mode of transmission.
			% Interference is added depending on the interference type. 
			% If 'Power' is selected, the interference is added as AWGN which is done in the first forward pass of `propagateWaveform`. 
			% The noise is added before the fading channel
			% 
			% If 'Frequency' is selected, the interference is added as a sum of interfering waveforms, that have propagated the channel (call to propagateWaveform)
			%
			% All manipulations of wavefroms are stored in `tempVar` and overwritten for each link. 
			% The manipulated waveform and power calculations are stored at the respective receiver objects
			% :obj:
			%	:Cells:
			% :Users:
			% :Mode:
			%
			
			Pairing = obj.Channel.getPairing(Cells);
			obj.Pairings = Pairing;
			numLinks = length(Pairing(1,:));
			
			% Store link conditions
			obj.LinkConditions.(Mode) = cell(numLinks,1);
			
			for i = 1:numLinks
				
				% Local copy for mutation
				Cell = Cells([Cells.NCellID] == Pairing(1,i));
				User = Users(find([Users.NCellID] == Pairing(2,i))); %#ok

				% Propagate waveform and write received waveform to struct
				tempVar = obj.propagateWaveform(Cell, User, Cells, Users, Mode);
		
				% Sum waveforms from interfering stations and compute SINR, if
				% frequency type interference is wanted.
				if strcmp(obj.Channel.InterferenceType,'Frequency')
					tempVar = obj.computeSINR(Cell, User, Cells, Users, Mode, tempVar);
				end
				
				% Receive signal at Rx module
				switch Mode
					case 'downlink'
						obj.setReceivedSignal(User,  tempVar);
					case 'uplink'
						obj.setReceivedSignal(Cell, tempVar, User);
				end
			

				
				% Store in channel variable
				obj.storeLinkCondition(i, Mode, tempVar)
				
			end
		end
	
		
		function receivedPower = getreceivedPowerMatrix(obj, Cell, User, sampleGrid)
			% Used for obtaining a Matrix of received power given a grid of
			% positions.
			%
			% :param obj:
			% :param Cell:
			% :param User:
			% :param sampleGrid:
			% :returns receivedPower:
			%
			
			[receivedPower, ~] = obj.computeLinkBudget(Cell, User, 'downlink', sampleGrid);
			receivedPower = reshape(receivedPower, length(sampleGrid), []);
		end
		

		function [interferesList, powerList] = getInterferes(obj, Cell, User, Cells, Users, Mode)
			% Get a list of interferes given the mode of transmission.
			% The interferers are for Cells based on the class of operations.
			% Thus all Macros' interfere with each other.
			% All users associated to the same class of stations also interfere
			% with each other.
			switch Mode
				case 'downlink'
					interferesList = obj.Channel.getInterferingCells(Cell, Cells);
					powerList = obj.listCellPower(User, interferesList);
				case 'uplink'
					interferesList = obj.Channel.getInterferingUsers(User, Cell, Users, Cells);
					powerList = obj.listUserPower(Cell, interferesList);
			end
		end
		
		function tempVar = powerInterference(obj, powerList, Mode, tempVar)
			% Power profile type interference.
			% SINR is computed based on the power profile and nothing else.

			switch Mode
				case 'downlink'
					% Sum power from interfering cells
					intPower = MonsterChannel.sumReceivedPower(powerList);
				case 'uplink'
					% Sum power from interfering users
					intPower = MonsterChannel.sumReceivedPower(powerList);
			end

			[tempVar.RxSINR, tempVar.RxSINRdB] = obj.Channel.calculateSINR(tempVar.RxPowerWatt, intPower, tempVar.noisePower);

			
		end
		
		function [tempVar] = frequencyInterference(obj, Cell, User, Cells, Users, Mode, interferesList, tempVar)
					% Compute interference based on the waveform of the signals. 
					% The interfering waveforms are computed and added (with correct
					% scaling in power and frequency) to the received signal of the
					% link propagated. The SINRdB computed is based on the power
					% profile and thus the worst case SINR expected if the frequency
					% components are all used. The estimated SINR is computed at the
					% receiver.
					%
					% for each interfering waveform, compute channel impairments and get waveform
					% Sum the waveforms to get combined interfering waveform
					% Sum power to get estimated power
					% TODO: Refactorize the uplink and downlink sum of waveforms
					interferingPower = 0;
					switch Mode
						case 'downlink'
							interferingWaveform = zeros(length(tempVar.RxWaveform),1);
							for intCell = 1:length(interferesList)
								tempIntVar = obj.propagateWaveform(interferesList(intCell), User, Cells, Users, Mode);
								tempIntVar.RxWaveform = setPower(tempIntVar.RxWaveform, tempIntVar.RxPower);
								interferingWaveform = interferingWaveform + circshift(tempIntVar.RxWaveform, randi(length(interferingWaveform)/2-1));
								interferingPower  = interferingPower + tempIntVar.RxPowerWatt;
							end
						case 'uplink'
							% Compute the longest waveform transmitted

							intWaveformSize = [interferesList.Tx];
							intWaveformSize = cellfun(@length,{intWaveformSize.Waveform}, 'UniformOutput', false);
							intWaveformSize = max([intWaveformSize{:}])+obj.SignalPadding;

							interferingWaveform = zeros(intWaveformSize,1);
							for intUser = 1:length(interferesList)
								tempIntVar = obj.propagateWaveform(Cell, interferesList(intUser), Cells, Users, Mode);
								tempIntVar.RxWaveform = setPower(tempIntVar.RxWaveform, tempIntVar.RxPower);
								interferingWaveform = interferingWaveform + circshift([tempIntVar.RxWaveform; complex(zeros(intWaveformSize-length(tempIntVar.RxWaveform),1))], randi(length(tempIntVar.RxWaveform)/2-1));
								interferingPower  = interferingPower + tempIntVar.RxPowerWatt;
							end
					end

					debug = false; % Debugging plots

					% option 1.
					% Add relative power to received waveform
					% Set power of RxWaveform based on link budget
					Waveform = setPower(tempVar.RxWaveform, tempVar.RxPower);

					if debug
						figure
						hold on
					end

					% Add interfering waveform
					% If longer, truncate the rest
					if length(interferingWaveform) > length(Waveform)
						rxWaveform = Waveform + interferingWaveform(1:length(Waveform),1);
					elseif length(interferingWaveform) < length(Waveform)
						rxWaveform = Waveform + [interferingWaveform; complex(zeros(length(Waveform)-length(interferingWaveform),1))];
					else
						rxWaveform = Waveform + interferingWaveform;
					end


					if debug

						Fint = fft(interferingWaveform)./length(interferingWaveform);
						Fpsd = 10*log10(fftshift(abs(Fint).^2))+30;
						plot(Fpsd)

						Fint = fft(rxWaveform)./length(rxWaveform);
						Fpsd = 10*log10(fftshift(abs(Fint).^2))+30;
						plot(Fpsd)

						Fint = fft(Waveform)./length(Waveform);
						Fpsd = 10*log10(fftshift(abs(Fint).^2))+30;
						plot(Fpsd)

						legend('Interfering waveform', 'With interference', 'No inteference')
					end
					% Normalize waveform 
					tempVar.RxWaveform = setPower(rxWaveform, 10*log10(bandpower(tempVar.RxWaveform))+30);

					% Compute worstcase SINR based on power profile. This assumes
					% constant power on all subcarriers and is thus the worst expected
					% SINR.
					[tempVar.RxSINR, tempVar.RxSINRdB] = obj.Channel.calculateSINR(tempVar.RxPowerWatt, interferingPower, tempVar.noisePower);

		end
		
		function [tempVar] = computeSINR(obj, Cell, User, Cells, Users, Mode, tempVar)
			% Compute SINR using received power and the noise power.
			% Interference is given as the power of the received signal, given the power of the associated Cell, over the power of the neighboring cells.
			%
			% :param obj:
			% :param Cell:
			% :param User:
			% :param Cells:
			% :param Users:
			% :param receivedPowerWatt:
			% :param noisePower:
			% :param Mode:
			% :returns SINR:
			%
			% v1. InterferenceType Power assumes full power, thus the SINR computation can be done using just the link budget.
			%	v2. Adds power from interfering waveforms.
			% TODO: Add uplink interference

			[interferesList, powerList] = obj.getInterferes(Cell, User, Cells, Users, Mode);
			if ~isempty(interferesList)
				switch obj.Channel.InterferenceType
					case 'Power'
						tempVar = obj.powerInterference(powerList, Mode, tempVar);
					case 'Frequency'
						tempVar = obj.frequencyInterference(Cell, User, Cells, Users, Mode, interferesList, tempVar);
					otherwise
						tempVar.RxSINR = tempVar.RxSNR;
				end
			else
				% No interferes, SNR equal SINR
				tempVar.RxSINR = tempVar.RxSNR;
			end
		end
		
		function SINR = listSINR(obj, User, Cells, Mode)
			% Get list of SINR for all cells, assuming they all interfere.
			%
			% :param User: One User
			% :param Cells: Multiple eNB's
			% :param Mode: Mode of transmission.
			% :returns SINR: List of SINR for each Cell
			
			obj.Channel.Logger.log('func listSINR: Interference is considered intra-class eNB cells','WRN')
			
			
			% Get received power for each Cell
			for iCell = 1:length(Cells)
				Cell = Cells(iCell);
				[~, receivedPower(iCell)] = obj.computeLinkBudget(Cell, User, Mode);
			end
			
			% Compute SINR from each Cell
			for iCell = 1:length(Cells)
				Cell = Cells(iCell);
				cellPower = receivedPower(iCell);
				interferingPower = sum(receivedPower(1:end ~= iCell));
				[~, thermalNoise] = thermalLoss();
				SINR(iCell) = 10*log10(obj.Channel.calculateSINR(cellPower, interferingPower, thermalNoise));
			end
			
		end
		
		function list = listCellPower(obj, User, Cells)
			% Get list of recieved power from all cells
			%
			% :param obj:
			% :param User:
			% :param Cells:
			% :param Mode:
			% :returns list:
			%
			
			list = struct();
			for iCell = 1:length(Cells)
				Cell = Cells(iCell);
				cellStr = sprintf('NCellID%i',Cell.NCellID);
				list.(cellStr).receivedPowerdBm = obj.computeLinkBudget(Cell, User, 'downlink');
				list.(cellStr).receivedPowerWatt = 10^((list.(cellStr).receivedPowerdBm-30)/10);
				list.(cellStr).NCellID = Cell.NCellID;
			end
			
		end


		function list = listUserPower(obj, Cell, Users)

			list = struct();
			for iUser = 1:length(Users)
				User = Users(iUser);
				userStr = sprintf('NCellIDID%i', User.NCellID);
				list.(userStr).receivedPowerdBm = obj.computeLinkBudget(Cell, User, 'uplink');
				list.(userStr).receivedPowerWatt = 10^((list.(userStr).receivedPowerdBm-30)/10);
				list.(userStr).NCellID = User.NCellID;
			end

		end

		function [txConfig, userConfig] = getLinkParameters(obj, Cell, User, mode, varargin)
			% Function acts like a wrapper between lower layer physical computations (usually matrix operations) and the Monster API of Cell and User objects
			% construct a structure for handling variables
			%
			% :param Cell: Cell object
			% :param User: User object
			% :param mode: 'downlink' or 'uplink' % Currently only difference is frequency
			% :param varargin: (optional) 2xN array of positions for which the link budget is wanted.
			userConfig = struct();
			txConfig = struct();
			
			txConfig.position = Cell.Position;

			if ~isempty(varargin{1})
				[X, Y] = meshgrid(varargin{1}{1}(1,:), varargin{1}{1}(2,:));
				Z = User.Position(3)*ones(length(X),length(Y));
			else
				X = User.Position(1);
				Y = User.Position(2);
				Z = User.Position(3);
			end
			userConfig.positions = [reshape(X,[],1)  reshape(Y,[],1) reshape(Z,[],1)];
			
			userConfig.Indoor = User.Mobility.Indoor;
						
			userConfig.d2d = arrayfun(@(x, y) obj.Channel.getDistance(Cell.Position(1:2),[x y]), userConfig.positions(:,1), userConfig.positions(:,2));
			userConfig.d3d = arrayfun(@(x, y, z) obj.Channel.getDistance(Cell.Position(1:3),[x y z]), userConfig.positions(:,1), userConfig.positions(:,2), userConfig.positions(:,3));
			switch mode
				case 'downlink'
					txConfig.hBs = Cell.Position(3);
					txConfig.areaType = obj.Channel.getAreaType(Cell);
					txConfig.seed = obj.Channel.getLinkSeed(User, Cell);
					txConfig.freq = Cell.Tx.Freq;
					userConfig.hUt = User.Position(3);
					
					
				case 'uplink'
					txConfig.hBs = Cell.Position(3);
					txConfig.areaType = obj.Channel.getAreaType(Cell);
					txConfig.seed = obj.Channel.getLinkSeed(User, Cell);
					txConfig.freq = User.Tx.Freq;
					userConfig.hUt = User.Position(3);
			end

		end
	

		function [userConfig] = computeLOS(obj, Cell, txConfig, userConfig)
			% Compute LOS situation
			% If a probability based LOS method is used, the LOSprop is realized with spatial consistency

			if userConfig.Indoor
				userConfig.LOS = 0;
				userConfig.LOSprop = NaN;
			else
				[userConfig.LOS, userConfig.LOSprop] = obj.Channel.isLinkLOS(txConfig, userConfig, false);
				if ~isnan(userConfig.LOSprop) % If a probablistic LOS model is used, the LOS state needs to be realized with spatial consistency
					userConfig.LOS = obj.spatialLOSstate(Cell, userConfig.positions(:,1:2), userConfig.LOSprop);
				end
			end
		end

		function [receivedPower, receivedPowerWatt] = computeLinkBudget(obj, Cell, User, mode, varargin)
			% Compute link budget for Tx -> Rx
			%
			% :param obj:
			% :param Cell:
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
			

			[txConfig, userConfig] = obj.getLinkParameters(Cell, User, mode, varargin);
			
			userConfig = obj.computeLOS(Cell, txConfig, userConfig);
		
			if obj.Channel.enableShadowing
				xCorr = arrayfun(@(x,y,z) obj.computeShadowingLoss(Cell, [x y], z), reshape(userConfig.positions(:,1),size(userConfig.LOS)), reshape(userConfig.positions(:,2),size(userConfig.LOS)), userConfig.LOS );
			else
				xCorr = 0;
			end

			if userConfig.Indoor
				indoorLoss = obj.computeIndoorLoss(txConfig, userConfig);
			else
				indoorLoss = 0;
			end

			
			EIRPdBm = arrayfun(@(x,y, z) Cell.Tx.getEIRPdBm(Cell.Position, [x y z]), userConfig.positions(:,1), userConfig.positions(:,2), userConfig.positions(:,3));
			lossdB = obj.computePathLoss(txConfig, userConfig);
			
			% Add possible shadowing loss and indoor loss
			lossdB = lossdB + xCorr + indoorLoss;
			
			switch mode
				case 'downlink'
					DownlinkUeLoss = arrayfun(@(x,y) User.Rx.getLoss(Cell.Position, [x y]), userConfig.positions(:,1), userConfig.positions(:,2));
					receivedPower = EIRPdBm-lossdB+DownlinkUeLoss; %dBm
				case 'uplink'
					EIRPdBm = User.Tx.getEIRPdBm;
					receivedPower = EIRPdBm-lossdB-Cell.Rx.NoiseFigure; %dBm 
			end
			
			receivedPowerWatt = 10.^((receivedPower-30)./10);
		end
		
		
		function [indoorLoss] = computeIndoorLoss(txConfig, userConfig)
			
			% Low loss model consists of LOS
			materials = {'StandardGlass', 'Concrete'; 0.3, 0.7};
			sigma_P = 4.4;
			
			% High loss model consists of
			%materials = {'IIRGlass', 'Concrete'; 0.7, 0.3}
			%sigma_P = 6.5;
			
			PL_tw = buildingloss3gpp38901(materials, txConfig.freq/10e2);
			
			% If indoor depth can be computed
			%PL_in = indoorloss3gpp38901('', 2d_in);
			% Otherwise sample from uniform
			PL_in  = indoorloss3gpp38901(userConfig.areaType);
			indoorLoss = PL_tw + PL_in + randn(1, 1)*sigma_P;
			
			
		end
		
		function [lossdB] = computePathLoss(obj, txConfig, userConfig)
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
			freq = txConfig.freq/10e2; % Convert to GHz
			areaType = txConfig.areaType;
			
			% Extract receiver configuration, can be arrays.
			hUt = userConfig.hUt;
			distance2d = userConfig.d2d;
			distance3d = userConfig.d3d;
			LOS = userConfig.LOS;
			
			% Check whether we have buildings in the scenario
			if ~isempty(obj.Channel.BuildingFootprints)
				avgBuilding = mean(obj.Channel.BuildingFootprints(:,5));
				avgStreetWidth = obj.Channel.BuildingFootprints(2,2)-obj.Channel.BuildingFootprints(1,4);
			else
				avgBuilding = 0;
				avgStreetWidth = 0;
			end
			
			try
				lossdB = loss3gpp38901(areaType, distance2d, distance3d, freq, hBs, hUt, avgBuilding, avgStreetWidth, LOS);
			catch ME
				if strcmp(ME.identifier,'Pathloss3GPP:Range')
						minRange = 10;
		 				lossdB = loss3gpp38901(areaType, minRange, distance3d, freq, hBs, hUt, avgBuilding, avgStreetWidth, LOS);
				else
					obj.Channel.Logger.log('Pathloss computation error', 'ERR')
				end
			end
			
		end
		
		
		function tempVar = addFading(obj, Cell, User, mode, tempVar)
			% Applies fading to the channel model based on the type configured
			%
			% :param obj: Monster3GPP38901 instance
			% :param Cell: Cell instance
			% :param User: UserEquipment instance
			% :param mode: string direction mode downlink | uplink
			% :param tempVar: struct temporary variables used to store impairments 
			% :return tempVar: struct updated impairments
			%
			
			% UT velocity in km/h
			v = User.Mobility.Velocity * 3.6;
			
			% Determine channel randomness/correlation
			if obj.Channel.enableReciprocity
				seed = obj.Channel.getLinkSeed(User, Cell);
			else
				switch mode
					case 'downlink'
						seed = obj.Channel.getLinkSeed(User, Cell)+2;
					case 'uplink'
						seed = obj.Channel.getLinkSeed(User, Cell)+3;
				end
			end
			
			% Extract carrier frequncy and sampling rate
			switch mode
				case 'downlink'
					fc = Cell.Tx.Freq*10e5;          % carrier frequency in Hz
					samplingRate = Cell.Tx.WaveformInfo.SamplingRate;
				case 'uplink'
					fc = User.Tx.Freq*10e5;          % carrier frequency in Hz
					samplingRate = User.Tx.WaveformInfo.SamplingRate;
			end
			
			c = physconst('lightspeed'); % speed of light in m/s
			fd = (v*1000/3600)/c*fc;     % UT max Doppler frequency in Hz
			sig = [tempVar.RxWaveform;zeros(obj.SignalPadding,1)]; 
			
			switch obj.Channel.FadingModel
				case 'CDL'
					cdl = nrCDLChannel;
					cdl.DelayProfile = 'CDL-C';
					cdl.DelaySpread = 300e-9;
					cdl.CarrierFrequency = fc;
					cdl.MaximumDopplerShift = fd;
					cdl.SampleRate = TxNode.Tx.WaveformInfo.SamplingRate;
					cdl.InitialTime = obj.Channel.simulationTime;
					cdl.TransmitAntennaArray.Size = obj.Channel.Mimo.arrayTuple;
					cdl.ReceiveAntennaArray.Size = obj.Channel.Mimo.arrayTuple;
					cdl.SampleDensity = 256;
					cdl.Seed = seed;
					tempVar.RxWaveform = cdl(sig);
				case 'TDL'
					tdl = nrTDLChannel;
					
					% Set transmission direction for MIMO correlation
					switch mode
						case 'downlink'
							tdl.TransmissionDirection = 'Downlink';
						case 'uplink'
							tdl.TransmissionDirection = 'Uplink';
					end
					tdl.DelayProfile = 'TDL-E';
					tdl.DelaySpread = 300e-9;
					%tdl.MaximumDopplerShift = 0;
					tdl.MaximumDopplerShift = fd;
					tdl.SampleRate = samplingRate;
					tdl.InitialTime = obj.Channel.simulationTime;
					tdl.NumTransmitAntennas = obj.Channel.Mimo.numTxAntennas;
					tdl.NumReceiveAntennas = obj.Channel.Mimo.numRxAntennas;
					tdl.Seed = seed;
					%tdl.KFactorScaling = true;
					%tdl.KFactor = 3;
					[tempVar.RxWaveform, tempVar.RxPathGains, ~] = tdl(sig);
					tempVar.RxPathFilters = getPathFilters(tdl);
			end
		end
		
		%%% UTILITY FUNCTIONS
		function config = findCellConfig(obj, Cell)
			% findCellConfig finds the Cell config
			%
			% :param obj:
			% :param Cell:
			% :returns config:
			%
			
			cellString = sprintf('Cell%i',Cell.NCellID);
			config = obj.CellConfigs.(cellString);
		end
		
		function h = getImpulseResponse(obj, Mode, Cell, User)
			% Plotting of impulse response applied from TxNode to RxNode
			%
			% :param obj:
			% :param Mode:
			% :param Cell:
			% :param User:
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
		
		function tempVar = setWaveform(obj, TxNode, tempVar)
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
			
			tempVar.Waveform = TxNode.Tx.Waveform;
			tempVar.WaveformInfo =  TxNode.Tx.WaveformInfo;
		end
		
		function h = plotSFMap(obj, Cell)
			% plotSFMap
			%
			% :param obj:
			% :param Cell:
			% :returns h:
			%
			
			config = obj.findCellConfig(Cell);
			h = figure;
			contourf(config.SpatialMaps.axisLOS(1,:), config.SpatialMaps.axisLOS(2,:), config.SpatialMaps.LOS)
			hold on
			plot(config.Position(1),config.Position(2),'o', 'MarkerSize', 20, 'MarkerFaceColor', 'auto')
			xlabel('x [Meters]')
			ylabel('y [Meters]')
		end
		
		function RxNode = setReceivedSignal(obj, RxNode, tempVar, varargin)
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
				RxNode.Rx.setWaveform(userId, tempVar.RxWaveform, tempVar.WaveformInfo);
				RxNode.Rx.setRxPw(userId, tempVar.RxPowerWatt);
				RxNode.Rx.setSNR(userId, tempVar.RxSNR);
				RxNode.Rx.setSINR(userId, tempVar.RxSINR);
				RxNode.Rx.setPathConditions(userId, tempVar.RxPathGains, tempVar.RxPathFilters);
			elseif isa(RxNode, 'UserEquipment')
				RxNode.Rx.setWaveform(tempVar.RxWaveform, tempVar.WaveformInfo);
				RxNode.Rx.setRxPw(tempVar.RxPowerWatt);
				RxNode.Rx.setSNR(tempVar.RxSNR);
				RxNode.Rx.setSINR(tempVar.RxSINR);
				RxNode.Rx.setPathConditions(tempVar.RxPathGains, tempVar.RxPathFilters);
			end
		end
		
		function storeLinkCondition(obj, index, mode, tempVar)
			% storeLinkCondition
			%
			% :param obj:
			% :param index:
			% :param mode:
			%
			
			linkCondition = struct();
			linkCondition.Waveform = tempVar.RxWaveform;
			linkCondition.WaveformInfo =  tempVar.WaveformInfo;
			linkCondition.RxPwdBm = tempVar.RxPower;
			linkCondition.SNR = tempVar.RxSNR;
			linkCondition.SINR = tempVar.RxSINR;
			linkCondition.PathGains = tempVar.RxPathGains;
			linkCondition.PathFilters = tempVar.RxPathFilters;
			obj.LinkConditions.(mode){index} = linkCondition;
		end
		
		function tempVar = TempVariables(obj, tempVar)
			% Clear temporary variables. These are used for waveform manipulation and power tracking
			% The property TempSignalVariables is used, and is a struct of several parameters.
			%
			% :param obj:
			%
			tempVar = struct();
			tempVar.RxPower = [];
			tempVar.RxSNR = [];
			tempVar.RxSINR = [];
			tempVar.RxWaveform = [];
			tempVar.RxWaveformInfo = [];
			tempVar.RxPathGains = [];
			tempVar.RxPathFilters = [];
		end
	end
	
	methods (Access = private)
		
		function createSpatialMaps(obj)
			% createSpatialMaps
			%
			% :param obj:
			%
			
			% Construct structure for containing spatial maps
			cellStrings = fieldnames(obj.CellConfigs);
			for iCell = 1:length(cellStrings)
				config = obj.CellConfigs.(cellStrings{iCell});
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
				
				obj.CellConfigs.(cellStrings{iCell}).SpatialMaps = spatialMap;
			end
		end
		
		function LOS = spatialLOSstate(obj, Cell, userPosition, LOSprop)
			% Determine spatial LOS state by realizing random variable from
			% spatial correlated map and comparing to LOS probability. Done
			% according to 7.6.3.3
			%
			% :param obj:
			% :param Cell:
			% :param userPosition:
			% :param LOSprop:
			% :returns LOS:
			%
			
			config = obj.findCellConfig(Cell);
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
		
		function XCorr = computeShadowingLoss(obj, Cell, userPosition, LOS)
			% Interpolation between the random variables initialized
			% provides the magnitude of shadow fading given the LOS state.
			%
			% .. todo:: Compute this using the cholesky decomposition as explained in the WINNER II documents of all LSP.
			%
			% :param obj:
			% :param Cell:
			% :param userPosition:
			% :param LOS:
			% :returns XCorr:
			%
			
			config = obj.findCellConfig(Cell);
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
			elseif Position(2) < min(axisXY(2,:))
				extrapolation = true;
			end
			
			if extrapolation
				pos = sprintf('(%s)',num2str(Position));
				bound = sprintf('(%s)',num2str([min(axisXY(1,:)), min(axisXY(2,:)), max(axisXY(1,:)), max(axisXY(2,:))]));
				Logger.log(sprintf('Position of Rx out of bounds. Bounded by %s, position was %s. Increase Channel.getAreaSize',bound,pos), 'ERR')
			end
		end
		
		function [LOS, prop] = LOSprobability(txConfig, userConfig)
			% LOS probability using table 7.4.2-1 of 3GPP TR 38.901
			%
			% :param txConfig:
			% :param userConfig:
			% :returns LOS: LOS boolean
			% :returns prop: Probability
			%
			prop = losProb3gpp38901(txConfig.areaType, userConfig.d2d, userConfig.hUt);
			
			% Realize probability
			x = rand(length(prop(:,1)),length(prop(1,:)));
			LOS = prop;
			LOS(x>LOS) = 0;
			LOS(LOS~= 0) =1;
			
		end
		
		
	end
end