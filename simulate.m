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
enbResults(1:Param.schRounds, 1:Param.numMacro + Param.numMicro) = struct(...
	'power', 0,...
	'util', 0,...
	'schedule', []);

ueResults(1:Param.schRounds, 1:Param.numUsers) = struct(...
	'blocks', [],...
	'cqi', NaN,...
	'preEvm', NaN,...
	'postEvm', NaN,....
	'bits', [],...
	'sinr', NaN,...
	'snr',NaN,...
	'rxPosition', [],...
	'txPosition', [], ...
	'symbols', [], ...
	'scheduled',NaN,...
	'servingStation',NaN);

infoResults = struct('utilLo', utilLo, 'utilHi', utilHi);

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

% if Param.draw
% 	drawHeatMap(HeatMap, Stations);
% end

% Rounds are 0-based for the subframe indexing, so add 1 when needed
for iRound = 0:(Param.schRounds-1)
	% In each scheduling round, check UEs associated with each station and
	% allocate PRBs through the scheduling function per each station
	sonohilog(sprintf('Round %i/%i',iRound+1,Param.schRounds),'NFO');
	
	
	% refresh UE-eNodeB association
	simTime = iRound*10^-3;
	if mod(simTime, Param.refreshAssociationTimer) == 0
		sonohilog('Refreshing user association', 'NFO');
		[Users, Stations] = refreshUsersAssociation(Users, Stations, Channel, Param);
	end
	
	
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
			Stations(iStation).Tx = setBCH(Stations(iStation).Tx,Stations(iStation));
		end

		% Reset the grid and put in the grid RS, PSS and SSS
		Stations(iStation).Tx = resetResourceGrid(Stations(iStation).Tx, Stations(iStation));
		
		% schedule only if at least 1 user is associated
		if Stations(iStation).Users(1) ~= 0
			[Stations(iStation), Users] = schedule(Stations(iStation), Users, Param);
		end
		
		% Check utilisation
		sch = [Stations(iStation).ScheduleDL.UeId];
		utilPercent = 100*find(sch, 1, 'last' )/length(sch);
		
		% check utilPercent and change to 0 if null
		if isempty(utilPercent)
			utilPercent = 0;
		end
		
		% calculate the power that will be used in this round by this eNodeB
		pIn = getPowerIn(Stations(iStation), utilPercent/100);
		
		% store eNodeB-space results
		resultsStore(iStation).util = utilPercent;
		resultsStore(iStation).power = pIn;
		resultsStore(iStation).schedule = Stations(iStation).ScheduleDL;
		
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
		% get the eNodeB this UE is connected to
		iServingStation = [Stations.NCellID] == Users(iUser).NCellID;
		
		% Check if this UE is scheduled otherwise skip
		if checkUserSchedule(Users(iUser), Stations(iServingStation))
			% generate transport block for the user
			[Stations(iServingStation), Users(iUser)] = ... 
				createTransportBlock(Stations(iServingStation), Users(iUser), Param, simTime);
			
			% generate codeword (RV defaulted to 0)
			Users(iUser) = createCodeword(Users(iUser), Param);
			
			% finally, generate the arrays of complex symbols by setting the
			% correspondent values per each eNodeB-UE pair
			% setup current subframe for serving eNodeB
			if Users(iUser).CodewordInfo.cwdSize ~= 0
				[sym, SymInfo] = createSymbols(Stations(iServingStation), Users(iUser),...
					Users(iUser).Codeword, Users(iUser).CodewordInfo, Param);
			end
			
			if SymInfo.symSize > 0
				symMatrix(iServingStation, iUser, :) = sym;
				symMatrixInfo(iServingStation, iUser) = SymInfo;
				% Store the pre-OFDM modulated symbols in the UE structure to calculate SER
				Users(iUser).Symbols = sym;
				Users(iUser).SymbolsInfo = SymInfo;
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
	sonohilog('eNodeB grid mapping and modulation', 'NFO');
	Stations = enbTxBulk(Stations, symMatrix, Param);
	
	% ----------------------------------
	% CHANNEL SYNCHRONIZATION
	% ------------------------------------
	% Setup the channel based on scheduled users
	Channel = Channel.setupChannel(Stations,Users);
	sonohilog('Running sync routine', 'NFO');
	[Users, Channel] = syncRoutine(Stations, Users, Channel, Param);
	
	% ------------------
	% CHANNEL TRAVERSE
	% ------------------
	% Once all eNodeBs have created and stored their txWaveforms, we can go
	% through the UEs and compute the rxWaveforms
	sonohilog(sprintf('Traversing channel in DL (mode: %s)...',Param.channel.mode), 'NFO');
	[Stations, Users] = Channel.traverse(Stations,Users,'downlink');
	
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
	[Stations, compoundWaveforms, Users] = ueTxBulk(Stations, Users, iRound, mod(iRound,10));

	% ------------------
	% CHANNEL TRAVERSE
	% ------------------
	% TODO for testing, UL channel traverse is disabled and we just set the txWaveform to the eNodeB
	%sonohilog(sprintf('Traversing channel in UL (mode: %s)...',Param.channel.mode), 'NFO');
	%[Stations, Users] = Channel.traverse(Stations, Users,'uplink');
	
	% TODO remove B2B testing
	for iStation = 1:length(Stations)
		iCfw = find([compoundWaveforms.eNodeBId] == Stations(iStation).NCellID);
		Stations(iStation).Rx.Waveform = compoundWaveforms(iCfw).txWaveform;
	end
	
	% --------------------------
	% ENODEB RECEPTION
	% ---------------------------
	sonohilog('Uplink data decoding', 'NFO');
	Stations = enbRxBulk(Stations, Users, simTime, ChannelEstimator.Uplink);

	% ----------------
	% ENODEB DATA DECODING
	% ----------------
	sonohilog('ENODEB data decoding block', 'NFO');
	[Stations, Users] = enbDataDecoding(Stations, Users, Param, simTime);

	% --------------------------
	% ENODEB SPACE METRICS RECORDING
	% ---------------------------
	sonohilog('eNodeB-space metrics recording', 'NFO');
	[enbResults, resultsStore] = recordEnBResults(Stations, resultsStore, enbResults, iRound);
	
	% --------------------------
	% UE SPACE METRICS RECORDING
	% ---------------------------
	sonohilog('UE-space metrics recording', 'NFO');
	ueResults = recordUEResults(Users, Stations, ueResults, iRound);

	% -----------
	% UE MOVEMENT
	% -----------
	sonohilog('UE movement', 'NFO');
	for iUser = 1:length(Users)
		Users(iUser) = move(Users(iUser), simTime, Param);
	end
	
	% Plot resource grids for all users
	if Param.draw
		[hScatter(1), hScatter(2)] = plotConstDiagram_rx(Stations,Users);
		[hGrids(1), hGrids(2)] = plotReGrids(Users);
		[hSpectrums(1)] = plotSpectrums(Users,Stations);
	end
	
	
	% --------------------
	% RESET FOR NEXT ROUND
	% --------------------
	sonohilog('Resetting objects for next simulation round', 'NFO');
	for iUser = 1:length(Users)
		Users(iUser) = Users(iUser).resetUser();
	end
	Channel = Channel.resetChannel();
	
end % end round

% Once this simulation set is done, save the output
save(strcat('results/', outPrexif, '.mat'), 'enbResults', 'ueResults', 'infoResults');
end
