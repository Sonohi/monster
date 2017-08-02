function simulate(Param, DataIn, utilLo, utilHi)

%   SIMULATE is used to run a single simulation
%
%   Function fingerprint
%   Param			->  general simulation parameters
%		DataIn		-> 	input data as struct
%   utilLo		-> 	value of low utilisation for this simulation
%		utilHi		->	value for high utilisation for this simulation

trSource = DataIn.trSource;
Stations = DataIn.Stations;
Users = DataIn.Users;
Channel = DataIn.Channel;
ChannelEstimator = DataIn.ChannelEstimator;

% Create structures to hold transmission data
if (Param.storeTxData)
	[tbMatrix, tbMatrixInfo] = initTbMatrix(Param);
	[cwdMatrix, cwdMatrixInfo] = initCwdMatrix(Param);
end
[symMatrix, symMatrixInfo] = initSymMatrix(Param);

% create a string to mark the output of this simulation
outPrexif = strcat('utilLo_', num2str(utilLo), '-utilHi_', num2str(utilHi));

% Prepare results data structures
enbResults(1:Param.numMacro + Param.numMicro, 1:Param.schRounds ) = struct(...
	'power', 0,...
	'util', 0);

ueResults(1:Param.numUsers, 1:Param.schRounds ) = struct(...
	'bler', 0,...
	'evm', 0,...
	'throughput', 0,...
	'sinr', 0,...
	'snr',0);

infoResults = struct('utilLo', utilLo, 'utilHi', utilHi);

% Routine for establishing offset based on whole frame.
FrameNo = 1;
[Users, Transmitters,Channel] = syncRoutine(FrameNo, Stations, Users, Channel, Param);
%
if Param.generateHeatMap
	switch Param.heatMapType
		case 'perClass'
			HeatMap = generateHeatMapClass(Transmitters, Channel, Param);
		case 'perStation'
			HeatMap = generateHeatmap(Transmitters, Channel, Param);
		otherwise
			sonohilog('Unknown heatMapType selected in simulation parameters', 'ERR')
	end
else
	load('utils/heatmap/HeatMap_eHATA_fBS_pos_5m_res');
end

if Param.draw
	drawHeatMap(HeatMap, Stations);
end

