classdef MonsterChannel < matlab.mixin.Copyable
	properties
		Mode;
		Region;
		BuildingFootprints;
		ChannelModel;
		enableFading;
		InterferenceType;
		enableShadowing;
		enableReciprocity;
		LOSMethod;
		simulationRound = 0;
		simulationTime = 0;
		extraSamplesArea = 800;
		Estimator = struct();
		Logger;
		area;
	end
	
	methods
		function obj = MonsterChannel(Cells, Users, Config, Logger)
			% MonsterChannel
			%
			% :param Cells:
			% :param Users:
			% :param Config:
			% :returns obj:
			%
			obj.Logger = Logger;
			obj.Mode = Config.Channel.mode;
			obj.Region = Config.Channel.region;
			obj.enableFading = Config.Channel.fadingActive;
			obj.InterferenceType = Config.Channel.interferenceType;
			obj.enableShadowing = Config.Channel.shadowingActive;
			obj.enableReciprocity = Config.Channel.reciprocityActive;
			obj.LOSMethod = Config.Channel.losMethod;
			if strcmp(Config.Terrain.type, 'city')
				obj.BuildingFootprints = Config.Terrain.buildings;
			else 
				obj.BuildingFootprints = [];
			end
			obj.area = Config.Terrain.area;
			obj.setupChannel(Cells, Users);
			obj.createChannelEstimator();
		end
		
		function setupChannel(obj, Cells, Users)
			% setupChannel
			%
			% :param obj:
			% :param Cells:
			% :param Users:
			%

			switch obj.Mode
				case '3GPP38901'
					obj.ChannelModel = Monster3GPP38901(obj, Cells);
				case 'Quadriga'
					obj.setupQuadrigaLayout(Cells, Users);
			end
		end

		function createChannelEstimator(obj)
			dl.PilotAverage = 'UserDefined';    % Type of pilot symbol averaging
			dl.FreqWindow = 31;                 % Frequency window size
			dl.TimeWindow = 23;                 % Time window size
			dl.InterpType = 'Cubic';            % 2D interpolation type
			dl.InterpWindow = 'Centered';       % Interpolation window type
			dl.InterpWinSize = 1;               % Interpolation window size

			ul.PilotAverage = 'UserDefined';    % Type of pilot averaging
			ul.FreqWindow = 13;                 % Frequency averaging windows in REs
			ul.TimeWindow = 1;                  % Time averaging windows in REs
			ul.InterpType = 'cubic';            % Interpolation type
			ul.Reference = 'Antennas';          % Reference for channel estimation

			obj.Estimator.Downlink = dl;
			obj.Estimator.Uplink = ul;
		end
		
		function traverse(obj, Cells, Users, Mode)
			% This function manipulates the waveform of the Tx module of either stations, or users depending on the selected mode
			% E.g. `Mode='uplink'` uses the Tx modules of the Users, and hereof waveforms, transmission power etc.
			% `Mode='downlink'` uses the Tx modules of the Cells, and hereof configurations.
			%
			% This function can only be used if the Cells have assigned users.
			%
			% :param obj:
			% :param Cells:
			% :param Users:
			% :param Mode:
			%

			if ~strcmp(Mode,'downlink') && ~strcmp(Mode,'uplink')
				obj.Logger.log('(MONSTER CHANNEL - traverse) Unknown channel type selected.','ERR', 'MonsterChannel:noChannelMode');
			end
			
			if any(~isa(Cells, 'EvolvedNodeB'))
				obj.Logger.log('(MONSTER CHANNEL - traverse) Unknown type of stations.','ERR', 'MonsterChannel:WrongCellClass');
			end
			
			if any(~isa(Users, 'UserEquipment'))
				obj.Logger.log('(MONSTER CHANNEL - traverse) Unknown type of users.','ERR', 'MonsterChannel:WrongUserClass');
			end
			
			% Filter stations and users
			[FilteredCells,~] = obj.getAssociated(Cells,Users);
			
			% Propagate waveforms
			if ~isempty(FilteredCells)
				obj.callChannelModel(Cells, Users, Mode);
			else
				obj.Logger.log('(MONSTER CHANNEL - traverse) No users found for any of the stations. Quitting traverse', 'ERR', 'MonsterChannel:NoUsersAssigned')
			end
			
		end
		
		function callChannelModel(obj, Cells, Users, Mode)
			% callChannelModel
			%
			% :param obj:
			% :param Cells:
			% :param Users:
			% :param Mode:
			%

			if isa(obj.ChannelModel, 'Monster3GPP38901')
				obj.ChannelModel.propagateWaveforms(Cells, Users, Mode);
			end
		end
		
		
		function seed = getLinkSeed(obj, rxObj, txObj)
			% getLinkSeed
			%
			% :param obj:
			% :param rxObj:
			% :param txObj:
			% :returns seed:
			%

			seed = rxObj.Seed * txObj.Seed + 10* obj.simulationRound;
		end
		
		function areaType = getAreaType(obj,Cell)
			% getAreaType
			%
			% :param obj:
			% :param Cell:
			% :returns areaType
			%

			if strcmp(Cell.BsClass, 'macro')
				areaType = obj.Region.macroScenario;
			elseif strcmp(Cell.BsClass,'micro')
				areaType = obj.Region.microScenario;
			end
		end
	
		
		function [H, sampleGrid] = signalPowerMap(obj, Cells, User, Resolution)
			% signalPowerMap
			%
			% :param obj:
			% :param Cells:
			% :param User:
			% :param Resolution:
			% 

			% Create sample Grid
			areaSize = obj.getAreaSize;
			X = -areaSize+Resolution*2:Resolution:areaSize-80;
			Y = -areaSize+Resolution*2:Resolution:areaSize-80;
			sampleGrid = [X;Y];
			% Get matrix for each Cell
			H=zeros(length(X),length(Y),length(Cells));
			for iCell=1:length(Cells)
				user=copy(User);
				H(:,:,iCell) =obj.ChannelModel.getreceivedPowerMatrix(Cells(iCell), user, sampleGrid);
			end
		end

		function h = plotPower(obj, Cells, User, resolution, Logger)
			[receivedPower, grid] = obj.signalPowerMap(Cells, User, resolution);
			%receivedPowerWatts = 10.^((receivedPower-30)./10);

			
			Logger.log('(MONSTER CHANNEL - plotPower) Computing Power map...','NFO');
			
			h = figure;
			contourf(grid(1,:),grid(2,:),max(receivedPower,[],3))
			c = colorbar();
			c.Label.String = 'Power [dBm]';
			xlabel('X [meters]')
			ylabel('Y [meters]')
			hold on
			for iCell = 1:length(Cells)
				plot(Cells(iCell).Position(1), Cells(iCell).Position(2), 'o', 'MarkerSize', 5, 'MarkerFaceColor', 'r')
			end


		end

		
		function h = plotSINR(obj, Cells, User, resolution, Logger)
			% plotSINR
			%
			% :obj: MonsterChannel instance
			% :Cells: Array<EvolvedNodeB> instances
			% :User: UserEquipment instance
			% :resolution: Float
			% :param Logger: MonsterLog instance
			
			[receivedPower, grid] = obj.signalPowerMap(Cells, User, resolution);
			receivedPowerWatts = 10.^((receivedPower-30)./10);
			[~, thermalNoise] = thermalLoss();

			for iCell = 1:length(Cells)
				% Get power of associated Cell
				receivedPowerCell = receivedPowerWatts(:,:,iCell);

				% Get power of interfering stations 
				% TODO: this needs to be based on the same class of stations.
				interferencePower = sum(receivedPowerWatts(:,:, 1:end ~= iCell),3);

				% Compute SINR
				SINR(:,:,iCell) = obj.calculateSINR(receivedPowerCell, interferencePower, thermalNoise);

			end

			Logger.log('(MONSTER CHANNEL - plotSINR) Computing SINR map...','NFO');
			
			h = figure;
			contourf(grid(1,:),grid(2,:),10*log10(max(SINR,[],3)))
			c = colorbar();
			c.Label.String = 'SINR [dB]';
			xlabel('X [meters]')
			ylabel('Y [meters]')
			hold on
			for iCell = 1:length(Cells)
				plot(Cells(iCell).Position(1), Cells(iCell).Position(2), 'o', 'MarkerSize', 5, 'MarkerFaceColor', 'r')
			end
		end
		
		function area = getAreaSize(obj)
			% getAreaSize
			%
			% :obj: MonsterChannel instance
			%
			
			% Extra samples for allowing interpolation. Error will be thrown in this is exceeded.
			area = obj.area(3) - obj.area(1) + obj.extraSamplesArea;
		end

		function list = getENBPowerList(obj, User, Cells, Mode)
			% getCellPowerList
			%
			% Returns list of received power to each Cell
			% :obj: MonsterChannel instance
			% :User: :UserEquipment:
			% :Cells: [:EvolvedNodeB]:
			% :Mode: 'downlink' or 'uplink'
			%

			if isa(obj.ChannelModel, 'Monster3GPP38901')
				list = obj.ChannelModel.listCellPower(User, Cells);
			end
		end


		function list = getENBSINRList(obj, User, Cells, Mode)
			% getENBSINRList
			%
			% Returns list of SINR for each Cell
			% :obj: MonsterChannel instance
			% :User: :UserEquipment:
			% :Cells: [:EvolvedNodeB]:
			% :Mode: 'downlink' or 'uplink'
			%

			if isa(obj.ChannelModel, 'Monster3GPP38901')
				list = obj.ChannelModel.listSINR(User, Cells, Mode);
			end
		end

		function eNBID = getENB(obj, User, Cells, Mode)
			% getENB
			%
			% Returns ID of eNB with highest received power
			% :obj: MonsterChannel instance
			% :User: :UserEquipment:
			% :Cells: [:EvolvedNodeB:]
			% :Mode: 'downlink' or 'uplink'
			%
			
			% get list of enb and received power to user
			list = obj.getENBPowerList(User, Cells, Mode);

			% Loop through data structure and find Cell with heighest received power
			fields = fieldnames(list);
			receivedPowerStructure = cellfun(@(x) getfield(list,x), fields);
			cellIds = [receivedPowerStructure.NCellID];
			[~, idx] = max([receivedPowerStructure.receivedPowerdBm]);
			eNBID = cellIds(idx);
		end
		
		function setupRound(obj, simRound, simTime)
			% setupRound updates the time properties of the channel for the time evolution
			%
			% :param simRound: Integer - current simulation round 
			% :param simTime: Double - current simulation time in seconds
			%

			obj.simulationRound = simRound;
			obj.simulationTime = simTime;
		end
		
		
		%%%%%%%%%%%%%%%%%%%%%%%%%%%
		%%%%% Quardiga model %%%%%%
		%%%%%%%%%%%%%%%%%%%%%%%%%%%
		function setupQuadrigaLayout(obj, Cells, Users)
			% Call Quadriga setup function
		end
		
		
		function [LOS, prop] = isLinkLOS(obj, txConfig, rxConfig, draw)
			% Check if link between `txPos` and `rxPos` is LOS using one of two methods
			%
			% 1. :attr:`SonohiChannel.LOSMethod` : :attr:`fresnel` 1st Fresnel zone and the building footprint.
			% 2. :attr:`SonohiChannel.LOSMethod` : :attr:`3GPP38901-probability` Uses probability given table 7.4.2-1 of 3GPP TR 38.901. See :meth:`ch.SONOHImodels.3GPP38901.sonohi3GPP38901.LOSprobability` for more the implementation.
			%
			% :param Cell: Need :attr:`Cells.Position` and :attr:`Cells.DlFreq`.
			% :type Cell: :class:`enb.EvolvedNodeB`
			% :param User: Need :attr:`User.Position`
			% :type User: :class:`ue.UserEquipment`
			% :param bool draw: Draws fresnel zone and elevation profile.
			% :returns: LOS (bool) indicating LOS
			% :returns: (optional) probability is returned if :attr:`3GPP38901-probability` is assigned
			
			% Check if User is indoor
			% Else use probability to determine LOS state
			% TODO: FIX
	
				switch obj.LOSMethod
					case 'fresnel'
							LOS = obj.fresnelLOScomputation(txConfig, rxConfig, draw);
							prop = NaN;
					case '3GPP38901-probability'
							[LOS, prop] = Monster3GPP38901.LOSprobability(txConfig, rxConfig);
					case 'NLOS'                   
						LOS = zeros(size(rxConfig.positions,1),1);
						prop = NaN;
					case 'LOS'
						LOS =  ones(size(rxConfig.positions,1),1);
						prop = NaN;
				end
			
		end
		
		
		function LOS = fresnelLOScomputation(obj, txConfig, rxConfig, draw)
			% fresnelLOScomputation
			%
			% :obj:
			% :Cell:
			% :User:
			% :draw:
			%

			txPos = txConfig.position;
			txFreq = txConfig.freq;
			rxPos = rxConfig.positions;
			
			[numPoints,distVec,elevProfile] = getElevationProfile(obj.BuildingFootprints, txPos, rxPos);
			
			distVec = distVec(2:end); % First is zero
			totalDistance = distVec(end); % Meters
			nthFresnel = 1;
			fRadius = zeros(length(distVec),nthFresnel);
			LOSPath = linspace(txPos(3), rxPos(3),  length(distVec))';
			
			for dist = 1:length(distVec)
				% Compute zones
				for zone = 1:nthFresnel
					fRadius(dist, zone) = fresnelZone(zone,  distVec(dist),  totalDistance-distVec(dist), txFreq*10e6);
				end
			end
			
			upperLos = LOSPath+fRadius;
			lowerLos = LOSPath-fRadius;
			losBoundary = lowerLos+(fRadius.*2)*0.6; % 60% which is needed to define LOS/NLOS
			LOS = true;
			
			% Check if any obstacles occupy 60% of the fresnel zone
			if sum(elevProfile' >= losBoundary)
				LOS = false;
			end
			
			if draw
				figure
				plot(distVec, elevProfile)
				hold on
				plot(distVec, LOSPath,'r--')
				plot(distVec, lowerLos, 'k--')
				plot(distVec, upperLos, 'k--')
				xlabel('Distance (m)')
				ylabel('Height (m)')
				legend('Building footprints', 'LOS path', '1st Fresnel zone')
			end
		end
		
		
		
	end
	
	methods(Static)

		function N0 = computeSpectralNoiseDensity(Cell, Mode, SNR, Nfft)
			% Compute spectral noise density NO
			%
			% :param obj:
			% :param Cell:
			% :param Mode:
			% :returns N0:
			%
			% TODO: Find citation for this computation. It's partly taken from matworks - however there is a theoretical equation for the symbol energy of OFDM signals.
			%
			
			switch Mode
				case 'downlink'
					Es = sqrt(2.0*Cell.CellRefP*double(Nfft));
					N0 = 1/(Es*sqrt(SNR));
				case 'uplink'
					N0 = 1/(sqrt(SNR)  * sqrt(double(Nfft)))/sqrt(2);
			end
			
		end
		

		function [SINR, SINRdB] = calculateSINR(receivedPower, inteferingPower, noisePower)
			% Calculates wideband SINR 
			%
			% :param receivedPower: Received power in watts
			% :param interferingPower: Total power of interfering signals in watts
			% :param noisePower: Power of noise in watts

			SINR = receivedPower ./ (inteferingPower + noisePower);
			SINRdB = 10*log10(SINR);

		end
		
		function [SNR, SNRdB, thermalNoise] = calculateSNR(Waveform, SamplingRate, Power)
			% Calculate SNR using thermal noise. Thermal noise is bandwidth dependent.
			%
			% :param obj:
			% :returns SNR:
			% :returns SNRdB:
			% :returns thermalNoise:
			%
			
			[thermalLossdBm, thermalNoise] = thermalLoss(Waveform, SamplingRate);
			rxNoiseFloor = thermalLossdBm;
			SNRdB = Power-rxNoiseFloor;
			SNR = 10.^((SNRdB)./10);
		end
		
		function interferingCells = getInterferingCells(SelectedCell, Cells)
			interferingCells = Cells(find(strcmp({Cells.BsClass},SelectedCell.BsClass)));
			interferingCells = interferingCells([interferingCells.NCellID]~=SelectedCell.NCellID);
		end

		function interferingUsers = getInterferingUsers(SelectedUser, AssociatedCell, Users, Cells)
			% Find all cells that share the same class as the one the user is associated with
			interferingCells = MonsterChannel.getInterferingCells(AssociatedCell, Cells);
			% Find all users scheduled/associated with that class of cells
			Pairing = MonsterChannel.getPairing([interferingCells, AssociatedCell],'uplink');
			Pairing = Pairing(2,Pairing(2,:) ~= SelectedUser.NCellID); % Remove the selected user
			interferingUsers = Users(Pairing);
		end
		
		function distance = getDistance(txPos,rxPos)
			% Get distance between txPos and rxPos
			distance = norm(rxPos-txPos);
		end
		
		
		function [cells, users] = getAssociated(Cells,Users)
			% Returns cells and users that are associated
			cells = [];
			for iCell = 1:length(Cells)
				UsersAssociated = [Cells(iCell).Users.UeId];
				UsersAssociated = UsersAssociated(UsersAssociated ~= -1);
				if ~isempty(UsersAssociated)
					cells = [cells, Cells(iCell)];
				end
			end
			
			UsersAssociated = [Cells.Users];
			UserIds = [UsersAssociated.UeId];
			UserIds = unique(UserIds);
			UserIds = UserIds(UserIds ~= -1);
			users = Users(ismember([Users.NCellID],UserIds));
		end
		
		function Pairing = getPairing(Cells, type)
			% Output: [Nlinks x 2] sized vector with pairings
			% where Nlinks is equal to the total number of associated users
			% for Input Cells.
			% E.g. Pairing(1,:) = All Cell ID's
			% E.g. Pairing(2,:) = All user ID's
			% and Pairing(1,1) = Describes the pairing of Cell and User
			
			% Get number of links associated with the Cell.
			
			nlink=1;
			for i = 1:length(Cells)
				
				switch type
					case 'downlink'
						association = [Cells(i).Users];
						users = extractUniqueIds([association.UeId]);
					case 'uplink'	
						scheduledUL = Cells(i).getUserIDsScheduledUL;
						users = scheduledUL;
				end
				
				for ii = 1:length(users)
					Pairing(:,nlink) = [Cells(i).NCellID; users(ii)]; %#ok
					nlink = nlink+1;
				end
			end
		end
	end	
end