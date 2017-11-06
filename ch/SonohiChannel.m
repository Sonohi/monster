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

    function [stations, users]  = getScheduled(Stations,Users)
      % Find stations that have scheduled users.
      % TODO: refactorize to uplink
      schedules = {Stations.ScheduleDL};
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

end