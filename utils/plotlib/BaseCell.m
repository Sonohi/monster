classdef BaseCell < matlab.mixin.Copyable
	
	%Properties
	properties
		Center;
		ISD;
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
					obj.ISD = Config.MacroEnb.ISD;
				case 'micro'
					obj.PosScenario = Config.MicroEnb.positioning;
					obj.ISD = Config.MicroEnb.ISD;
				case 'pico'
					obj.PosScenario = Config.PicoEnb.positioning;
					obj.ISD = Config.PicoEnb.ISD;
				otherwise
					monsterLog('Unknown cell type selected.','ERR')
			end
			
		end
		
	end
	
	
	
end