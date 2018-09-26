classdef sonohiB2B < sonohiBase

    properties
        CompoundWaveform
    end

    methods

        function obj = sonohiB2B(Channel, Chtype)
            obj = obj@sonohiBase(Channel, Chtype)
            %sonohilog('Running B2B','WRN')

        end
    
    end
    

    methods 

        % Overwrite of downlink logic
        function [users] = downlink(obj,Stations,Users)
            % Update the Rx module of users
            users = Users;
            for iUser = 1:length(users)
                iServingStation = find([Stations.NCellID] == Users(iUser).ENodeBID);
                users(iUser).Rx.Waveform = Stations(iServingStation).Tx.Waveform;
                users(iUser).Rx.RxPwdBm = Stations(iServingStation).Pmax;
            end
        end

        % Overwrite of uplink logic
        function [stations] = uplink(obj,Stations,Users)
            % Update the Rx module of stations

            stations = Stations;
            
            
            for iStation = 1:length(Stations)
                iCfw = find([obj.CompoundWaveform.eNodeBId] == Stations(iStation).NCellID);
                stations(iStation).Rx.Waveform = obj.CompoundWaveform(iCfw).txWaveform;
                stations(iStation).Rx.RxPwdBm = obj.CompoundWaveform(iCfw).Pmax;
            end

        end

    end

end
