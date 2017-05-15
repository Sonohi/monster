%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   MAIN 																										          					%
%																																							 	%
%   Simulation Parameters                                                       %                    %
%		reset 						-> 	resets the paths and refreshes them										%
%		schRounds 				->	overall length of the simulation											%
%		numSubFramesMacro ->	bandwidth of macro cell																%
%													(100 subframes = 20 MHz bandwidth)										%
%		numSubFramesMicro ->	bandwidth of micro cell																%
%		numMacro 					->	number of macro cells																	%
%		numMicro					-> 	number of micro cells																	%
%		seed							-> 	seed for channel																			%
%		buildings					->	file path for coordinates of Manhattan grid						%
%		velocity					->	velocity of Users																			%
%		numUsers					-> 	number of Users																				%
%		utilLoThr					->	lower threshold of utilisation												%
%		utilHiThr					->	upper threshold of utilisation												%
%		Channel.mode			->	channel model to be used															%
%																																								%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
clc;
close all;

% Simulation Parameters
Param.reset = 0;
Param.schRounds = 1;
Param.numSubFramesMacro = 50;
Param.numSubFramesMicro = 25;
Param.numMacro = 1;
Param.numMicro = 5;
Param.seed = 122;
Param.buildings = load('mobility/buildings.txt');
Param.velocity = 3; %in km/h
Param.numUsers = 15;
Param.utilLoThr = 1;
Param.utilHiThr = 51;
Param.ulFreq = 1747.5;
Param.dlFreq = 1842.5;
Param.maxTbSize = 97896;
Param.maxCwdSize = 10^5;
Param.maxSymSize = 10^5;
Param.storeTxData = true;
Param.scheduling = 'roundRobin';
Param.prbSym = 160;

sonohi(Param.reset);

% Channel configuration
Param.channel.mode = 'mobility'; % ['mobility','fading'];

% Guard for initial setup: exit of there's more than 1 macro BS
if (Param.numMacro ~= 1)
	return;
end

% Create Stations and Users
Stations = createBaseStations(Param);
Users = createUsers(Param);

% Create Channels
Stations = createChannels(Stations,Param);

% Create channel estimator
ChannelEstimator = createChannelEstimator();

% Create structures to hold transmission data
if (Param.storeTxData)
	[tbMatrix, tbMatrixInfo] = initTbMatrix(Param);
	[cwdMatrix, cwdMatrixInfo] = initCwdMatrix(Param);
end
[symMatrix, symMatrixInfo] = initSymMatrix(Param);

% Get traffic source data and check if we have already the MAT file with the traffic data
if (exist('traffic/trafficSource.mat', 'file') ~= 2 || Param.reset)
	trSource = loadTrafficData('traffic/bunnyDump.csv', true);
else
	load('traffic/trafficSource.mat', 'trSource');
end

% Utilisation ranges
if (Param.utilLoThr > 0 && Param.utilLoThr <= 100 && Param.utilHiThr > 0 && ...
	 	Param.utilHiThr <= 100)
	utilLo = 1:Param.utilLoThr;
	utilHi = Param.utilHiThr:100;
else
	return;
end

% Main loop
for (iUtilLo = 1: length(utilLo))
	for (iUtilHi = 1:length(utilHi))
		for (iRound = 1:Param.schRounds)
			% In each scheduling round, check UEs associated with each station and
			% allocate PRBs through the scheduling function per each station

			% check which UEs are associated to which eNB
			[Users, Stations] = refreshUsersAssociation(Users, Stations, Param);
			simTime = iRound*10^-3;

			for (iStation = 1:length(Stations))

				% Update RLC transmission queues for the connected users
				Stations(iStation).Users = updateTrQueue(trSource, iRound, Stations(iStation).Users);

				% schedule only if at least 1 user is associated
				if (Stations(iStation).Users(1).ueId ~= 0)
					Stations(iStation) = schedule(Stations(iStation), Param);
				end
			end;

			% per each user, create the codeword
			for (iUser = 1:length(Users))
				% get the eNodeB thie UE is connected to
				iServingStation = find([Stations.NCellID] == Users(iUser).eNodeB);

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
                % Get associated user that is scheduled
                
                schUser = Stations(iStation).Schedule(iRound).ueId;

				% generate empty grid or clean the previous one
				Stations(iStation).ResourceGrid = lteDLResourceGrid(Stations(iStation));
				% now for each list of user symbols, reshape them into the grid
				for (iUser = 1:Param.numUsers)
					sz = symMatrixInfo(iStation, iUser).symSize;
					ixs = symMatrixInfo(iStation, iUser).indexes;
					if (sz ~= 0)
						% TODO revise padding/truncating (why symbols are not int multiples of 14?)
						tempSym(1:sz,1) = symMatrix(iStation, iUser, 1:sz);
						mapSym = mapSymbols(tempSym, length(ixs) * 14);
						Stations(iStation).ResourceGrid(ixs, :) = reshape(mapSym, [length(ixs), 14]);
					end
				end

				% with the grid ready, generate the TX waveform
                % Currently the waveform is given per station, i.e. same
                % for all associated users.
				[Stations(iStation).TxWaveform, Stations(iStation).Waveforminfo] = ...
					lteOFDMModulate(Stations(iStation), Stations(iStation).ResourceGrid);

				% Now for each UE - eNodeB pair filter through the channel
				for (iUser = 1:length(Users))
					Stations(iStation).Channel(iUser).InitTime = iRound/1000;
                    
                    % Pass through channel model
                    Users(iUser).rxWaveform = ...
                        Stations(iStation).Channel(iUser).propagate(Stations(iStation).TxWaveform);
						
                    
                    %TODO
                    %Compute power from eNB and calculate transmission SNR
                    
                    %Normalize power for AWGN impairment
                    %N0 = 1/(sqrt(2.0*Stations(iStation).CellRefP*double(Stations(iStation).Waveforminfo.Nfft))*SNR);
                    
                    % Add AWGN in time domain
                    %noise = No*complex(randn(length(Users(iUser).rxWaveform)),...
                    %randn(length(Users(iUser).rxWaveform)));
                    
                   
					
				end
      end

			% The first step at the DL receiver is to

			% After all Stations computed the tx and estiamted rx waveforms, sum
			% over all the rx waveforms and demodulate
			% TODO UE-specific summation with rx waveforms scaled by pathloss factor
			% for each user bla bla bla
			% rxWaveform = k_i * rxWaveforms(i) + noise

			% TODO demodulate rx waveform per each station again
			% for each station bla bla bla
			% rxSubFrame = lteOFDMDemodulate(Stations(iStation), rxWaveform)

			% TODO do channel estimation for the received subframe
			% for each station bla bla bla
			% [estChannelGrid,noiseEst] = lteDLChannelEstimate(Stations(iStation),ChannelEstimator, ...
      % 	rxSubframe);
			% TODO compute sinr and estimate CQI based on the channel estimation
			% for each station bla bla bla
			% [cqi, sinr] = lteCQISelect(Stations(iStation),Stations(iStation).PDSCH,...
			% 	estChannelGrid,noiseEst);

			% TODO Record stats and power consumed in this round
		end
	end
end
