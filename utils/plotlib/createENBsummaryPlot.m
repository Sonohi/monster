function Param = createENBsummaryPlot(Param, Stations)
% This function creates the main figure used for PHY visualization
% Tags are used to identify the plots.
fig = figure('Name','eNB statistics','Position',[100, 100, 1000, 1000]);
tabgp = uitabgroup(fig,'Position',[.05 .05 .9 .9]);

%% Setup tab for each enb
for stationIdx = 1:length(Stations)
	station = Stations(stationIdx);
	stationId = station.NCellID;
	stationSummary = uitab(tabgp,'Title',sprintf('Station %i', stationId));
	stationSummaryAxes = axes('parent', stationSummary);
	hold(stationSummaryAxes,'on')
	subplot(4,3,1,'Tag',sprintf('station%iPowerState',stationId))
	animatedline('Color','b')
	title('Power State')
	subplot(4,3,2,'Tag',sprintf('station%iSchedule',stationId))
	animatedline('Color','b')
	title('Schedule')
	subplot(4,3,3,'Tag',sprintf('station%iDLThroughput',stationId))
	animatedline('Color','b')
	title('DL throughput')
	subplot(4,3,4,'Tag',sprintf('station%iPowerConsumed',stationId))
	animatedline('Color','b')
	title('Power consumed')
%numRows = ceil(Param.numUsers/4);
%for user = 1:Param.numUsers
%    subplot(4,numRows,user,'Tag',sprintf('user%iRxConstDL',user));
%end
end
Param.eNBFigure = fig;
Param.eNBAxes = findall(fig,'type','axes');
end