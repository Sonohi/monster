%Class defining all relevant coordinates for a macro cell 
classdef MacroCell < BaseCell
	
	%Properties
	properties
		MicroCoordinates;
	end
	
	methods
		function obj = MacroCell(Config, Logger, siteId, cellCentre, cellId, microPosPerMacroCell)
			% Constructor
			obj = obj@BaseCell(Config, Logger, siteId, cellCentre, cellId, 'macro');
			% Calculate possible positions of micro sites
			obj.computeMicroPos(microPosPerMacroCell);
		end
		
	end
	
	methods (Access = private)
		% Compute all the available positions for micro sites within the macro cell 
		% As per 38.901, there are at most 3 micro sites positions per macro cell
		function obj = computeMicroPos(obj, microPosPerMacroCell)
			microPos = zeros(microPosPerMacroCell, 2);
			% Divide the circumference around the centre of the macro cell
			theta = 2*pi/microPosPerMacroCell;
			% Now calculate the position of the micro sites within the macro cell
			% The micro sites are placed in a circle around the centre of the macro cell
			% The radius of such circle is half the radius of the macro cell
			for iMicro = 1:microPosPerMacroCell
				microPos(iMicro, 1) = obj.Center(1) + obj.Radius/2 * cos((iMicro-1) * theta);
				microPos(iMicro, 2) = obj.Center(2) + obj.Radius/2 * sin((iMicro-1) * theta);
			end
			obj.MicroCoordinates = microPos;
		end
		
	end
	
end
