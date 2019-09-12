classdef BaseCell < matlab.mixin.Copyable
	
	%Properties
	properties
		Center;
		SiteID;
		CellID;
		CellType;
		PosScenario;
		Radius;
		Area;
		Logger;
	end
	
	methods
		function obj = BaseCell(Config, Logger, siteId, cellCentre, cellId, cellType)
			%Constructor
			
			%Set arguments
			obj.Logger = Logger;
			obj.SiteID = siteId;
			obj.Center = cellCentre;
			obj.CellID = cellId;
			obj.CellType = cellType;
			%Set positioning scenario accordingly, currently not implemented fully.
			switch cellType
				case 'macro'
					obj.PosScenario = 'hexagonal';
					obj.Radius = Config.MacroEnb.ISD/Config.MacroEnb.cellsPerSite;
				case 'micro'
					obj.PosScenario = Config.MicroEnb.positioning;
					obj.Radius = Config.MicroEnb.ISD/Config.MicroEnb.cellsPerSite;
				otherwise
					obj.Logger.log('Unknown cell type selected.','ERR')
				obj.Area = 2*sqrt(3)*(obj.Radius)^2;
			end
		end
	end
end