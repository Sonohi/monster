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
		'info', struct('utilLo', utilLo, 'utilHi', utilHi));

	for iRound = 1:Param.schRounds
		% In each scheduling round, check UEs associated with each station and
		% allocate PRBs through the scheduling function per each station

		% check which UEs are associated to which eNB
		[Users, Stations] = refreshUsersAssociation(Users, Stations, Param);
		simTime = iRound*10^-3;

		% Update RLC transmission queues for the users and reset the scheduled flag
		for iUser = 1:length(Users)
			queue = updateTrQueue(trSource, simTime, Users(iUser));
			Users(iUser) = setQueue(Users(iUser), queue);
			Users(iUser) = setScheduled(Users(iUser), false);
		end;

		for iStation = 1:length(Stations)
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
			
			% store eNodeB-space results
			Results.util(iStation, iRound) = utilPercent;

			% Check utilisation metrics and change status if needed
			Stations(iStation) = checkUtilisation(Stations(iStation), utilPercent,...
				Param, utilLo, utilHi, Stations);
		end

		% per each user, create the codeword
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
					Stations(iServingStation).NSubframe = iRound;
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
		end % end user loop

		% the last step in the DL transmisison chain is to map the symbols to the
		% resource grid and modulate the grid to get the TX waveform
		for iStation = 1:length(Stations)
			% generate empty grid or clean the previous one
			Stations(iStation) = resetResourceGrid(Stations(iStation));
			% now for each list of user symbols, reshape them into the grid
			for iUser = 1:Param.numUsers
				sz = symMatrixInfo(iStation, iUser).symSize;
				ixs = symMatrixInfo(iStation, iUser).indexes;
				if (sz ~= 0)
					% TODO revise padding/truncating (why symbols are not int multiples of 14?)
					tempSym(1:sz,1) = symMatrix(iStation, iUser, 1:sz);
					mapSym = mapSymbols(tempSym, length(ixs) * 14);
					Stations(iStation).ReGrid(ixs, :) = reshape(mapSym, [length(ixs), 14]);
				end
			end

			% with the grid ready, generate the TX waveform
			% Currently the waveform is given per station, i.e. same
			% for all associated users.
			Stations(iStation) = modulateTxWaveform(Stations(iStation));
		end

    if Param.draw
      constellationDiagram(Stations(1,1).TxWaveform, ...
		  	Stations(1,1).WaveformInfo.SamplingRate/Stations(1,1).WaveformInfo.Nfft);
    end

		% Once all eNodeBs have created and stored their txWaveforms, we can go
		% through the UEs and compute the rxWaveforms

		for iUser = 1:length(Users)
			% find serving eNodeB
			iServingStation = find([Stations.NCellID] == Users(iUser).ENodeB);

			% TODO remove B2B testing
			Users(iUser).RxWaveform = Stations(iServingStation).TxWaveform;

			% Now, demodulate the overall received waveform for users that should
			% receive a TB
			if checkUserSchedule(Users(iUser), Stations(iServingStation))
				Users(iUser) = demodulateRxWaveform(Users(iUser), Stations(iServingStation));

				% Estimate channel for the received subframe
				Users(iUser) = estimateChannel(Users(iUser), Stations(iServingStation),...
					ChannelEstimator);

				% finally, get the value of the sinr for this subframe and the corresponing
				% CQI that should be used for the next round

				Users(iUser) = selectCqi(Users(iUser), Stations(iServingStation));

				% store UE-space results
				Results.sinr(iUser, iRound) = Users(iUser).Sinr;
				Results.cqi(iUser, iRound) = Users(iUser).WCqi;
			end

		end
	end % end round

	% Once this simulation set is done, save the output
  save(strcat('results/', outPrexif, '.mat'), 'Results');
end
