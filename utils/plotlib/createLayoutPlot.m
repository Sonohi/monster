function Param = createLayoutPlot(Param)
fig = figure('Name','Layout','Position',[100, 100, 1000, 1000]);
layout_axes = axes('parent', fig);
%Find simulation area
buildings = Param.buildings;
area = [min(buildings(:, 1)), min(buildings(:, 2)), max(buildings(:, 3)), ...
	max(buildings(:, 4))];
xc = (area(3) - area(1))/2;
yc = (area(4) - area(2))/2;
%If uniform is not chosen or the radius is less than building grid, resize to building grid
if (strcmp(Param.microPos,'uniform') && (2*Param.microUniformRadius >= area(3) || 2*Param.microUniformRadius >= area(4))) ... 
    || (strcmp(Param.picoPos,'uniform') && (2*Param.picoUniformRadius >= area(3) || 2*Param.picoUniformRadius >= area(4)))
    %Find largest radius and make the figure that size
    if strcmp(Param.microPos,'uniform') && strcmp(Param.picoPos,'uniform')
        maxRadius =max([Param.microUniformRadius,Param.picoUniformRadius]);
    elseif strcmp(Param.microPos,'uniform')
        maxRadius =Param.microUniformRadius;
    else 
        maxRadius =Param.picoUniformRadius;
    end
    set(layout_axes,'XLim',[xc-maxRadius-10,xc+maxRadius+10],'YLim',[yc-maxRadius-10,yc+maxRadius+10]); %+/-10 for better looks
else
    set(layout_axes,'XLim',[-10,area(3)+10],'YLim',[-10,area(4)+10]); %+/-10 for better looks
end
set(layout_axes,'XTick',[]);
set(layout_axes,'XTickLabel',[]);
set(layout_axes,'YTick',[]);
set(layout_axes,'YTickLabel',[]);
set(layout_axes,'Box','on');
hold(layout_axes,'on');
Param.LayoutFigure = fig;
Param.LayoutAxes = findall(fig,'type','axes');
end