classdef ChBulk_v2 < SonohiChannel
    
    methods(Access = private)
        function [intSig, intSigdBm] = getInterferers(obj,Stations,station,user)
            
            % Get power of each station that is not the serving station and
            % compute loss based on pathloss or in the case of winner on
            % both.
            % Computation needs to be done per spectral component, thus
            % interference needs to be computed as a transferfunction
            % This means the non-normalized spectrums needs to be added
            % after pathloss is added.
            
            % v1 Uses eHATA based pathloss computation for both cases
            % v2 Switch based on channel mode
            
            
            
            RxPw = zeros(1,length(Stations));
            for iStation = 1:length(Stations)
                if Stations(iStation).NCellID ~= station.NCellID
                    % Get rx of all other stations
                    StationC = Stations(iStation);
                    
                    StationC = StationC.resetScheduleDL();
                    StationC.Users(1:length(Stations(iStation).Users)) = struct('UeId', -1, 'CQI', -1, 'RSSI', -1);
                    StationC.Users(1).UeId = user.NCellID;
                    StationC.ScheduleDL(1).UeId = user.NCellID;
                    user.Rx.Waveform = [];
                    if strcmp(obj.DLMode,'eHATA')
                        eHATA = sonohieHATA(obj);
                        Users = eHATA.run(StationC,user);
                    elseif strcmp(obj.DLMode, 'winner')
                        WINNER = sonohiWINNER(StationC,user, obj,'downlink');
                        WINNER = WINNER.setup();
                        [~, Users] = WINNER.run(StationC,user);
                    end
                    RxPw(iStation) = Users.Rx.RxPwdBm;
                    rxSignorm = Users.Rx.Waveform;
                    
                    % Set correct power of all signals, rxSigNorm is the signal
                    % normalized. rxPw contains the estimated rx power based
                    % on tx power and the link budget
                    rxSig(:,iStation) = setPower(rxSignorm,RxPw(iStation));
                    
                    rxPwP = 10*log10(bandpower(rxSig(:,iStation)))+30;
                end
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
            
            if exist('rxSig','var')
                intSig = sum(rxSig,2);
                
                % total power of interfering signal
                intSigdBm = 10*log10(bandpower(intSig))+30;
            else
                intSig = 0;
                intSigdBm= 0;
            end
            %figure
            %plot(10*log10(abs(fftshift(fft(intSig)).^2)));
            
        end
    end
    
    methods
        function obj = ChBulk_v2(Param)
            obj.Area = Param.area;
            obj.DLMode = Param.channel.modeDL;
            obj.ULMode = Param.channel.modeUL;
            obj.Buildings = Param.buildings;
            obj.Draw = Param.draw;
            obj.Region = Param.channel.region;
        end
        
        function [Users,obj] = downlink(obj,Stations,Users)
            validateChannel(obj);
            validateStations(Stations);
            validateUsers(Users);
            stations = Stations;
            users = Users;
            
            [stations,users] = obj.getAssociated(Stations,Users);

            %[stations, users] = obj.getScheduledDL(Stations, Users);
            %try
               
            [~, users] = obj.DownlinkModel.run(stations,users,'channel',obj);
             
            %catch ME
            %  sonohilog('Something went wrong....','WRN')
            %end
            %Apply interference on all users if 'full' is enabled
            if strcmp(obj.fieldType,'full')
                users = obj.applyInterference(stations,users,'downlink');
            end
            
            % Overwrite in input struct
            for iUser = 1:length(users)
                ueId = users(iUser).NCellID;
                Users([Users.NCellID] == ueId) = users(iUser);
            end
            
            
        end
        
        function [Stations,Users,obj] = uplink(obj,Stations,Users,varargin)
