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


        function combinedLoss = getInterference(obj,Stations,station,user)

            % Get power of each station that is not the serving station and
            % compute loss based on pathloss or in the case of winner on
            % both.
            % Computation needs to be done per spectral component, thus
            % interference needs to be computed as a transferfunction
            % This means the non-normalized spectrums needs to be added
            % after pathloss is added.

            % v1 Uses eHATA based pathloss computation for both cases

            eHATA = sonohieHATA(obj);
            for iStation = 1:length(Stations)

                if Stations(iStation).NCellID ~= station.NCellID
                    % Get rx of all other stations
                    %txSig = obj.addFading([...
                        Stations(iStation).TxWaveform;zeros(25,1)],Stations(iStation).WaveformInfo);
                    %[rxSigNorm,~,rxPw(iStation)] = obj.addPathlossAwgn(Stations(iStation),user,txSig);


                    Users = eHATA.run(Stations(iStation),user);

                    RxPw(iStation) = UserRx.RxInfo.rxPw;
                    rxSignorm = Users.RxWaveform;


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

                eHATA = sonohieHATA(obj);
                Users = eHATA.run(Stations,Users);

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
