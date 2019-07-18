% Class definition for coordinates for a micro site with a variable number of cells
classdef MicroCell < BaseCell
	% Properties
	properties
		
	end

	methods 
		function obj = MicroCell(cellCentre, cellId, Config, Logger)
			obj = obj@BaseCell(cellCentre, cellId, 'micro', Config, Logger);
		end
	end
end 