function simulate(Param, DataIn, utilLo, utilHi)

%   SIMULATE is used to run a single simulation
%
%   Function fingerprint
%   Param			->  general simulation parameters
%		DataIn		-> 	input data as struct
%   utilLo		-> 	value of low utilisation for this simulation
%		utilHi		->	value for high utilisation for this simulation

TrafficGenerators = DataIn.TrafficGenerators;
Stations = DataIn.Stations;
Users = DataIn.Users;
Channel = DataIn.Channel;
ChannelEstimator = DataIn.ChannelEstimator;
SimulationMetrics = MetricRecorder(Param, utilLo, utilHi);

% Create structures to hold transmission data
if (Param.storeTxData)
	[tbMatrix, tbMatrixInfo] = initTbMatrix(Param);
	[cwdMatrix, cwdMatrixInfo] = initCwdMatrix(Param);
end
%[symMatrix, symMatrixInfo] = initSymMatrix(Param);

% create a string to mark the output of this simulation
outPrexif = strcat('seed_', num2str(Param.seed),'-utilLo_', num2str(utilLo),...
	'-utilHi_', num2str(utilHi), '-numUsers_', num2str(Param.numUsers));

if Param.generateHeatMap
	switch Param.heatMapType
		case 'perClass'
			HeatMap = generateHeatMapClass(Stations, Channel, Param);
		case 'perStation'
			HeatMap = generateHeatmap(Stations, Channel, Param);
		otherwise
			sonohilog('Unknown heatMapType selected in simulation parameters', 'ERR')
	end
else
	load('utils/heatmap/HeatMap_eHATA_fBS_pos_5m_res');
end

if Param.draw
	ENBsummaryplt = ENBsummaryPlot(Stations);
	UEsummaryplt = UESummaryPlot(Users);
	plotcoverage(Stations, Channel, Param)
	%drawHeatMap(HeatMap, Stations);
end

