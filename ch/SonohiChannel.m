classdef SonohiChannel
    %
    
    properties
        Area;
        ULMode;
        DLMode;
        Buildings;
        Draw;
        Region;
        DownlinkModel;
        UplinkModel;
        fieldType;
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
        
        function [stations, users]  = getScheduled(Stations,Users,schedule)
            % Find stations that have scheduled users.
            
            schedules = {schedule};
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
            users = Users(ismember([Users.NCellID],usersC));
            
        end
        
        function [stations, users] = getScheduledDL(Stations,Users)
            
            [stations, users] = SonohiChannel.getScheduled(Stations,Users,Stations.ScheduleDL);
            
        end
        
        function [stations, users] = getScheduledUL(Stations,Users)
            
            [stations, users] = SonohiChannel.getScheduled(Stations,Users,Stations.ScheduleUL);
            
        end
        
    end
    
    methods
        
        function obj = resetChannelModels(obj)
            % Resets any channel setup
            obj.DownlinkModel = [];
            obj.UplinkModel = [];
        end
        
        function obj = setupChannelDL(obj,Stations,Users)
            % Setup channel given the DL schedule, e.g. the association to simulate when traversed.
            [stations, users] = obj.getScheduledDL(Stations, Users);
            obj.DownlinkModel = obj.setupChannel(stations,users,'downlink');
        end
        
        function obj = setupChannelUL(obj, Stations, Users)
            % Setup channel given the DL schedule, e.g. the association to simulate when traversed.
            [stations, users] = obj.getScheduledUL(Stations, Users);
            obj.UplinkModel = obj.setupChannel(stations,users,'uplink');
        end
        
    end
    
    methods(Access=private)
        
        function chModel = setupChannel(obj,Stations,Users,chtype)
            % Setup association to traverse
            switch chtype
                case 'downlink'
                    mode = obj.DLMode;
                case 'uplink'
                    mode = obj.ULMode;
            end
            
            if strcmp(mode,'winner')
                WINNER = sonohiWINNER(Stations,Users, obj,chtype);
                chModel = WINNER.setup();
            elseif strcmp(mode,'eHATA')
                chModel = sonohieHATA(obj);
            elseif strcmp(mode, 'B2B')
                chModel = sonohiB2B(obj, chtype);
            end
            
            
            
        end
        
    end
    
    
end