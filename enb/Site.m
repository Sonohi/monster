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
		function obj = Site(Config, Logger, siteId, cellsClass, cellNumber)
			obj.SiteId = siteId;
			obj.Logger = Logger;
			% Call constructor of cells/eNodeBs and assign the cell id based on the siteId
			cellsIds = 3*siteId + [1:cellNumber];
			Cells(1:cellNumber) = arrayfun(@(x) EvolvedNodeB(Config, cellsClass, x, Logger), cellsIds);

		end

	end
end