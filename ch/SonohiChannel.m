classdef SonohiChannel
% 

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
      usersS = cellfun(@(x) unique([x.NCellID]), schedules, 'UniformOutput', false);
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

    function obj = resetChannel(obj)
    % Resets any channel setup
      obj.WINNER = [];
      obj.eHATA = [];
    end
    
    function obj = setupChannelDL(obj,Stations,Users)
    % Setup channel given the DL schedule, e.g. the association to simulate when traversed.
      [stations, users] = obj.getScheduledDL(Stations, Users);
      obj = obj.setupChannel(stations,users);

    end

end

methods(Access=private)

    function obj = setupChannel(obj,Stations,Users)
    % Setup association to traverse

      if strcmp(obj.Mode,'winner')
        obj.WINNER = sonohiWINNER(Stations,Users, obj);
        obj.WINNER = obj.WINNER.setup();
      elseif strcmp(obj.Mode,'eHATA')
        obj.eHATA = sonohieHATA(obj);
      end
      
    end
    
end


end