function [macroPos, microPos] = positionBaseStations (maBS, miBS, buildings,draw)

%   POSITION BASE STATIONS is used to set up the physical location of BSs
%
%   Function fingerprint
%   maBS      ->  number of macro base stations
%   miBS      ->  number of micro base stations
%   buildings ->  building position matrix
%
%   macroPos ->  positions of the macro base stations
%   microPos ->  positions of the micro base stations

	%Create position vectors
	macroPos = zeros(maBS, 2);
	microPos = zeros(miBS, 2);

	%Find simulation area
	area = [min(buildings(:, 1)), min(buildings(:, 2)), max(buildings(:, 3)), ...
		max(buildings(:, 4))];

  % Draw grid
  if draw
      figure
      rectangle('Position',area)
      hold on
      for i = 1:length(buildings(:,1))
          x0 = buildings(i,1);
          y0 = buildings(i,2);
          x = buildings(i,3)-x0;
          y = buildings(i,4)-y0;
          rectangle('Position',[x0 y0 x y],'FaceColor',[0.9 .9 .9])
      end
  end

	% Macro BS positioned at centre with single BS
	% TODO extend at multiple macro
	if (maBS == 1)
		xc = (area(3) - area(1))/2;
		yc = (area(4) - area(2))/2;
		macroPos(maBS, :) = [xc yc];
		if draw
			 rectangle('Position',[xc yc 5 5],'Curvature',[1 1],'EdgeColor','r','FaceColor','r')
		end
	end

	%Micro BS positioning
	for (i = 1 : miBS)
	  valid = false;
	  while (~valid)
	    x = rand * (area(3) + area(1)) - area(1);
	    y = rand * (area(4) + area(2)) - area(2);
	    for (b = 1 : length(buildings(:, 1)))
	      if (x > buildings(b, 1) && x < buildings(b, 3) && y > buildings(b, 2) && y < buildings(b, 4))
	        valid = true;
	      end
	    end
	    for (m = 1 : maBS)
	      d = sqrt((macroPos(m, 1) - x) ^ 2 + (macroPos(m, 2) - y) ^ 2);
	      if (d < 20)
	        valid = false;
	      end
	    end

	    for (m = 1 : i - 1)
	      d = sqrt((microPos(m, 1) - x) ^ 2 + (microPos(m, 2) - y) ^ 2);
	      if (d < 20)
	        valid = false;
	      end
	    end
	  end
	  microPos(i, :) = [x y];
      if draw
         rectangle('Position',[x y 5 5],'Curvature',[1 1],'EdgeColor',[0 .5 .5],'FaceColor',[0 .5 .5])
      end
	end

end
