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


	for (iRound = 1:Param.schRounds)
		% In each scheduling round, check UEs associated with each station and
		% allocate PRBs through the scheduling function per each station

		% check which UEs are associated to which eNB
		[Users, Stations] = refreshUsersAssociation(Users, Stations, Param);
		simTime = iRound*10^-3;

		% Update RLC transmission queues for the users and reset the scheduled flag
		for (iUser = 1:length(Users))
			queue = updateTrQueue(trSource, simTime, Users(iUser));
			Users(iUser) = setQueue(Users(iUser), queue);
			Users(iUser) = setScheduled(Users(iUser), false);
		end;

		for (iStation = 1:length(Stations))
			% schedule only if at least 1 user is associated
			if (Stations(iStation).Users(1) ~= 0)
				Stations(iStation) = schedule(Stations(iStation), Users, Param);
			end
		end;

		% per each user, create the codeword
		for (iUser = 1:length(Users))
			% get the eNodeB thie UE is connected to
			iServingStation = find([Stations.NCellID] == Users(iUser).ENodeB);

			% Check if this UE is scheduled otherwise skip
			if (checkUserSchedule(Users(iUser), Stations(iServingStation)))
				% generate transport block for the user
				[tb, TbInfo] = createTransportBlock(Stations(iServingStation), Users(iUser), ...
					Param);

				% generate codeword (RV defaulted to 0)
				[cwd, CwdInfo] = createCodeword(tb, TbInfo, Param);

				% finally, generate the arrays of complex symbols by setting the
				% correspondent values per each eNodeB-UE pair
				% setup current subframe for serving eNodeB
				if (CwdInfo.cwdSize ~= 0) % is this even necessary?
					Stations(iServingStation).NSubframe = iRound;
					[sym, SymInfo] = createSymbols(Stations(iServingStation), Users(iUser), cwd, ...
						CwdInfo, Param);
				end

				if (SymInfo.symSize > 0)
					symMatrix(iServingStation, iUser, :) = sym;
					symMatrixInfo(iServingStation, iUser) = SymInfo;
				end

				% Save to data structures
				if (Param.storeTxData)
					tbMatrix(iServingStation, iUser, :) = tb;
					tbMatrixInfo(iServingStation, iUser) = TbInfo;
					cwdMatrix(iServingStation, iUser, :) = cwd;
					cwdMatrixInfo(iServingStation, iUser) = CwdInfo;
				end

			end
		end % end user loop

		% the last step in the DL transmisison chain is to map the symbols to the
		% resource grid and modulate the grid to get the TX waveform
		for (iStation = 1:length(Stations))
			% generate empty grid or clean the previous one
			Stations(iStation) = resetResourceGrid(Stations(iStation));
			% now for each list of user symbols, reshape them into the grid
			for (iUser = 1:Param.numUsers)
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

		% Once all eNodeBs have created and stored their txWaveforms, we can go
		% through the UEs and compute the rxWaveforms

		% Model propagation channel
		Channel.traverse(Stations,Users,iRound)

		for (iUser = 1:length(Users))
			% find serving eNodeB
			iServingStation = find([Stations.NCellID] == Users(iUser).ENodeB);
			Stations(iServingStation).Channel.InitTime = iRound/1000;
			%Users(iUser).RxWaveform = ...
			%	Stations(iServingStation).Channel.propagate(Stations(iServingStation),Users(iUser));

			%TODO
			%Compute power from eNB and calculate transmission SNR

			%Normalize power for AWGN impairment
			%N0 = 1/(sqrt(2.0*Stations(iStation).CellRefP*double(Stations(iStation).Waveforminfo.Nfft))*SNR);

			% Add AWGN in time domain
			%noise = No*complex(randn(length(Users(iUser).rxWaveform)),...
			%randn(length(Users(iUser).rxWaveform)));

			% calculate the overall received waveform for this user by doing a summation
			% of the interfering ones
			for (iStation = 1:length(Stations))
				if (iStation ~= iServingStation)
					k = getScalingFactor(Stations(iStation), Users(iUser));
					Users(iUser).rxWaveform = Users(iUser).rxWaveform + ...
						k*Stations(iStation).Channel.propagate(Stations(iServingStation),Users(iUser));
				end
			end

			% Now, demodulate the overall received waveform for users that should
			% receive a TB
			if (checkUserSchedule(Users(iUser), Stations(iServingStation)))
				rxSubFrame = lteOFDMDemodulate(Stations(iServingStation), ...
					Users(iUser).rxWaveform);

				% Estimate channel for the received subframe
				[estChannelGrid, noiseEst] = lteDLChannelEstimate(Stations(iServingStation),...
					ChannelEstimator, rxSubframe);

				% finally, get the value of the sinr for this subframe and the corresponing
				% CQI that should be used for the next round

				% TODO revise if PDSCH settings should be edited to meet the scheduling
				% details of this user
				[cqi, sinr] = lteCQISelect(Stations(iServingStation), ...
					Stations(iServingStation).PDSCH, estChannelGrid, noiseEst);

				Users(iUser).wCqi = cqi;

				% TODO Record stats and power consumed in this round
			end
		end
	end % end
end
