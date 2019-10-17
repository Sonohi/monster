function [LayoutFigure, LayoutAxes] = createLayoutPlot(Config, Layout)
	fig = figure('Name','Layout','Position',[100, 100, 1000, 1000]);
	layoutAxes = axes('parent', fig);
	%Find simulation area
	area = Layout.Terrain.area;
	xc = (area(3) - area(1))/2;
	yc = (area(4) - area(2))/2;
	maxRadius = max(area(3)/2,area(4)/2);
	%Depending on position scenario and radius resize axes to that or resize to building grid
	%Check macro
	if Config.MacroEnb.ISD > maxRadius
		maxRadius = Config.MacroEnb.ISD;
	end
	%Check micro
	if (strcmp(Config.MicroEnb.positioning,'uniform')  && Config.MicroEnb.ISD > maxRadius)
		maxRadius = Config.MicroEnb.ISD;
	end
	%If hexagonal
	if (strcmp(Config.MicroEnb.positioning,'hexagonal')  && (Config.MacroEnb.ISD*3/2 > maxRadius && Config.MicroEnb.sitesNumber > 6 ))
		maxRadius = Config.MacroEnb.ISD*3/2;
	end
	%Set axes accordingly
	set(layoutAxes,'XLim',[xc-maxRadius-10,xc+maxRadius+10],'YLim',[yc-maxRadius-10,yc+maxRadius+10]); %+/-10 for better looks
	set(layoutAxes,'XTick',[]);
	set(layoutAxes,'XTickLabel',[]);
	set(layoutAxes,'YTick',[]);
	set(layoutAxes,'YTickLabel',[]);
	set(layoutAxes,'Box','on');
	hold(layoutAxes,'on');
	LayoutFigure = fig;
	LayoutAxes = findall(fig,'type','axes');
end