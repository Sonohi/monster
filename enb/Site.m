classdef Site < matlab.mixin.Copyable
	% SITE defines a value class for a network site as a set of 1 or more cells
	properties
		SiteId; % Used to generate the SSS of the eNodeBs 
		Position;
		Class;
		Cells;
		Logger;
	end

	methods
		% Constructor
		function obj = Site(Config, Logger, sitePosition, siteId, cellsClass, macroCellId, cellsIds)
			obj.SiteId = siteId;
			obj.Logger = Logger;
			obj.Position = sitePosition;
			obj.Class = cellsClass;
			% Depending on the number of cells in this site, generate bearing values
			theta = 360/length(cellsIds);
			possibleBearings = 0:theta:360;
			bearings = possibleBearings(1:length(cellsIds));
			% Call constructor of cells/eNodeBs and assign the cell ids
			Cells(1:length(cellsIds)) = arrayfun(@(x, y) EvolvedNodeB(Config, Logger, ...
				cellsClass, sitePosition, x, y, siteId, macroCellId), cellsIds, bearings);
			obj.Cells = Cells;
		end
	end
end