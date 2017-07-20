classdef ChBulk_v2
	%CHBULK_V2 Summary of this class goes here
	%   Detailed explanation goes here
	
	properties
		Area;
		Mode;
		Buildings;
		Draw;
		Region;
        WINNER;
	end
	
	methods(Static)
		
		
		function distance = getDistance(txPos,rxPos)
			distance = norm(rxPos-txPos);
		end
		
		function thermalNoise = ThermalNoise(NDLRB)
			switch NDLRB
				case 6
					BW = 1.4e6;
				case 15
					BW = 3e6;
				case 25
					BW = 5e6;
				case 50
					BW = 10e6;
				case 75
					BW = 15e6;
				case 100
					BW = 20e6;
			end
			
			T = 290;
			k = physconst('Boltzmann');
			thermalNoise = k*T*BW;
		end
		
		
		
		
	end
	
	methods(Access = private)
		
		function [numPoints,distVec,elavationProfile] = getElevation(obj,txPos,rxPos)
            % TODO, move to seperate class
			elavationProfile(1) = 0;
			distVec(1) = 0;
			% Walk towards rxPos
			signX = sign(rxPos(1)-txPos(1));
			signY = sign(rxPos(2)-txPos(2));
			avgG = (txPos(1)-rxPos(1))/(txPos(2)-rxPos(2));
			position(1:2,1) = txPos(1:2);
			%plot(position(1,1),position(2,1),'r<')
			i = 2;
			numPoints = 0;
			while true
				% Check current distance
				distance = norm(position(1:2,i-1)'-rxPos(1:2));
				
				% Move position
				[moved_dist,position(1:2,i)] = move(position(1:2,i-1),signX,signY,avgG,0.1);
				distVec(i) = distVec(i-1)+moved_dist;
				%plot(position(1,i),position(2,i),'bo')
				% Check if new position is at a greater distance, if so, we
				% passed it.
				distance_n = norm(position(1:2,i)'-rxPos(1:2));
				if distance_n > distance
					break;
				else
					% Check if we're inside a building
					fbuildings_x = obj.Buildings(obj.Buildings(:,1) < position(1,i) & obj.Buildings(:,3) > position(1,i),:);
					fbuildings_y = fbuildings_x(fbuildings_x(:,2) < position(2,i) & fbuildings_x(:,4) > position(2,i),:);
					
					if ~isempty(fbuildings_y)
						elavationProfile(i) = fbuildings_y(5);
						if elavationProfile(i-1) == 0
							numPoints = numPoints +1;
						end
					else
						elavationProfile(i) = 0;
						
					end
				end
				i = i+1;
			end
			
			%figure
			%plot(elavationProfile)
			
			
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
		
		function [rxSig, SNRLin, rxPw] = addPathlossAwgn(obj,Station,User,txSig,varargin)
			thermalNoise = obj.ThermalNoise(Station.NDLRB);
			hbPos = Station.Position;
			hmPos = User.Position;
			distance = obj.getDistance(hbPos,hmPos)/1e3;
			switch obj.Mode
				case 'eHATA'
					%[lossdB, ~] = ExtendedHata_MedianBasicPropLoss(Station.DlFreq, ...
					%  distance, hbPos(3), hmPos(3), obj.Region);

					[numPoints,distVec,elev_profile] = obj.getElevation(hbPos,hmPos);

					if numPoints == 0
						numPoints_scale = 1;
					else
						numPoints_scale = numPoints;
					end

					elev = [numPoints_scale; distVec(end)/(numPoints_scale); hbPos(3); elev_profile'; hmPos(3)];

					lossdB = ExtendedHata_PropLoss(Station.DlFreq, hbPos(3), ...
						hmPos(3), obj.Region, elev);
					
					
					
			end
			
			
			txPw = 10*log10(Station.Pmax)+30; %dBm.
			
			rxPw = txPw-lossdB;
			% SNR = P_rx_db - P_noise_db
			rxNoiseFloor = 10*log10(thermalNoise)+User.NoiseFigure;
			SNR = rxPw-rxNoiseFloor;
			SNRLin = 10^(SNR/10);
			str1 = sprintf('Station(%i) to User(%i)\n Distance: %s\n SNR:  %s\n',...
				Station.NCellID,User.UeId,num2str(distance),num2str(SNR));
			sonohilog(str1,'NFO0');
			
			%% Apply SNR
			
			% Compute average symbol energy
			% This is based on the number of useed subcarriers.
			% Scale it by the number of used RE since the power is
			% equally distributed
			Es = sqrt(2.0*Station.CellRefP*double(Station.WaveformInfo.Nfft)*Station.WaveformInfo.OfdmEnergyScale);
			
			% Compute spectral noise density NO
			N0 = 1/(Es*SNRLin);
			
			% Add AWGN
			
			noise = N0*complex(randn(size(txSig)), ...
				randn(size(txSig)));
			
			rxSig = txSig + noise;
			
		end
		
		function combinedLoss = getInterference(obj,Stations,station,user)
			
			% Get power of each station that is not the serving station and
			% compute loss based on pathloss or in the case of winner on
			% both.
			% Computation needs to be done per spectral component, thus
			% interference needs to be computed as a transferfunction
			% This means the non-normalized spectrums needs to be added
			% after pathloss is added.
			
			% v1 Uses eHATA based pathloss computation for both cases
			
			for iStation = 1:length(Stations)
				
				if Stations(iStation).NCellID ~= station.NCellID
					% Get rx of all other stations
					txSig = obj.addFading([...
						Stations(iStation).TxWaveform;zeros(25,1)],Stations(iStation).WaveformInfo);
					[rxSigNorm,~,rxPw(iStation)] = obj.addPathlossAwgn(Stations(iStation),user,txSig);
					
					% Set correct power of all signals, rxSigNorm is the signal
					% normalized. rxPw contains the estimated rx power based
					% on tx power and the link budget
					lossdB = 10*log10(bandpower(rxSigNorm))-rxPw(iStation);
					rxSig(:,iStation) =  rxSigNorm.*10^(-lossdB/20);
					
					
					
					rxPwP = 10*log10(bandpower(rxSig(:,iStation)));
				end
				
				
			end
			
			
			% Compute combined recieved spectrum (e.g. sum of all recieved
			% signals)
			
			intSig = sum(rxSig,2);
			
			% Get power of signal at independent frequency components.
			
			intSigLoss = 10*log10(bandpower(intSig));
			
			figure
			plot(10*log10(abs(fftshift(fft(intSig)).^2)));
			
			
			combinedLoss = 0;
			
		end
		
		function rx = addFading(obj,tx,info,varargin)
            
            
            % TODO, refactorize to seperate classes
            
            switch obj.Mode
                case 'eHATA'
                    cfg.SamplingRate = info.SamplingRate;
                    cfg.Seed = 1;                  % Random channel seed
                    cfg.NRxAnts = 1;               % 1 receive antenna
                    cfg.DelayProfile = 'EPA';      % EVA delay spread
                    cfg.DopplerFreq = 120;         % 120Hz Doppler frequency
                    cfg.MIMOCorrelation = 'Low';   % Low (no) MIMO correlation
                    cfg.InitTime = 0;              % Initialize at time zero
                    cfg.NTerms = 16;               % Oscillators used in fading model
                    cfg.ModelType = 'GMEDS';       % Rayleigh fading model type
                    cfg.InitPhase = 'Random';      % Random initial phases
                    cfg.NormalizePathGains = 'On'; % Normalize delay profile power
                    cfg.NormalizeTxAnts = 'On';    % Normalize for transmit antennas
                    % Pass data through the fading channel model
                    rx = lteFadingChannel(cfg,tx);
					
			end
			
		end
		




	end
	
	methods
		function obj = ChBulk_v2(Param)
			obj.Area = Param.area;
			obj.Mode = Param.channel.mode;
			obj.Buildings = Param.buildings;
			obj.Draw = Param.draw;
			obj.Region = Param.channel.region;
		end



		function [Stations,Users,obj] = traverse(obj,Stations,Users,varargin)
            validateattributes(Stations,{'EvolvedNodeB'},{'vector'})
            validateattributes(Users,{'UserEquipment'},{'vector'})
            validateattributes([Stations.Users],{'numeric'},{'>=',0})
           
            if nargin > 3
                nVargs = length(varargin);
                for k = 1:nVargs
                    if strcmp(varargin{k},'field')
                        fieldType = varargin{k+1};
                    end
                end
            else
                fieldType = 'full';
            end

			% Assuming one antenna port, number of links are equal to
			% number of users scheuled in the given round
			users  = [Stations.Users];
			numLinks = nnz(users);
			
			Pairing = obj.getPairing(Stations);
			% Apply channel based on configuration.
            % TODO, move logic to seperate class
			if strcmp(obj.Mode,'winner')
				
				%Check if transfer function is already computed:
				% If empty, e.g. not computed, compute impulse response and
				% store it for next syncroutine.
				if isempty(obj.WINNER)
                    obj.WINNER = sonohiWINNER(Stations,Users, obj);
					%[obj.WconfigLayout, obj.WconfigParset] = obj.initializeWinner(Stations,Users);
					obj.WINNER = obj.WINNER.setup();
				else
					sonohilog('Using previously computed WINNER','NFO0')
                end
				
                
                Users = obj.WINNER.run(Stations,Users);
				
				
			elseif strcmp(obj.Mode,'eHATA')
				for i = 1:numLinks
					station = Stations(Pairing(1,i));
                    
                    if strcmp(fieldType,'full')
                    
                        Users(Pairing(2,i)).RxWaveform = obj.addFading([...
                            station.TxWaveform;zeros(25,1)],station.WaveformInfo);
                    
                    
                    
                    %interLossdB = obj.getInterference(Stations,station,Users(Pairing(2,i)));
                    
					[Users(Pairing(2,i)).RxWaveform, SNRLin, rxPw] = obj.addPathlossAwgn(...
						station,Users(Pairing(2,i)),Users(Pairing(2,i)).RxWaveform);
                    
                    elseif strcmp(fieldType,'pathloss')
                       [Users([Users.UeId] == Pairing(2,i)).RxWaveform, SNRLin, rxPw] = obj.addPathlossAwgn(...
                            station,Users([Users.UeId] == Pairing(2,i)),Users([Users.UeId] == Pairing(2,i)).RxWaveform);
                    
                    end

                    Users([Users.UeId] == Pairing(2,i)).RxInfo.SNRdB = 10*log10(SNRLin);
                    Users([Users.UeId] == Pairing(2,i)).RxInfo.SNR = SNRLin;
                    Users([Users.UeId] == Pairing(2,i)).RxInfo.rxPw = rxPw;

				end
			end
			
		end
		
		function Pairing = getPairing(obj,Stations)
            % Output: [Nlinks x 2] sized vector with pairings
            % where Nlinks is equal to the total number of scheduled users
            % for Input Stations.
            % E.g. Pairing(1,:) = All station ID's
            % E.g. Pairing(2,:) = All user ID's
            % and Pairing(1,1) = Describes the pairing of Station and User
            
            validateattributes(Stations,{'EvolvedNodeB'},{'vector'})
            
			users  = [Stations.Users];
			
			nlink=1;
			for i = 1:length(Stations)
				for ii = 1:nnz(users(:,i))
					Pairing(:,nlink) = [i; users(ii,i)];
					nlink = nlink+1;
				end
			end

        end
        
        function stationID = getAssociation(obj,Stations,User) 
            
            validateattributes(Stations,{'EvolvedNodeB'},{'vector'})
            validateattributes([Stations.Users],{'numeric'},{'<=',0})
            validateattributes(User,{'UserEquipment'},{'size',[1,1]})
           
            % For user try association with all stations and select
            % the one with highest Rx power
            sonohilog(sprintf('Finding User association for User(%i) based on Rx power...',User.UeId),'NFO')
            
            RxPw = zeros(length(Stations),1);
            for iStation = 1:length(Stations)
                %Local copy of all stations
                StationC = Stations;
                
                % Associate user
                StationC(iStation).Users(1,1) = User.UeId;

                % Reset any existing channel conditions
                %if strcmp(obj.Mode,'winner')
                %    obj.resetWinner;
                %end
                
                % Set mode for eHATA (increased computational speed)
                obj.Mode = 'eHATA';
               
                % Traverse channel
                [~, UserRx] = obj.traverse(StationC,User,'field','pathloss');
                RxPw(iStation) = UserRx.RxInfo.rxPw;
            end
            [maxPw,maxStation] = max(RxPw);
            stationID = Stations(maxStation).NCellID;
        end
        
        function obj = resetWinner(obj)
            obj.WINNER = [];
        end

	end
end
