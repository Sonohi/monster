% Class definition for coordinates for a micro site with a variable number of cells
classdef MicroCell < BaseCell
	% Properties
	properties
		
	end

	methods 
		function obj = MicroCell(Config, Logger, siteId, cellCentre, cellId)
			obj = obj@BaseCell(Config, Logger, siteId, cellCentre, cellId, 'micro');
		end
	end
end 