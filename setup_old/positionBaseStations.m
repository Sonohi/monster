function [macroPos, microPos, picoPos] = positionBaseStations (maBS, miBS, piBS, Param)

%   POSITION BASE STATIONS is used to set up the physical location of BSs
%

%Find simulation area
buildings = Param.buildings;
area = [min(buildings(:, 1)), min(buildings(:, 2)), max(buildings(:, 3)), ...
	max(buildings(:, 4))];
xc = (area(3) - area(1))/2;
yc = (area(4) - area(2))/2;
%Generate network layout
networkLayout = NetworkLayout(xc,yc,Param); 

%Macro BST positioning
macroPos = networkLayout.MacroCoordinates; 

%Micro BST positioning
microPos = networkLayout.Cells{1}.MicroPos;

%Pico BST positioning
picoPos = networkLayout.Cells{1}.PicoPos;

%Draw the base stations
networkLayout.draweNBs(Param);	
	
end
