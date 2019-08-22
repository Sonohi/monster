classdef ENBsummaryPlot < matlab.mixin.Copyable
	properties
		title = 'eNB statistics';
		position = [100, 100, 1000, 1000];
		metrics = {'PowerState', 'PowerConsumed', 'HARQ', 'Utilization'};
		metricsUnit = {'State', 'Watt', 'No. HARQ', '%'};
		metricsColor;
		fig;
		tabgp;
		axes;
	end
	
	properties(Access=private)
		numCols = 4; % Default number of columns for the subplots
		numRows;
	end
	
	methods
		function obj = ENBsummaryPlot(Cells)
			obj.setColors();
			obj.createFigureHandle();
			obj.createTabGroup();
			obj.getNumberOfRows();
			obj.createTabForEachCell(Cells);
			obj.axes = findall(obj.fig,'type','axes');
		end
		
		function obj = setColors(obj)
			obj.metricsColor = rand(length(obj.metrics),3);
		end
		
		function obj = createFigureHandle(obj)
			obj.fig = figure('Name',obj.title,'Position',obj.position);
		end
		
		function obj = createTabGroup(obj)
			obj.tabgp = uitabgroup(obj.fig,'Position',[.05 .05 .9 .9]);
		end
		
		function obj = createTabForEachCell(obj, Cells)
			%% Setup tab for each enb
			for iCell = 1:length(Cells)
				Cell = Cells(iCell);
				cellId = Cell.NCellID;
				cellSummary = uitab(obj.tabgp,'Title',sprintf('Cell %i', cellId));
				cellSummaryAxes = axes('parent', cellSummary);
				hold(cellSummaryAxes,'on')
				
				for metricIdx = 1:length(obj.metrics)
					metric = obj.metrics{metricIdx};
					metricColor = obj.metricsColor(metricIdx,:);
					h = subplot(obj.numRows,obj.numCols,metricIdx,'Tag',sprintf('Cell%i%s',cellId, metric));
					animatedline(h,'Color',metricColor)
					title(h,metric)
					xlabel(h,'Seconds')
					ylabel(h,obj.metricsUnit{metricIdx})
				end
			end
		end
		
		function obj = getNumberOfRows(obj)
			obj.numRows = ceil(length(obj.metrics)/obj.numCols);
		end
		
		
		function obj = addData(obj,cellId,metric,x,y)
			h = obj.findSubplotHandle(cellId, metric);
			addpoints(h,x,y)
		end
		
		function obj = ENBBulkPlot(obj, Cells, SimulationMetrics, iRound)
			simTime = iRound * 0.001;
			iRound = iRound + 1;
			for iCell = 1:length(Cells)
				Cell = Cells(iCell);
				obj.addData(Cell.NCellID, 'PowerState', simTime, SimulationMetrics.powerState(iRound,iCell));
				obj.addData(Cell.NCellID, 'PowerConsumed', simTime, SimulationMetrics.powerConsumed(iRound,iCell));
				obj.addData(Cell.NCellID, 'HARQ', simTime, SimulationMetrics.harqRtx(iRound,iCell));
				obj.addData(Cell.NCellID, 'Utilization', simTime, SimulationMetrics.util(iRound,iCell));
			end
		end
	end
	
	methods(Access=private)
		
		function h = findSubplotHandle(obj, cellId,metric)
			Tag = sprintf('Cell%i%s',cellId, metric);
			axEq = findall(obj.axes,'Tag',Tag);
			h = get(axEq,'Children');
		end
	end
end

