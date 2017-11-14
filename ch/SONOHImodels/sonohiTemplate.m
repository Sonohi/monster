classdef sonohiTemplate

    properties
        Channel;
        Chtype; %Downlink or Uplink
    end

    methods

        function obj = sonohiTemplate(Stations, Users, Channel, Chtype)
            sonohilog('Initializing channel model...','NFO0')
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
        end

        function [stations] = uplink(obj,Stations,Users)
            % Update the Rx module of stations
        end
        
        function [rxSig, SNRLin, rxPwdBm] = addPathlossAwgn(obj, TxNode, RxNode, txSig, lossdB)

        end

        function rx = addFading(tx)

        end

    end

end