for iRound = 0:Param.schRounds
  % TODO: Add log print that states which round is being simulated.
	% In each scheduling round, check UEs associated with each station and
	% allocate PRBs through the scheduling function per each station

	% check which UEs are associated to which eNB
	[Users, Stations] = refreshUsersAssociation(Users, Stations, Channel, Param);
	simTime = iRound*10^-3;

	% Update RLC transmission queues for the users and reset the scheduled flag
	for iUser = 1:length(Users)
		queue = updateTrQueue(trSource, simTime, Users(iUser));
		Users(iUser) = setQueue(Users(iUser), queue);
		Users(iUser) = setScheduled(Users(iUser), false);
	end

	% ---------------------
	% ENODEB SCHEDULE START
	% ---------------------
	for iStation = 1:length(Stations)
		% First off, set the number of the current subframe withing the frame
		% this is the scheduling round modulo 10 (the frame is 10ms)
		Stations(iStation).NSubframe = mod(iRound,10);

		% every 40 ms the cell has to broadcast its identity with the BCH
		% check if we need to regenerate that (except for iRound == 0 as it's regenerated
		% when the object is created)
		if (iRound ~= 0 && mod(iRound, 40) == 0)
			Stations(iStation) = setBCH(Stations(iStation));
		end
		% Reset teh grid and put in the grid RS, PSS and SSS
		Stations(iStation) = resetResourceGrid(Stations(iStation));

		% schedule only if at least 1 user is associated
		if Stations(iStation).Users(1) ~= 0
			Stations(iStation) = schedule(Stations(iStation), Users, Param);
		end

		% Check utilisation
		sch = [Stations(iStation).Schedule.UeId];
		utilPercent = 100*find(sch, 1, 'last' )/length(sch);

		% check utilPercent and cahnge to 0 if null
		if isempty(utilPercent)
			utilPercent = 0;
		end

		% calculate the power that will be used in this round by this eNodeB
		pIn = getPowerIn(Stations(iStation), utilPercent/100);

		% store eNodeB-space results
		enbResults(iStation, iRound + 1).util = utilPercent;
		enbResults(iStation, iRound + 1).power = pIn;

		% Check utilisation metrics and change status if needed
		Stations(iStation) = checkUtilisation(Stations(iStation), utilPercent,...
			Param, utilLo, utilHi, Stations);
	end
	% -------------------
	% ENODEB SCHEDULE END
	% -------------------

	% ----------------------------------------------
	% ENODEB CREATE DL-SCH TB TO PDSCH SYMBOLS START
	% ----------------------------------------------
	for iUser = 1:length(Users)
		% get the eNodeB thie UE is connected to
		iServingStation = find([Stations.NCellID] == Users(iUser).ENodeB);

		% Check if this UE is scheduled otherwise skip
		if checkUserSchedule(Users(iUser), Stations(iServingStation))
			% generate transport block for the user
			[Users(iUser).TransportBlock, Users(iUser).TransportBlockInfo] =...
				createTransportBlock(Stations(iServingStation), Users(iUser), Param);

			% generate codeword (RV defaulted to 0)
			[Users(iUser).Codeword, Users(iUser).CodewordInfo] = createCodeword(...
				Users(iUser).TransportBlock,Users(iUser).TransportBlockInfo, Param);

			% finally, generate the arrays of complex symbols by setting the
			% correspondent values per each eNodeB-UE pair
			% setup current subframe for serving eNodeB
			if Users(iUser).CodewordInfo.cwdSize ~= 0 % is this even necessary?
				[sym, SymInfo] = createSymbols(Stations(iServingStation), Users(iUser),...
					Users(iUser).Codeword, Users(iUser).CodewordInfo, Param);
			end

			if SymInfo.symSize > 0
				symMatrix(iServingStation, iUser, :) = sym;
				symMatrixInfo(iServingStation, iUser) = SymInfo;
			end

			% Save to data structures
			if Param.storeTxData
				tbMatrix(iServingStation, iUser, :) = Users(iUser).TransportBlock;
				tbMatrixInfo(iServingStation, iUser) = Users(iUser).TransportBlockInfo;
				cwdMatrix(iServingStation, iUser, :) = Users(iUser).Codeword;
				cwdMatrixInfo(iServingStation, iUser) = Users(iUser).CodewordInfo;
			end

		end
	end
	% --------------------------------------------
	% ENODEB CREATE DL-SCH TB TO PDSCH SYMBOLS END
	% --------------------------------------------

	% ----------------------------------
	% ENODEB GRID MAPPING AND MODULATION
	% ----------------------------------
	sonohilog('eNodeB grid mapping and modulation block', 'NFO');
	for iStation = 1:length(Stations)
		Stations(iStation) = mapGridAndModulate(Stations(iStation), iStation, ...
			symMatrix, Param);
	end

	if Param.draw
		% Plot OFDM spectrum of first station
		spectrumAnalyser(Stations(1).TxWaveform, Stations(1).WaveformInfo.SamplingRate);

		% Plot conestellation diagram of first station
		enb = cast2Struct(Stations(1));
		% get PDSCH indexes
		[indPdsch, info] = Stations(1).getPDSCHindicies;
		grid = lteOFDMDemodulate(enb,enb.TxWaveform);
		% Get data symbols and visualize
		gridR = grid(indPdsch);
		constellationDiagram(gridR,1);

		% combine subframe grids to a frame grid for dbg
		if iRound <= 10
			Stations(1).Frame = [Stations(1).Frame Stations(1).ReGrid];
		end

	end

	% Once all eNodeBs have created and stored their txWaveforms, we can go
	% through the UEs and compute the rxWaveforms
  sonohilog(sprintf('Traversing channel (mode: %s)...',Param.channel.mode),'NFO')
	[Stations, Users] = Channel.traverse(Stations,Users);

	% ------------------
	% CHANNEL TRAVERSE
	% ------------------
	% Once all eNodeBs have created and stored their txWaveforms, we can go
	% through the UEs and compute the rxWaveforms
	sonohilog(sprintf('Traversing channel (mode: %s)...',Param.channel.mode), 'NFO');
	[Stations, Users] = Channel.traverse(Stations,Users);

	% ------------
	% UE RECEPTION
	% ------------
	sonohilog('UE reception block', 'NFO');
	Users = RxBulk(Stations, Users, ChannelEstimator);

	% --------------------------
	% UE SPACE METRICS RECORDING
	% ---------------------------
	sonohilog('UE-space metrics recording', 'NFO');

	% -----------
	% UE MOVEMENT
	% -----------
	for iUser = 1:length(Users)
		Users(iUser) = move(Users(iUser), simTime, Param);
	end

	% Plot resource grids for all users
	if Param.draw
		[hScatter(1), hScatter(2)] = plotConstDiagram_rx(Stations,Users);
		[hGrids(1), hGrids(2)] = plotReGrids(Users);
	end


	% TODO:
	% Decide how to reconfigure channel model. e.g. each scheduling
	% round?
	% Should the model configuration be identical (only update of
	% layout) or configured upon new?
	Channel.h = [];
	[Users, Transmitters,Channel] = syncRoutine(FrameNo, Stations, Users, Channel, Param);

end % end round

% Once this simulation set is done, save the output
save(strcat('results/', outPrexif, '.mat'), 'enbResults', 'ueResults', 'infoResults');
end
