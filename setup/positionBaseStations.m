function [macro_pos, micro_pos] = positionBaseStations (maBS, miBS, buildings)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   POSITION BASE STATIONS is used to set up the physical location of BSs      %
%                                                                              %
%   Function fingerprint                                                       %
%   maBS      ->  number of macro base stations                                %
%   miBS      ->  number of micro base stations                                %
%   buildings ->  building position matrix                                     %
%                                                                              %
%   macro_pos ->  positions of the macro base stations                         %
%   micro_pos ->  positions of the micro base stations                         %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%Create position vectors
macro_pos = zeros(maBS, 2);
micro_pos = zeros(miBS, 2);

%Find simulation area
area = [min(buildings(1, :)), min(buildings(2, :)), max(buildings(3, :)), max(buildings(4, :))];

%TODO Macro BS positioning

%Micro BS positioning
for (i = 1 : miBS),
    valid = false;
    while (~valid),
        x = rand * (area(3) + area(1)) - area(1);
        y = rand * (area(4) + area(2)) - area(2);
        for (b = 1 : length(buildings(:, 1))),
            if (x > buildings(b, 1) && x < buildings(b, 3) && y > buildings(b, 2) && y < buildings(b, 4))
                valid = true;
            end
        end
        for (m = 1 : maBS),
            d = sqrt((macro_pos(m, 1) - x) ^ 2 + (macro_pos(m, 2) - y) ^ 2);
            if (d < 20)
                valid = false;
            end
        end
        
        for (m = 1 : i - 1),
            d = sqrt((micro_pos(m, 1) - x) ^ 2 + (micro_pos(m, 2) - y) ^ 2);
            if (d < 20)
                valid = false;
            end
        end
    end
    micro_pos(i, :) = [x y];
end

end
