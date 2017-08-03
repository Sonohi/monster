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

      eHATA = sonohieHATA(obj);
      RxPw = zeros(1,length(Stations));
      for iStation = 1:length(Stations)
        if Stations(iStation).NCellID ~= station.NCellID
          % Get rx of all other stations
          StationC = Stations(iStation);
          StationC.Users = zeros(1,length(Stations(iStation).Users));
          StationC.Users(1) = user.UeId;
          user.Rx.Waveform = [];

          Users = eHATA.run(StationC,user);
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
      %validateEmptyUsers([Stations.Users]);

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

      % Assuming one antenna port, number of links are equal to
      % number of users scheuled in the given round
      users  = [Stations.Users];
      numLinks = nnz(users);

      Pairing = obj.getPairing(Stations);
      % Apply channel based on configuration.
      if strcmp(obj.Mode,'winner')
        %Check if transfer function is already computed:
        % If empty, e.g. not computed, compute impulse response and
        % store it for next syncroutine.
        % TODO: move this to WINNER. e.g. construction and setup is
        % called in run.
        if isempty(obj.WINNER)
          obj.WINNER = sonohiWINNER(Stations,Users, obj);
          %[obj.WconfigLayout, obj.WconfigParset] = obj.initializeWinner(Stations,Users);
          obj.WINNER = obj.WINNER.setup();
        else
          sonohilog('Using previously computed WINNER','NFO0')
        end

        Users = obj.WINNER.run(Stations,Users);

      elseif strcmp(obj.Mode,'eHATA')
        if isempty(obj.eHATA)
          obj.eHATA = sonohieHATA(obj);
        end
        Users = obj.eHATA.run(Stations,Users);
      elseif strcmp(obj.Mode,'B2B')
        sonohilog('Back2Back channel mode selected, no channel actually traversed', 'WRN');
        for iUser = 1:length(Users)
          iServingStation = find([Stations.NCellID] == Users(iUser).ENodeB);
          Users(iUser).RxWaveform = Stations(iServingStation).TxWaveform;
        end
      end

      % Apply interference on all users if 'full' is enabled
      if strcmp(obj.fieldType,'full')
        Users = obj.applyInterference(Stations,Users);
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

      users  = [Stations.Users];

      nlink=1;
      for i = 1:length(Stations)
        for ii = 1:nnz(users(:,i))
          Pairing(:,nlink) = [i; users(ii,i)]; %#ok
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
        StationC(iStation).Users(1,1) = User.UeId;

        % Reset any existing channel conditions
        %if strcmp(obj.Mode,'winner')
        %    obj.resetWinner;
        %end

        % Set mode for eHATA (increased computational speed)
        obj.Mode = 'eHATA';

        % Traverse channel
        [~, UserRx] = obj.traverse(StationC,User,'field','pathloss');
        RxPw(iStation) = UserRx.Rx.RxPwdBm;
      end
      [maxPw,maxStation] = max(RxPw);
      stationID = Stations(maxStation).NCellID;
    end

    function obj = resetChannel(obj)
      obj.WINNER = [];
      obj.eHATA = [];
    end

    function Users = applyInterference(obj,Stations,Users)
      % Method used to apply the interference on a specific received waveform
      sonohilog('Computing and applying interference based on station class...','NFO0')
      % Validate arguments
      validateChannel(obj);
      validateStations(Stations);
      validateUsers(Users);
      % TODO: Validate that users are scheduled. E.g. that Users(iUser).ENodeB is not empty. required when
      % finding the station associated with each user.
      % For each user find serving eNB
      for iUser = 1:length(Users)
        user = Users(iUser);
        station = Stations(find([Stations.NCellID] == Users(iUser).ENodeB));
        if isempty(station)
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
          user.Rx.RxPwdBm = intSigdBm;
        end
        
        

        Users(iUser) = user;
      end



    end

  end
end