% Rounds are 0-based for the subframe indexing, so add 1 when needed
for iRound = 0:(Param.schRounds-1)
	% In each scheduling round, check UEs associated with each station and
	% allocate PRBs through the scheduling function per each station
	sonohilog(sprintf('Round %i/%i',iRound+1,Param.schRounds),'NFO');
	
	% -----------
	% UE MOVEMENT
	% -----------
	sonohilog('UE movement', 'NFO');
	for iUser = 1:length(Users)
		Users(iUser) = Users(iUser).move(iRound);
	end
	
	
	% refresh UE-eNodeB association
	simTime = iRound*10^-3;
	% TODO: Add this to the traverse or setup function of the channel
  Channel.iRound = iRound;
	if mod(simTime, Param.refreshAssociationTimer) == 0
		sonohilog('Refreshing user association', 'NFO');
		[Users, Stations] = refreshUsersAssociation(Users, Stations, Channel, Param, simTime);
	end
	
	% Update RLC transmission queues for the users and reset the scheduled flag
	Users = updateQueuesBulk(Users, TrafficGenerators, simTime);
	
	% ---------------------
	% ENODEB SCHEDULE START
	% ---------------------
	for iStation = 1:length(Stations)
		
		% check whether this eNodeB should schedule
		[schFlag, Stations(iStation)] = shouldSchedule(Stations(iStation), Users);
		if schFlag
			[Stations(iStation), Users] = schedule(Stations(iStation), Users, Param);
		end
		
		% Check utilisation
		sch = find([Stations(iStation).ScheduleDL.UeId] ~= -1);
		utilPercent = 100*find(sch, 1, 'last' )/length([Stations(iStation).ScheduleDL]);
		
		% check utilPercent and change to 0 if null
		if isempty(utilPercent)
			utilPercent = 0;
		end
		
		% Check utilisation metrics and change PowerState if needed
		Stations(iStation) = evaluatePowerState(Stations(iStation), utilPercent,...
			Param, utilLo, utilHi, Stations);
	end
	% -------------------
	% ENODEB SCHEDULE END
	% -------------------
  
  % ------------------------
  % Draw scheduled links
  % ------------------------
  if Param.draw
    plotlinks(Users, Stations, Param.LayoutAxes, 'downlink')
  end
  
	
	% ----------------------------------------------
	% ENODEB DL-SCH & PDSCH CREATION AND MAPPING
	% ----------------------------------------------
	sonohilog('eNodeB DL-SCH & PDSCH creation and mapping', 'NFO');
	[Stations, Users] = enbTxBulk(Stations, Users, Param, simTime);


	% ------------------
	% CHANNEL TRAVERSE
	% ------------------
	% Once all eNodeBs have created and stored their txWaveforms, we can go
	% through the UEs and compute the rxWaveforms
  % Setup the channel based on scheduled users
	sonohilog(sprintf('Traversing channel in DL (mode: %s)...',Param.channel.modeDL), 'NFO');
	[Stations, Users] = Channel.traverse(Stations, Users, 'downlink');
	
	% ------------
	% UE RECEPTION
	% ------------
	sonohilog('UE reception block', 'NFO');
	Users = ueRxBulk(Stations, Users, ChannelEstimator.Downlink);

	% ----------------
	% UE DATA DECODING
	% ----------------
	sonohilog('UE data decoding block', 'NFO');
	[Stations, Users] = ueDataDecoding(Stations, Users, Param, simTime);
	
	% --------------------------
	% UE UPLINK
	% ---------------------------
	sonohilog('Uplink transmission', 'NFO');
	[Stations, compoundWaveforms, Users] = ueTxBulk(Stations, Users, iRound, mod(iRound,10), Param);

	% ------------------
	% CHANNEL TRAVERSE
	% ------------------
	sonohilog(sprintf('Traversing channel in UL (mode: %s)...',Param.channel.modeUL), 'NFO');
	Channel = Channel.setupChannelUL(Stations,Users,'compoundWaveform',compoundWaveforms);
	[Stations, Users] = Channel.traverse(Stations, Users,'uplink');

	% --------------------------
	% ENODEB RECEPTION
	% ---------------------------
	sonohilog('eNodeB reception block', 'NFO');
	Stations = enbRxBulk(Stations, Users, simTime, ChannelEstimator.Uplink);

	% ----------------
	% ENODEB DATA DECODING
	% ----------------
	sonohilog('eNodeB data decoding block', 'NFO');
	[Stations, Users] = enbDataDecoding(Stations, Users, Param, simTime);

	% --------------------------
	% ENODEB SPACE METRICS RECORDING
	% ---------------------------
	sonohilog('eNodeB-space metrics recording', 'NFO');
	SimulationMetrics = SimulationMetrics.recordEnbMetrics(Stations, iRound, Param, utilLo);
	
	% --------------------------
	% UE SPACE METRICS RECORDING
	% ---------------------------
	sonohilog('UE-space metrics recording', 'NFO');
	SimulationMetrics = SimulationMetrics.recordUeMetrics(Users, iRound);


	% Plot resource grids for all users
	if Param.draw
		plotConstDiagramDL(Stations,Users, Param);
		plotSpectrums(Users,Stations, Param);
    UEsummaryplt.UEBulkPlot(Users, SimulationMetrics, iRound);
    ENBsummaryplt.ENBBulkPlot(Stations, SimulationMetrics, iRound);
		for iUser = 1:length(Users)
			Users(iUser).plotUEinScenario(Param);
		end
    drawnow
	end
	
	
	% --------------------
	% RESET FOR NEXT ROUND
	% --------------------
	sonohilog('Resetting objects for next simulation round', 'NFO');
	for iUser = 1:length(Users)
		Users(iUser) = Users(iUser).reset();
	end
	for iStation = 1:length(Stations)
		Stations(iStation) = Stations(iStation).reset(iRound + 1);
	end
	
end % end round

% Once this simulation set is done, save the output
% Remove figures from the config structure
% TODO: upper API will contain these figure handles, thus they will not
% need to be removed from Param.
try
Param = rmfield(Param,{'LayoutFigure', 'PHYFigure', 'LayoutAxes','PHYAxes'});
catch
end
SimulationMetrics.Param = Param;
save(strcat('results/', outPrexif, '.mat'), 'SimulationMetrics');
end