%            sonohilog('Not implemented yet.','ERR')

            validateChannel(obj);
            validateStations(Stations);
            validateUsers(Users);
            [stations,users] = obj.getAssociated(Stations,Users);
            [stations,~] = obj.UplinkModel.run(stations,users,varargin);
            % Overwrite in input struct
            for iStation = 1:length(stations)
                StationID = stations(iStation).NCellID;
                Stations([Stations.NCellID] == StationID) = stations(iStation);
            end
            
            
        end
           
        
        function [Stations,Users,obj] = traverse(obj,Stations,Users,chtype,varargin)
            if isempty(varargin)
                obj.fieldType = 'full';
            else
                vargs = varargin;
                nVargs = length(vargs);
                
                for k = 1:nVargs
                    if strcmp(vargs{k},'field')
                        obj.fieldType = vargs{k+1};
                    end
                end
            end
            
            
            [stations,users] = obj.getAssociated(Stations,Users);

         
            if ~isempty(stations)
                switch chtype
                    case 'downlink'
                        [Users,obj] = obj.downlink(Stations,Users);
                    case 'uplink'
                        [Stations,obj] = obj.uplink(Stations,Users,varargin);
                end
            else
                sonohilog('No users found for any of the stations. Is this supposed to happen?','WRN')
            end

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
        
        function stationID = getAssociation(obj,Stations,User)
            
            validateStations(Stations);
            validateEmptyUsers([Stations.Users]);
            validateUsers(User);
            
            % For user try association with all stations and select
            % the one with highest Rx power
            sonohilog(sprintf('Finding User association for User(%i) based on Rx power...',User.NCellID),'NFO0')
            
            RxPw = zeros(length(Stations),1);
            for iStation = 1:length(Stations)
                %Local copy of all stations
                StationC = Stations(iStation);
                
                % Associate user
                StationC = StationC.resetScheduleDL();
                StationC.Users = struct('UeId', User.NCellID, 'CQI', -1, 'RSSI', -1);
                StationC.ScheduleDL(1).UeId = User.NCellID;
                User.ENodeBID = StationC.NCellID;
                
                
                obj = obj.setupChannelDL(StationC, User);
                
                % Reset any existing channel conditions
                %if strcmp(obj.Mode,'winner')
                %    obj.resetWinner;
                %end
                
                % Traverse channel
                for ll = 1:5
                    [~, UserRx] = obj.traverse(StationC,User,'downlink','field','pathloss');
                    RxPw(iStation,ll) = UserRx.Rx.RxPwdBm;
                end
                % Reset schedule
                
                % Debug distance
                distance(iStation) = obj.getDistance(StationC.Position,User.Position);
                
            end
            [minDistance, minStation] = min(distance);
            [maxPw,maxStation] = max(mean(RxPw,2));
            stationID = Stations(maxStation).NCellID;
        end
        
        
        
        function Users = applyInterference(obj,Stations,Users,chtype)
            
            switch chtype
                case 'downlink'
                    Users = obj.applyDownlinkInteference(Stations,Users);
                case 'uplink'
                    sonohilog('Not implemented yet.','ERR')
            end
            
            
        end
        
        
        function Users = applyDownlinkInteference(obj, Stations, Users)
            
            % Method used to apply the interference on a specific received waveform
            sonohilog('Computing and applying interference based on station class...','NFO')
            % Validate arguments
            validateChannel(obj);
            validateStations(Stations);
            validateUsers(Users);
            for iUser = 1:length(Users)
                user = Users(iUser);
                station = Stations(find([Stations.NCellID] == Users(iUser).ENodeBID));
                
                if isempty(station)
                    user.Rx.SINR = user.Rx.SNR;
                    Users(iUser) = user;
                    continue
                end
                % Find stations with the same BsClass
                % This ensures also same sampling frequency
                % TODO: make this frequency dependent.
                Stations = Stations(find(strcmp({Stations.BsClass},station.BsClass)));
                if isempty(Stations)
                    % No other interfering stations
                    user.Rx.SINR = user.Rx.SNR;
                    Users(iUser) = user;
                    continue
                end
                
                
                % Get the combined interfering signal and its loss
                [intSig, intSigdBm] = obj.getInterferers(Stations,station,user);
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
        
    end
end
