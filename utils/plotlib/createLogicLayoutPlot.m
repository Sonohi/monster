function [LogicLayoutFigure, LogicLayoutAxes] = createLogicLayoutPlot(Config)
  LogicLayoutFigure = figure('Name','Logic Layout','Position',[100, 100, 1000, 1000]);
	LogicLayoutAxes  = findall(LogicLayoutFigure,'type','axes');
end