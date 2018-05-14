classdef UESummaryPlot < handle
    properties
        title = 'UE statistics';
        position = [100, 100, 1000, 1000];
        metrics = {'BER', 'CQI', 'preEVM', 'postEVM', 'SNR', 'SINR', 'RSRP', 'ReceivedPower', 'Throughput'};
        metricsUnit = {'BER', 'CQI', '%', '%', 'dB', 'dB', 'dBm', 'ReceivedPower', 'Bit'};
        metricsPlotType = {'animatedline','animatedline', 'animatedline', 'animatedline'};
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
        function obj = UESummaryPlot(Stations)
            obj.setColors();
            obj.createFigureHandle();
            obj.createTabGroup();
            obj.getNumberOfRows();
            obj.createTabForEachUE(Stations);
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
        
        function obj = createTabForEachUE(obj, Users)
            %% Setup tab for each user
            for userIdx = 1:length(Users)
                user = Users(userIdx);  
                userID = user.NCellID;
                stationSummary = uitab(obj.tabgp,'Title',sprintf('User %i', userID));
                stationSummaryAxes = axes('parent', stationSummary);
                hold(stationSummaryAxes,'on')
                
                for metricIdx = 1:length(obj.metrics)
                    metric = obj.metrics{metricIdx};
                    metricColor = obj.metricsColor(metricIdx,:);
                    h = subplot(obj.numRows,obj.numCols,metricIdx,'Tag',sprintf('user%i%s',userID, metric));
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
        
        function obj = UEBulkPlot(obj, Users, SimulationMetrics, iRound)
            simTime = 0.001*iRound;
            iRound = iRound + 1; % Starts a zero, but also considered the first index.
             for userIdx = 1:length(Users)
               user = Users(userIdx);
               obj.addData(user.NCellID, 'BER', simTime, SimulationMetrics.ber(iRound, userIdx));
               obj.addData(user.NCellID, 'preEVM', simTime, SimulationMetrics.preEvm(iRound, userIdx));
               obj.addData(user.NCellID, 'postEVM', simTime, SimulationMetrics.postEvm(iRound, userIdx));
               obj.addData(user.NCellID, 'CQI', simTime, SimulationMetrics.cqi(iRound, userIdx));
               obj.addData(user.NCellID, 'SNR', simTime, SimulationMetrics.snrdB(iRound, userIdx));
               obj.addData(user.NCellID, 'SINR', simTime, SimulationMetrics.sinrdB(iRound, userIdx));
               obj.addData(user.NCellID, 'ReceivedPower', simTime, SimulationMetrics.receivedPowerdBm(iRound, userIdx));
               obj.addData(user.NCellID, 'RSRP', simTime, SimulationMetrics.rsrpdBm(iRound, userIdx));
               obj.addData(user.NCellID, 'Throughput', simTime, SimulationMetrics.throughput(iRound, userIdx));
            end 
            
        end
    end
    
    methods(Access=private)
        
        function h = findSubplotHandle(obj, userId,metric)
            Tag = sprintf('user%i%s',userId, metric);
            axEq = findall(obj.axes,'Tag',Tag);
            h = get(axEq,'Children');
        end
    end
end

