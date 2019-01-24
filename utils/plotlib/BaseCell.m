classdef BaseCell < matlab.mixin.Copyable
	
	%Properties
	properties
		Center;
		Radius;
		CellID;
		CellType;
		PosScenario;
	end
	
	methods
		function obj =BaseCell(xc, yc, Config, cellId, cellType)
			%Constructor
			
			%Set arguments
			obj.Center  = [xc yc];
			obj.CellID = cellId;
			obj.CellType = cellType;
			%Set positioning scenario accordingly, currently not implemented fully.
			switch cellType
				case 'macro'
					obj.PosScenario = 'hexagonal';
					obj.Radius = Config.MacroEnb.radius;
				case 'micro'
					obj.PosScenario = Config.MicroEnb.positioning;
					obj.Radius = Config.MicroEnb.Radius;
				case 'pico'
					obj.PosScenario = Config.PicoEnb.positioning;
					obj.Radius = Config.PicoEnb.radius;
				otherwise
					monsterLog('Unknown cell type selected.','ERR')
			end
			
		end
		
	end
	
	
	
end