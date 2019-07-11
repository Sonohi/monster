classdef BaseCell < matlab.mixin.Copyable
	
	%Properties
	properties
		Center;
		ISD;
		CellID;
		CellType;
		PosScenario;
		Logger;
	end
	
	methods
		function obj =BaseCell(xc, yc, Config, cellId, cellType, Logger)
			%Constructor
			
			%Set arguments
			obj.Logger = Logger;
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
					obj.Logger.log('Unknown cell type selected.','ERR')
			end
			
		end
		
	end
	
	
	
end