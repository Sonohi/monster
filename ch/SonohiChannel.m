classdef SonohiChannel < handle
	% This is the base coordinator class for the physical channels.
	%
	% Currently supported models: [:attr:`winner`, :attr:`eHATA`, :attr:`ITU1546`, :attr:`3GPP38901`, :attr:`B2B`]
	%
	% .. warning:: 'uplink' is currently only available in B2B mode.
	%
	% The constructor requires the following options:
	%
	% :input Param: Parameter struct containing the following:
	% :Param.channel.modeDL: (str) Channel model used in downlink. e.g. `'winner'`
	% :Param.channel.modeUL: (str) Channel model used in uplink. e.g. `'B2B'`
	% :Param.channel.region: (str) Region of channel. This changes based on the channel model as the mapping and definition is considered different. See each model for the configuration of this, e.g. :mod:`ch.SONOHImodels`
	% :Param.Seed: (int) Base seed for the channel
	% :Param.channel.enableFading: (bool) Enable/disable fading
	% :Param.channel.enableInterference: (bool) Enable/disable interference
	% :Param.enableShadowing: (bool) Enable/disable spartial correlated shadowing, currently only supported using :attr:`3GPP38901`
	% :Param.LOSMethod: (str) `'fresnel'` or `'3GPP38901-probability'`, See :meth:`ch.SonohiChannel.isLinkLOS` for more info.
	% :Param.buildings: (optional) Needed for `'fresnel'` LOSMethod, Structure containing footprints of buildings, given by (x0, y0, x1, y1) coordinates.
	properties
		ULMode;
		DLMode;
		Region;
		DownlinkModel;
		UplinkModel;
		fieldType; % replace this?
		Seed;
		iRound;
		enableFading;
		enableInterference;
		enableShadowing;
		LOSMethod;
		BuildingFootprints % Matrix containing footprints of buildings
	end
	
	methods
		function obj = SonohiChannel(Stations, Users, Param)
			obj.DLMode = Param.channel.modeDL;
			obj.ULMode = Param.channel.modeUL;
			obj.Region = Param.channel.region;
			obj.LOSMethod = Param.channel.LOSMethod;
			obj.Seed = Param.seed;
			obj.enableFading = Param.channel.enableFading;
			obj.enableInterference = Param.channel.enableInterference;
			obj.enableShadowing = Param.channel.enableShadowing;
			obj.BuildingFootprints = Param.buildings;
			obj.iRound = 0;
			
			% Get class for chosen model for downlink
			obj.DownlinkModel = obj.findChannelClass('downlink');
			obj.UplinkModel = obj.findChannelClass('uplink');
			
			obj.DownlinkModel.setup(Stations, Users, Param);

			if obj.enableShadowing
				obj.DownlinkModel.setupShadowing(Stations)
			end

			
		end
		
	end
	
	methods(Static)
		
		
		
		function distance = getDistance(txPos,rxPos)
			% Get distance between txPos and rxPos
			distance = norm(rxPos-txPos);
		end
		
		
		function [stations, users] = getAssociated(Stations,Users)
			% Returns stations and users that are associated
			stations = [];
			for istation = 1:length(Stations)
				UsersAssociated = [Stations(istation).Users.UeId];
				UsersAssociated = UsersAssociated(UsersAssociated ~= -1);
				if ~isempty(UsersAssociated)
					stations = [stations, Stations(istation)];
				end
			end
			
			
			UsersAssociated = [Stations.Users];
			UserIds = [UsersAssociated.UeId];
			UserIds = unique(UserIds);
			UserIds = UserIds(UserIds ~= -1);
			users = Users(ismember([Users.NCellID],UserIds));
			
		end
		
	end
	
	methods
		
		
		function areatype = getAreaType(obj,Station)
			if strcmp(Station.BsClass, 'macro')
				areatype = obj.Region.macroScenario;
			elseif strcmp(Station.BsClass,'micro')
				areatype = obj.Region.microScenario;
			elseif strcmp(Station.BsClass,'pico')
				areatype = obj.Region.picoScenario;
			end
		end
		
		
		function chModel = findChannelClass(obj,chtype)
			% Setup association to traverse
			switch chtype
				case 'downlink'
					mode = obj.DLMode;
				case 'uplink'
					mode = obj.ULMode;
			end
			
			if strcmp(mode,'eHATA')
				chModel = sonohieHATA(obj, chtype);
			elseif strcmp(mode,'ITU1546')
				chModel = sonohiITU(obj, chtype);
			elseif strcmp(mode, 'B2B')
				chModel = sonohiB2B(obj, chtype);
			elseif strcmp(mode, '3GPP38901')
				chModel = sonohi3GPP38901(obj, chtype);
			elseif strcmp(mode, 'winner')
				chModel = sonohiWINNERv2(obj, chtype);
			elseif strcmp(mode, 'Quadriga')
				chModel = sonohiQuadriga(obj, chtype);
			else
				sonohilog(sprintf('Channel mode: %s not supported. Choose [eHATA, ITU1546, winner]',mode),'ERR')
			end
			
			
			
		end
		
		function area = getAreaSize(obj)
			extraSamples = 5000; % Extra samples for allowing interpolation. Error will be thrown in this is exceeded.
			area = (max(obj.BuildingFootprints(:,3)) - min(obj.BuildingFootprints(:,1))) + extraSamples;
		end
		
		
		function [Stations, Users,obj] = runModel(obj,Stations,Users, chtype)
			validateChannel(obj);
			validateStations(Stations);
			validateUsers(Users);
			stations = Stations;
			users = Users;
			
			switch chtype
				case 'downlink'
					[~, users] = obj.DownlinkModel.run(stations,users,'channel',obj);
				case 'uplink'
					[stations, ~] = obj.UplinkModel.run(stations,users,'channel',obj);
			end
			
			if strcmp(obj.fieldType,'full')
				if obj.enableInterference
					users = obj.applyInterference(stations,users,chtype);
				end
			end
			
			Users = users;
			Stations = stations;
			
			
		end
		
		function [intSig, intSigdBm] = getInterferers(obj,interferingStations,associatedStation,user)
			
			% Get power of each station that is not the serving station and
			% compute loss based on pathloss or in the case of winner on
			% both.
			% Computation needs to be done per spectral component, thus
			% interference needs to be computed as a transferfunction
			% This means the non-normalized spectrums needs to be added
			% after pathloss is added.
			
			% v1 Uses eHATA based pathloss computation for both cases
			% v2 Switch based on channel mode
			% v3 switch replaced with setup and traverse functions as regularly used
			% v4 Removed check for interfering stations as this is done before this function call, renamed variables
			
			
			
			RxPw = zeros(1,length(interferingStations));
			for iStation = 1:length(interferingStations)
				% Get rx of all other stations
				StationC = interferingStations(iStation);
				
				% Clean the transmission scenario
				StationC = StationC.resetScheduleDL();
				StationC.Users(1:length(interferingStations(iStation).Users)) = struct('UeId', -1, 'CQI', -1, 'RSSI', -1);
				StationC.Users(1).UeId = user.NCellID;
				StationC.ScheduleDL(1).UeId = user.NCellID;
				user.Rx.Waveform = [];
				
				[~, user] = obj.DownlinkModel.run(StationC, user);
				
				% Extract power and waveform
				RxPw(iStation) = user.Rx.RxPwdBm;
				rxSignorm = user.Rx.Waveform;
				
				% Add timeshift to cause decorrelation between interfering
				% waveforms and actual waveform
				timeshift = randi([1 100]);
				rxSignorm = circshift(rxSignorm, timeshift);
				
				% Set correct power of all signals, rxSigNorm is the signal
				% normalized. rxPw contains the estimated rx power based
				% on tx power and the link budget
				
				rxSig(:,iStation) = setPower(rxSignorm,RxPw(iStation));
				
				rxPwP = 10*log10(bandpower(rxSig(:,iStation)))+30;
			end
			% Compute combined recieved spectrum (e.g. sum of all recieved
			% signals)
			
			% Make sure all time domain signals are same length,
			% e.g. resample in time-domain
			% TODO: replace this with a oneliner? Want an array of array
			% lengths, but signals needs to be saved in a cell size they
			% can differ in size.
			%figure
			%hold on
			%for sigs = 1:length(rxSig(1,:))
			%   if ~isempty(rxSig(:,sigs))
			%       plot(10*log10(abs(fftshift(fft(rxSig(:,sigs)).^2))));
			%   end
			%end
			intSig = sum(rxSig,2);
			% total power of interfering signal
			intSigdBm = 10*log10(bandpower(intSig))+30;
		end
		
		function Users = applyInterference(obj,Stations,Users,chtype)
			
			switch chtype
				case 'downlink'
					Users = obj.applyDownlinkInteference(Stations,Users);
				case 'uplink'
					sonohilog('Interference computation in uplink not implemented yet.','WRN')
			end
			
			
		end
		
		function Users = applyDownlinkInteference(obj, Stations, Users)
			
			% Method used to apply the interference on a specific received waveform
			sonohilog('Computing and applying interference based on station class','NFO')
			% Validate arguments
			validateChannel(obj);
			validateStations(Stations);
			validateUsers(Users);
			for iUser = 1:length(Users)
				user = Users(iUser);
				
				% Find associated eNB
				AssociatedStation = Stations(find([Stations.NCellID] == Users(iUser).ENodeBID));
				
				if isempty(AssociatedStation)
					user.Rx.SINR = user.Rx.SNR;
					Users(iUser) = user;
					continue
				end
				% Find stations with the same BsClass
				% This ensures also same sampling frequency
				% TODO: make this frequency dependent.
				interferingStations = Stations(find(strcmp({Stations.BsClass},AssociatedStation.BsClass)));
				interferingStations = interferingStations([interferingStations.NCellID]~=AssociatedStation.NCellID);
				if isempty(interferingStations)
					% No other interfering stations
					user.Rx.SINR = user.Rx.SNR;
					Users(iUser) = user;
					continue
				end
				
				
				% Get the combined interfering signal and its loss
				[intSig, intSigdBm] = obj.getInterferers(interferingStations,AssociatedStation,user);
				user.Rx.IntSigLoss = intSigdBm;
				% If no interference is computed intSig is zero
				if intSig == 0
					user.Rx.SINR =  user.Rx.SNR;
					Users(iUser) = user;
					continue
				end
				% Now combine the interfering and serving signal
				% Set the calculated rx power to the waveform so the combined
				% signal can be created.
				NormPw = 10*log10(bandpower(user.Rx.Waveform))+30;
				UserRxSig = setPower(user.Rx.Waveform,user.Rx.RxPwdBm);
				
				% check power is set correct
				powerThreshold = 0.05;
				UserRxSigPwdBm = 10*log10(bandpower(UserRxSig))+30;
				if abs(UserRxSigPwdBm-user.Rx.RxPwdBm) > powerThreshold %in dB
					sonohilog('Power scaling is incorrect or exceeded threshold of dB','WRN')
				end
				
				% Create combined signal
				rxSig = user.RxAmpli*UserRxSig + intSig;
				user.Rx.RxPwdBm;
				
				% Amplify the combined waveform such the energy is normalized per symbol
				% This corresponds to normalizing the transmitted waveform with the
				% interfering waveforms.
				% TODO: Generalize this, this is not completely accurate.
				user.Rx.Waveform = setPower(rxSig,NormPw);
				
				%                         figure
				%                         hold on
				%                         plot(10*log10(abs(fftshift(fft(rxSig)).^2)));
				%                         plot(10*log10(abs(fftshift(fft(UserRxSig)).^2)));
				%                         plot(10*log10(abs(fftshift(fft(intSig)).^2)));
				%                         legend('Combined signal (w interference)','Unnormalized received waveform','Interference')
				
				% SINR is then given as the SNR (dB difference towards noise floor)
				% with the additional loss of the interference signal.
				if (user.Rx.RxPwdBm-intSigdBm) >= 0
					user.Rx.SINR = 10^((user.Rx.SNRdB - (user.Rx.RxPwdBm-intSigdBm))/10);
				else
					user.Rx.SINR = 10^((user.Rx.RxPwdBm-intSigdBm)/10);
					% Update RxPw
				end
				
				
				Users(iUser) = user;
			end
			
			
		end
		
		
		function stationID = getAssociation(obj,Stations,User)
			
			validateStations(Stations);
			validateEmptyUsers([Stations.Users]);
			validateUsers(User);
			
			% For user try association with all stations and select
			% the one with highest Rx power
			sonohilog(sprintf('Finding User association for User(%i) based on Rx power',User.NCellID),'NFO0')
			
			RxPw = cell(length(Stations),1);
			for iStation = 1:length(Stations)
				%Local copy of all stations
				StationC = Stations(iStation);
				
				% Associate user
				StationC = StationC.resetScheduleDL();
				StationC.Users = struct('UeId', User.NCellID, 'CQI', -1, 'RSSI', -1);
				StationC.ScheduleDL(1).UeId = User.NCellID;
				User.ENodeBID = StationC.NCellID;
				
				
				
				% Reset any existing channel conditions
				%if strcmp(obj.Mode,'winner')
				%    obj.resetWinner;
				%end
				
				% Traverse channel
				[~, UserRx] = obj.traverse(StationC,User,'downlink','field','pathloss');
				RxPw{iStation} = UserRx.Rx.RxPwdBm;
				
				% Get power measurements from last rounds, maximum of 10 rounds.
				previous_measurements = UserRx.Rx.getFromHistory('RxPwdBm',StationC.NCellID);
				
				if length(previous_measurements) > 10
					RxPw{iStation} = [RxPw{iStation} previous_measurements(end-10:end)]';
				elseif length(previous_measurements) <= 10 && length(previous_measurements) ~= 0
					RxPw{iStation} = [RxPw{iStation} previous_measurements];
				end
				
				% Debug distance
				distance(iStation) = obj.getDistance(StationC.Position,User.Position);
				
			end
			
			% History can contain zeros, loop to remove these per row and
			% provide with mean value
			for iStation = 1:length(Stations)
				measurements = RxPw{iStation};
				mean_power(iStation) = mean(measurements(measurements ~= 0));
			end
			[maxPw,maxStation] = max(mean_power);
			stationID = Stations(maxStation).NCellID;
		end
		
		
		
		function Pairing = getPairing(obj,Stations)
			% Output: [Nlinks x 2] sized vector with pairings
			% where Nlinks is equal to the total number of scheduled users
			% for Input Stations.
			% E.g. Pairing(1,:) = All station ID's
			% E.g. Pairing(2,:) = All user ID's
			% and Pairing(1,1) = Describes the pairing of Station and User
			
			validateChannel(obj);
			validateStations(Stations);
			
			% Get number of links associated with the station.
			
			nlink=1;
			for i = 1:length(Stations)
				schedule = [Stations(i).Users];
				users = extractUniqueIds([schedule.UeId]);
				for ii = 1:length(users)
					Pairing(:,nlink) = [Stations(i).NCellID; users(ii)]; %#ok
					nlink = nlink+1;
				end
			end
			
		end
		
		function [LOS, prop] = isLinkLOS(obj, Station, User, draw)
			% Check if link between `txPos` and `rxPos` is LOS using one of two methods
			%
			% 1. :attr:`SonohiChannel.LOSMethod` : :attr:`fresnel` 1st Fresnel zone and the building footprint.
			% 2. :attr:`SonohiChannel.LOSMethod` : :attr:`3GPP38901-probability` Uses probability given table 7.4.2-1 of 3GPP TR 38.901. See :meth:`ch.SONOHImodels.3GPP38901.sonohi3GPP38901.LOSprobability` for more the implementation.
			%
			% :param Station: Need :attr:`Stations.Position` and :attr:`Stations.DlFreq`.
			% :type Station: :class:`enb.EvolvedNodeB`
			% :param User: Need :attr:`User.Position`
			% :type User: :class:`ue.UserEquipment`
			% :param bool draw: Draws fresnel zone and elevation profile.
			% :returns: LOS (bool) indicating LOS
            % :returns: (optional) probability is returned if :attr:`3GPP38901-probability` is assigned
            
            % Check if User is indoor
            % Else use probability to determine LOS state
            if User.Mobility.Indoor 
                LOS = 0;
                prop = NaN;
            else
			
                switch obj.LOSMethod
                    case 'fresnel'
                        LOS = obj.fresnelLOScomputation(Station, User, draw);
                        prop = NaN;
                    case '3GPP38901-probability'
                        [LOS, prop] = sonohi3GPP38901.LOSprobability(obj, Station, User);
												
										case 'NLOS'
											LOS = 0;
											prop = NaN;

										case 'LOS'
											LOS = 1;
											prop = NaN;
										
                end
                
            end
		end
		
		function LOS = fresnelLOScomputation(obj, Station, User, draw)
			txPos = Station.Position;
			txFreq = Station.DlFreq;
			rxPos = User.Position;
			
			[numPoints,distVec,elevProfile] = obj.getElevation(txPos,rxPos);
			
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
		
		
		function [numPoints,distVec,elavationProfile] = getElevation(obj,txPos,rxPos)
			% Moves through the building footprints structure and gathers the
			% height. A resolution of 0.05 meters used. Outputs a distance vector
			%
			% :param txPos: Position consisting of x, y, z coordinates
			% :param rxPos: Position consisting of x, y, z coordinates
			% :returns: `numPoints` number of elevation points between txPos and rxPos
			% :returns: `distVec` vector with resolution 0.05 meters from txPos to rxPos
			% :returns: `elevationProfile` vector of height values
			elavationProfile(1) = 0;
			distVec(1) = 0;
			
			% Check if x and y are equal
			if txPos(1:2) == rxPos(1:2)
				numPoints = 0;
				distVec = 0;
				elavationProfile = 0;
			else
				
				% Walk towards rxPos
				signX = sign(rxPos(1)-txPos(1));
				
				signY = sign(rxPos(2)-txPos(2));
				
				avgG = (txPos(1)-rxPos(1))/(txPos(2)-rxPos(2))+normrnd(0,0.01); %Small offset
				position(1:2,1) = txPos(1:2);
				i = 2;
				max_i = 10e6;
				numPoints = 0;
				resolution = 0.05; % Given in meters
				
				while true
					if i >= max_i
						break;
					end
					
					% Check current distance
					distance = norm(position(1:2,i-1)'-rxPos(1:2));
					
					% Move position
					[moved_dist,position(1:2,i)] = move(position(1:2,i-1),signX,signY,avgG,resolution);
					distVec(i) = distVec(i-1)+moved_dist; %#ok
					
					% Check if new position is at a greater distance, if so, we
					% passed it.
					distance_n = norm(position(1:2,i)'-rxPos(1:2));
					if distance_n >= distance
						break;
					else
						% Check if we're inside a building
						fbuildings_x = obj.BuildingFootprints(obj.BuildingFootprints(:,1) < position(1,i) & obj.BuildingFootprints(:,3) > position(1,i),:);
						fbuildings_y = fbuildings_x(fbuildings_x(:,2) < position(2,i) & fbuildings_x(:,4) > position(2,i),:);
						
						if ~isempty(fbuildings_y)
							elavationProfile(i) = fbuildings_y(5); %#ok
							if elavationProfile(i-1) == 0
								numPoints = numPoints +1;
							end
						else
							elavationProfile(i) = 0; %#ok
							
						end
					end
					i = i+1;
					
				end
				
			end
			
			
			
			function [distance,position] = move(position,signX,signY,avgG,moveS)
				if abs(avgG) > 1
					moveX = abs(avgG)*signX*moveS;
					moveY = 1*signY*moveS;
					position(1) = position(1)+moveX;
					position(2) = position(2)+moveY;
					
				else
					moveX = 1*signX*moveS;
					moveY = (1/abs(avgG))*signY*moveS;
					position(1) = position(1)+moveX;
					position(2) = position(2)+moveY;
				end
				distance = sqrt(moveX^2+moveY^2);
			end
			
		end
		
		function seed = getLinkSeed(obj, rxObj)
			seed = obj.Seed+10*obj.iRound^2+5*rxObj.NCellID^2;
		end
		
		function simTime = getSimTime(obj)
			% TODO: This should be moved to a parent API
			simTime = obj.iRound*10^-3;
		end
		
		
	end
	
	
	
end