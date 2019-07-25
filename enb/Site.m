classdef Site < matlab.mixin.Copyable
	% SITE defines a value class for a network site as a set of 1 or more cells
	properties
		SiteId; % Used to generate the SSS of the eNodeBs 
		Position;
		Cells;
		Logger;
	end

	methods
		% Constructor
		function obj = Site(Config, Logger, sitePosition, siteId, cellsClass, cellsIds)
			obj.SiteId = siteId;
			obj.Logger = Logger;
			obj.Position = sitePosition;
			% Call constructor of cells/eNodeBs and assign the cell ids
			Cells(1:length(cellsIds)) = arrayfun(@(x) EvolvedNodeB(Config, Logger, cellsClass, sitePosition, x, siteId, -1), cellsIds);
			obj.Cells = Cells;
		end
	end
end