classdef SonohiChannel
  % This is the base coordinator class for the physical channels.
  %
  % The constructor requires the following options:
  %
  % :input Param: Parameter struct containing the following:
  % :Param.modeDL: (str) Mode of downlink
  % :Param.modeUL: (str) Mode of uplink
  % :Param.region: (str) Region of channel
  % :Param.Seed: (int) Base seed for the channel
  % :Param.enableFading: (bool) Enable/disable fading
  % :Param.enableInterference: (bool) Enable/disable interference
  
  %% Properties
  properties
    ULMode;
    DLMode;
    Region;
    DownlinkModel;
    UplinkModel;
    fieldType; % replace this?
    Seed;
    SimTime;
    enableFading;
    enableInterference;
  end
  
  methods
    function obj = SonohiChannel(Param)
      obj.DLMode = Param.channel.modeDL;
      obj.ULMode = Param.channel.modeUL;
      obj.Region = Param.channel.region;
      obj.Seed = Param.seed;
      obj.enableFading = Param.channel.enableFading;
      obj.enableInterference = Param.channel.enableInterference;
    end
    
  end
  
  methods(Static)
    
    
    function distance = getDistance(txPos,rxPos)
      % Get distance between txPos and rxPos
      distance = norm(rxPos-txPos);
    end
    
    function thermalNoise = ThermalNoise(NDLRB)
      % Calculate thermalnoise based on bandwidth
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
                        
  function chModel = setupChannel(obj,Stations,Users,chtype)
    % Setup association to traverse
    switch chtype
        case 'downlink'
            mode = obj.DLMode;
        case 'uplink'
            mode = obj.ULMode;
    end
    
    if strcmp(mode,'winner')
        WINNER = sonohiWINNERv2(Stations,Users, obj,chtype);
        chModel = WINNER.setup();
    elseif strcmp(mode,'eHATA')
        chModel = sonohieHATA(obj, chtype);
    elseif strcmp(mode,'ITU1546')
        chModel = sonohiITU(obj, chtype);
    elseif strcmp(mode, 'B2B')
        chModel = sonohiB2B(obj, chtype);
    else
        sonohilog(sprintf('Channel mode: %s not supported. Choose [eHATA, ITU1546, winner]',mode),'ERR')
    end
    
    
    
end

    function [Users,obj] = runModel(obj,Stations,Users, chtype)
      validateChannel(obj);
      validateStations(Stations);
      validateUsers(Users);
      stations = Stations;
      users = Users;
      
      switch chtype
        case 'downlink'
          [~, users] = obj.DownlinkModel.run(stations,users,'channel',obj);
        case 'uplink'
          [~, users] = obj.UplinkModel.run(stations,users,'channel',obj);
      end
      
      if strcmp(obj.fieldType,'full')
        if obj.enableInterference
          users = obj.applyInterference(stations,users,chtype);
        end
      end
      
      % Overwrite in input struct
      for iUser = 1:length(users)
        ueId = users(iUser).NCellID;
        Users([Users.NCellID] == ueId) = users(iUser);
      end
      
      
    end
    
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
      % v3 switch replaced with setup and traverse functions as regularly used
      
      
      
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
          
          % Select channel model using switcher
          obj = obj.setupChannelDL(StationC, user);
          
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
        
        obj = obj.setupChannelDL(StationC, User);
        
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
    
    
  end
  
  
  
end