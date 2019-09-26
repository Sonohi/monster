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

		function obj = Site(Config, Logger, Layout, iSite, existingSites, cellsClass)
			% Get the site configuration 
			switch cellsClass
				case 'macro'
					SiteConfig = Layout.getMacroSiteConfig(Config, iSite);		
				case 'micro'
					SiteConfig = Layout.getMicroSiteConfig(Config, iSite, existingSites);
			end
			obj.Logger = Logger;
			obj.SiteId = SiteConfig.id;
			obj.Position = SiteConfig.position;
			obj.Class = SiteConfig.class;
			% Depending on the number of cells in this site, generate bearing values
			theta = 360/length(SiteConfig.cellsIds);
			possibleBearings = 0:theta:360;
			bearings = possibleBearings(1:length(SiteConfig.cellsIds));
			% Call constructor of cells/eNodeBs and assign the cell ids
			CellConfig = struct(...
				'class', SiteConfig.class,...
				'position', SiteConfig.position, ...
				'siteId', SiteConfig.id,...
				'macroCellId',SiteConfig.macroCellId);
			Cells(1:length(SiteConfig.cellsIds)) = arrayfun(@(x,y) EvolvedNodeB(...
				Config, Logger, CellConfig, x, y), SiteConfig.cellsIds, bearings);
			obj.Cells = Cells;
		end		
	end
end