function Param = createLayoutPlot(Param)
fig = figure('Name','Layout','Position',[400, 400, 1000, 1000]);
layout_axes = axes('parent', fig);
set(layout_axes,'XLim',[0, 600],'YLim',[0, 600]);
set(layout_axes,'XTick',[]);
set(layout_axes,'XTickLabel',[]);
set(layout_axes,'YTick',[]);
set(layout_axes,'YTickLabel',[]);
set(layout_axes,'Box','on');
hold(layout_axes,'on');
Param.LayoutFigure = fig;
Param.LayoutAxes = findall(fig,'type','axes');
end