classdef sonohiB2B

    properties
        Channel;
        Chtype; %Downlink or Uplink
    end

    methods

        function obj = sonohiB2B(Channel, Chtype)
            sonohilog('Running B2B','WRN')
            obj.Channel = Channel;
            obj.Chtype = Chtype;

        end

        function obj = setup(obj)

        end
        

        function [stations,users] = run(obj,Stations,Users, varargin)

        switch obj.Chtype
            case 'downlink'
                users = obj.downlink(Stations,Users);
                stations = Stations;
            case 'uplink'
                stations = obj.uplink(Stations,Users);
                users = Users;
        end

        end

    
    end
    

    methods (Access=private) 

        function [users] = downlink(obj,Stations,Users)
            % Update the Rx module of users
            users = Users;
            for iUser = 1:length(users)
                iServingStation = find([Stations.NCellID] == Users(iUser).ENodeBID);
                users(iUser).Rx.Waveform = Stations(iServingStation).Tx.Waveform;
                users(iUser).Rx.RxPwdBm = Stations(iServingStation).Pmax;
            end
        end

        function [stations] = uplink(obj,Stations,Users)
            % Update the Rx module of stations

            stations = Stations;
            for iStation = 1:length(stations)
                iServingUser = find([Users.ENodeBID] == Stations(iStation).NCellID);
                stations(iStation).Rx.Waveform = Users(iServingUser).Tx.Waveform;
                stations(iStation).Rx.RxPwdBm = Users(iServingUser).Pmax;
            end
        end
        
        function [rxSig, SNRLin, rxPwdBm] = addPathlossAwgn(obj, TxNode, RxNode, txSig, lossdB)

        end

        function rx = addFading(tx)

        end

    end

end
