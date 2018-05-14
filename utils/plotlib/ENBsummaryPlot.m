classdef ENBsummaryPlot < handle
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
		function obj = ENBsummaryPlot(Stations)
			obj.setColors();
			obj.createFigureHandle();
			obj.createTabGroup();
			obj.getNumberOfRows();
			obj.createTabForEachStation(Stations);
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
		
		function obj = createTabForEachStation(obj, Stations)
			%% Setup tab for each enb
			for stationIdx = 1:length(Stations)
				station = Stations(stationIdx);
				stationId = station.NCellID;
				stationSummary = uitab(obj.tabgp,'Title',sprintf('Station %i', stationId));
				stationSummaryAxes = axes('parent', stationSummary);
				hold(stationSummaryAxes,'on')
				
				for metricIdx = 1:length(obj.metrics)
					metric = obj.metrics{metricIdx};
					metricColor = obj.metricsColor(metricIdx,:);
					h = subplot(obj.numRows,obj.numCols,metricIdx,'Tag',sprintf('station%i%s',stationId, metric));
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
		
		
		function obj = addData(obj,stationId,metric,x,y)
			h = obj.findSubplotHandle(stationId, metric);
			addpoints(h,x,y)
		end
		
		function obj = ENBBulkPlot(obj, Stations, SimulationMetrics, iRound)
			simTime = iRound * 0.001;
			iRound = iRound + 1;
			for stationIdx = 1:length(Stations)
				station = Stations(stationIdx);
				obj.addData(station.NCellID, 'PowerState', simTime, SimulationMetrics.powerState(iRound,stationIdx));
				obj.addData(station.NCellID, 'PowerConsumed', simTime, SimulationMetrics.powerConsumed(iRound,stationIdx));
				obj.addData(station.NCellID, 'HARQ', simTime, SimulationMetrics.harqRtx(iRound,stationIdx));
				obj.addData(station.NCellID, 'Utilization', simTime, SimulationMetrics.util(iRound,stationIdx));
			end
		end
	end
	
	methods(Access=private)
		
		function h = findSubplotHandle(obj, stationId,metric)
			Tag = sprintf('station%i%s',stationId, metric);
			axEq = findall(obj.axes,'Tag',Tag);
			h = get(axEq,'Children');
		end
	end
end

