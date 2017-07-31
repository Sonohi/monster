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

Results = struct(...
	'sinr', zeros(Param.numUsers,Param.schRounds),...
	'cqi', 	zeros(Param.numUsers,Param.schRounds), ...
	'util', zeros(Param.numMacro + Param.numMicro, Param.schRounds),...
	'power', zeros(Param.numMacro + Param.numMicro, Param.schRounds),...
	'info', struct('utilLo', utilLo, 'utilHi', utilHi));

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
	load('utils/heatmap/Heatmap');
end

if Param.draw
	drawHeatMap(HeatMap, Stations);
end

for iRound = 0:Param.schRounds
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
		Results.util(iStation, iRound + 1) = utilPercent;
		Results.power(iStation, iRound + 1) = pIn;

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
			[tb, TbInfo] = createTransportBlock(Stations(iServingStation), Users(iUser), ...
				Param);

			% generate codeword (RV defaulted to 0)
			[cwd, CwdInfo] = createCodeword(tb, TbInfo, Param);

			% finally, generate the arrays of complex symbols by setting the
			% correspondent values per each eNodeB-UE pair
			% setup current subframe for serving eNodeB
			if CwdInfo.cwdSize ~= 0 % is this even necessary?
				[sym, SymInfo] = createSymbols(Stations(iServingStation), Users(iUser), cwd, ...
					CwdInfo, Param);
			end

			if SymInfo.symSize > 0
				symMatrix(iServingStation, iUser, :) = sym;
				symMatrixInfo(iServingStation, iUser) = SymInfo;
			end

			% Save to data structures
			if Param.storeTxData
				tbMatrix(iServingStation, iUser, :) = tb;
				tbMatrixInfo(iServingStation, iUser) = TbInfo;
				cwdMatrix(iServingStation, iUser, :) = cwd;
				cwdMatrixInfo(iServingStation, iUser) = CwdInfo;
			end

		end
	end
	% --------------------------------------------
	% ENODEB CREATE DL-SCH TB TO PDSCH SYMBOLS END
	% --------------------------------------------

	% -------------------------
	% ENODEB GRID MAPPING START
	% -------------------------
	for iStation = 1:length(Stations)
		% the last step in the DL transmisison chain is to map the symbols to the
		% resource grid and modulate the grid to get the TX waveform

		% extract all the symbols this eNodeB has to transmit
		syms = extractStationSyms(Stations(iStation), iStation, symMatrix, Param);

		% insert the symbols of the PDSCH into the grid
		Stations(iStation) = setPDSCHGrid(Stations(iStation), syms);

		% with the grid ready, generate the TX waveform
		Stations(iStation) = modulateTxWaveform(Stations(iStation));
	end
	% -----------------------
	% ENODEB GRID MAPPING END
	% -----------------------

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
	[Stations, Users] = Channel.traverse(Stations,Users);

	% ------------------
	% UE RECEPTION START
	% ------------------
	for iUser = 1:length(Users)
		% find serving eNodeB
		iServingStation = find([Stations.NCellID] == Users(iUser).ENodeB);
		loopTitle = sprintf('Station %i -> User %i',iServingStation,Users(iUser).UeId);
		sonohilog(loopTitle, 'NFO')

		% Compute offset on single RB, check against offset computed for whole frame.
		if iRound == 0 || iRound == 5
			[offset, offsetAuto] = calcFrameOffset(Stations(iServingStation), Users(iUser));
			if offset ~= Users(iUser).Offset
				offsetS = sprintf('Timing offset compute for single RB differ by: %s',num2str(Users(iUser).Offset-offset));
				sonohilog(offsetS, 'NFO0')
			end
		end


		% compute the interference from non-serving stations
		Users(iUser).RxWaveform = Channel.applyInterference(Stations, ...
			Stations(iServingStation), Users(iUser));

		% Now, demodulate the overall received waveform for users that should
		% receive a TB
		if checkUserSchedule(Users(iUser), Stations(iServingStation))
			Users(iUser).RxWaveform = Users(iUser).RxWaveform(1+Users(iUser).Offset(FrameNo):end,:);

			Users(iUser) = demodulateRxWaveform(Users(iUser), Stations(iServingStation));

			% Check if we're able to demodulate
			if isequal(size(Users(iUser).RxSubFrame),size(Stations(iServingStation).ReGrid))


				% Estimate channel for the received subframe
				Users(iUser) = estimateChannel(Users(iUser), Stations(iServingStation),...
					ChannelEstimator);

				% Calculate error
				%rxError = Stations(iServingStation).ReGrid - Users(iUser).RxSubFrame;

				% Perform equalization to account for phase noise (needs
				% SNR)
				if ~strcmp(Param.channel.mode,'B2B')
					Users(iUser) = Users(iUser).equalize;
					eqError = Stations(iServingStation).ReGrid - Users(iUser).EqSubFrame;
				end

				EVM = comm.EVM;
				EVM.AveragingDimensions = [1 2];
				preEqualisedEVM = EVM(Stations(iServingStation).ReGrid,Users(iUser).RxSubFrame);
				s = sprintf('Percentage RMS EVM of Pre-Equalized signal: %0.3f%%\n', ...
					preEqualisedEVM);
				sonohilog(s,'NFO0')

				EVM = comm.EVM;
				EVM.AveragingDimensions = [1 2];
				postEqualisedEVM = EVM(Stations(iServingStation).ReGrid,Users(iUser).EqSubFrame);
				s = sprintf('Percentage RMS EVM of Post-Equalized signal: %0.3f%%\n', ...
					postEqualisedEVM);
				sonohilog(s,'NFO')


				% finally, get the value of the sinr for this subframe and the corresponing
				% CQI that should be used for the next round
				Users(iUser) = selectCqi(Users(iUser), Stations(iServingStation));
			else
				% Set a conservative CQI
				s = sprintf('Not able to demodulate Station(%i) to User(%i)',iServingStation,iUser, ...
					'\nSetting a conservative CQI value of 4');
				sonohilog(s,'WRN');
				Users(iUser).WCqi = 4;
				Users(iUser).Sinr = NaN;

			end
			% store UE-space results
			Results.sinr(iUser, iRound + 1) = Users(iUser).Sinr;
			Results.cqi(iUser, iRound + 1) = Users(iUser).WCqi;
		end
	end
	% -----------------
	% UE RECEPTION END
	% -----------------

	% TODO consider moving this User loop into the one above
	% -----------------
	% UE MOVEMENT START
	% -----------------
	for iUser = 1:length(Users)
		Users(iUser) = move(Users(iUser), simTime, Param);
	end
	% ---------------
	% UE MOVEMENT END
	% ---------------


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
save(strcat('results/', outPrexif, '.mat'), 'Results');
end
