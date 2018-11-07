function Param = createLayoutPlot(Param)
fig = figure('Name','Layout','Position',[100, 100, 1000, 1000]);
layout_axes = axes('parent', fig);
%Find simulation area
buildings = Param.buildings;
area = [min(buildings(:, 1)), min(buildings(:, 2)), max(buildings(:, 3)), ...
	max(buildings(:, 4))];
xc = (area(3) - area(1))/2;
yc = (area(4) - area(2))/2;
maxRadius = max(area(3)/2,area(4)/2);
%Depending on position scenario and radius resize axes to match, otherwise resize to building grid

%Check macro
if Param.macroRadius*Param.numMacro >maxRadius
    maxRadius = Param.macroRadius*Param.numMacro;
end

%Set axes accordingly
set(layout_axes,'XLim',[xc-maxRadius-10,xc+maxRadius+10],'YLim',[yc-maxRadius-10,yc+maxRadius+10]); %+/-10 for better looks
set(layout_axes,'XTick',[]);
set(layout_axes,'XTickLabel',[]);
set(layout_axes,'YTick',[]);
set(layout_axes,'YTickLabel',[]);
set(layout_axes,'Box','on');
hold(layout_axes,'on');
Param.LayoutFigure = fig;
Param.LayoutAxes = findall(fig,'type','axes');
end