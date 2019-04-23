function [LayoutFigure, LayoutAxes] = createLayoutPlot(Config)
	fig = figure('Name','Layout','Position',[100, 100, 1000, 1000]);
	layout_axes = axes('parent', fig);
	%Find simulation area
	buildings = Config.Terrain.buildings;
	area = [min(buildings(:, 1)), min(buildings(:, 2)), max(buildings(:, 3)), ...
		max(buildings(:, 4))];
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
	if (strcmp(Config.MicroEnb.positioning,'hexagonal')  && (Config.MacroEnb.ISD*3/2 > maxRadius && Config.MicroEnb.number > 6 ))
		maxRadius = Config.MacroEnb.ISD*3/2;
	end
	%Check pico
	if (strcmp(Config.PicoEnb.positioning,'uniform') && Config.PicoEnb.ISD > maxRadius)
		maxRadius = Config.PicoEnb.ISD;
	end
	%Set axes accordingly
	set(layout_axes,'XLim',[xc-maxRadius-10,xc+maxRadius+10],'YLim',[yc-maxRadius-10,yc+maxRadius+10]); %+/-10 for better looks
	set(layout_axes,'XTick',[]);
	set(layout_axes,'XTickLabel',[]);
	set(layout_axes,'YTick',[]);
	set(layout_axes,'YTickLabel',[]);
	set(layout_axes,'Box','on');
	hold(layout_axes,'on');
	LayoutFigure = fig;
	LayoutAxes = findall(fig,'type','axes');
end