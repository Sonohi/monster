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
    eHATA;
    fieldType;
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
    
    function [stations, users]  = getScheduled(Stations,Users)
      % Find stations that have scheduled users.
      schedules = {Stations.Schedule};
      usersS = cellfun(@(x) unique([x.UeId]), schedules, 'UniformOutput', false);
      stationsS = cellfun(@(x) x(x~= 0), usersS, 'UniformOutput', false);
      stationsS = ~cellfun('isempty',stationsS);
      stations = Stations(stationsS);
      
      % Find users that are scheduled.
      lens = sum(cellfun('length',usersS),1);
      usersC = zeros(max(lens),numel(lens));
      usersC(bsxfun(@le,[1:max(lens)]',lens)) = horzcat(usersS{:});
      usersC = reshape( usersC ,1,numel(usersC));
      usersC = usersC(usersC ~= 0);
      users = Users(ismember([Users.UeId],usersC));
      
    end
    
  end
  
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
          
          StationC = StationC.resetSchedule();
          StationC.Users = zeros(1,length(Stations(iStation).Users));
          StationC.Users(1) = user.UeId;
          StationC.Schedule(1).UeId = user.UeId;
          user.Rx.Waveform = [];
          if strcmp(obj.Mode,'eHATA')
            eHATA = sonohieHATA(obj);
            Users = eHATA.run(StationC,user);
          elseif strcmp(obj.Mode, 'winner')
            WINNER = sonohiWINNER(StationC,user, obj);
            WINNER = WINNER.setup();
            Users = WINNER.run(StationC,user);
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
      obj.Mode = Param.channel.mode;
      obj.Buildings = Param.buildings;
      obj.Draw = Param.draw;
      obj.Region = Param.channel.region;
    end
    
    
    
    function [Stations,Users,obj] = traverse(obj,Stations,Users,varargin)
      validateChannel(obj);
      validateStations(Stations);
      validateUsers(Users);
      
      [stations, users] = obj.getScheduled(Stations, Users);
      
      if nargin > 3
        nVargs = length(varargin);
        for k = 1:nVargs
          if strcmp(varargin{k},'field')
            obj.fieldType = varargin{k+1};
          end
        end
      else
        obj.fieldType = 'full';
        
      end
      
      if strcmp(obj.Mode,'winner')
        users = obj.WINNER.run(stations,users);
        
      elseif strcmp(obj.Mode,'eHATA')
        obj.eHATA.Channel = obj;
        users = obj.eHATA.run(stations,users);
        
      elseif strcmp(obj.Mode,'B2B')
        
        sonohilog('Back2Back channel mode selected, no channel actually traversed', 'WRN');
        for iUser = 1:length(users)
          iServingStation = find([Stations.NCellID] == Users(iUser).ENodeB);
          Users(iUser).Rx.Waveform = Stations(iServingStation).Tx.Waveform;
        end
      end
      
      %Apply interference on all users if 'full' is enabled
      if strcmp(obj.fieldType,'full')
        users = obj.applyInterference(stations,users);
      end
      
      % Overwrite in input struct
      for iUser = 1:length(users)
        ueId = users(iUser).UeId;
        Users([Users.UeId] == ueId) = users(iUser);
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
        schedule = [Stations(i).Schedule];
        users = removeZeros(unique([schedule.UeId]));
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
      sonohilog(sprintf('Finding User association for User(%i) based on Rx power...',User.UeId),'NFO0')
      
      RxPw = zeros(length(Stations),1);
      for iStation = 1:length(Stations)
        %Local copy of all stations
        StationC = Stations;
        
        % Associate user
        StationC(iStation).resetSchedule();
        StationC(iStation).Schedule(1).UeId = User.UeId;
        User.ENodeB = StationC(iStation).NCellID;
        
        % TODO: move this guy so the Channel setup is used instead
        if strcmp(obj.Mode,'eHATA') 
            obj.eHATA = sonohieHATA(obj);
        elseif strcmp(obj.Mode,'winner')
            obj.WINNER = sonohiWINNER(StationC(iStation),User, obj);
            obj.WINNER = obj.WINNER.setup();  
        end
        
        % Reset any existing channel conditions
        %if strcmp(obj.Mode,'winner')
        %    obj.resetWinner;
        %end
        
        % Traverse channel
        for ll = 1:5
            [~, UserRx] = obj.traverse(StationC(iStation),User,'field','pathloss');
            RxPw(iStation,ll) = UserRx.Rx.RxPwdBm;
        end
        % Reset schedule
        
        % Debug distance
        distance(iStation) = obj.getDistance(StationC(iStation).Position,User.Position);
        
      end
      [minDistance, minStation] = min(distance);
      [maxPw,maxStation] = max(mean(RxPw,2));
      stationID = Stations(maxStation).NCellID;
    end
    
    function obj = resetChannel(obj)
      obj.WINNER = [];
      obj.eHATA = [];
    end
    
    function obj = setupChannel(obj,Stations,Users)
        [stations, users] = obj.getScheduled(Stations, Users);
        if strcmp(obj.Mode,'winner')
            obj.WINNER = sonohiWINNER(stations,users, obj);
            obj.WINNER = obj.WINNER.setup();
        elseif strcmp(obj.Mode,'eHATA')
            obj.eHATA = sonohieHATA(obj);
        end
        
    end
    
    function Users = applyInterference(obj,Stations,Users)
      % Method used to apply the interference on a specific received waveform
      sonohilog('Computing and applying interference based on station class...','NFO')
      % Validate arguments
      validateChannel(obj);
      validateStations(Stations);
      validateUsers(Users);
      for iUser = 1:length(Users)
        user = Users(iUser);
        station = Stations(find([Stations.NCellID] == Users(iUser).ENodeB));
        
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
