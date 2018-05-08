function Param = createPHYplot(Param)
% This function creates the main figure used for PHY visualization
% Tags are used to identify the plots.
fig = figure('Name','PHY','Position',[100, 100, 1000, 1000]);
tabgp = uitabgroup(fig,'Position',[.05 .05 .9 .9]);

%% Setup rx. const tab
rxConstDL = uitab(tabgp,'Title','Rx. Constellation (DL)');
rxConstDLAxes = axes('parent', rxConstDL);
hold(rxConstDLAxes,'on')
numRows = ceil(Param.numUsers/4);
for user = 1:Param.numUsers
    subplot(4,numRows,user,'Tag',sprintf('user%iRxConstDL',user));
end

%% Setup eq. const. tab
eqConstDL = uitab(tabgp,'Title','Eq. Constellation (DL)');
eqConstDLAxes = axes('parent', eqConstDL);
hold(eqConstDLAxes,'on')
for user = 1:Param.numUsers
    subplot(4,numRows,user,'Tag',sprintf('user%iEqConstDL',user));
end

%% Setup spectrum tab
spectrumConstDL = uitab(tabgp,'Title','Rx. Spectrum (DL)');
spectrumConstDLAxes = axes('parent', spectrumConstDL);
hold(spectrumConstDLAxes,'on')
for user = 1:Param.numUsers
    h = subplot(4,numRows,user,'Tag',sprintf('user%iSpectrumDL',user));
end
%set(phy_axes,'XLim',[0, 600],'YLim',[0, 600]);
%set(phy_axes,'XTick',[]);
%set(phy_axes,'XTickLabel',[]);
%set(phy_axes,'YTick',[]);
%set(phy_axes,'YTickLabel',[]);
%set(phy_axes,'Box','on');
%hold(phy_axes,'on');
Param.PHYFigure = fig;
Param.PHYAxes = findall(fig,'type','axes');
end