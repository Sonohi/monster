%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   MAIN 																										          					%
%																																							 	%
%   Simulation parameters                                                       %                    %
%		reset 						-> 	resets the paths and refreshes them										%
%		schRounds 				->	overall length of the simulation											%
%		numSubFramesMacro ->	bandwidth of macro cell																%
%													(100 subframes = 20 MHz bandwidth)										%
%		numSubFramesMicro ->	bandwidth of micro cell																%
%		numMacro 					->	number of macro cells																	%
%		numMicro					-> 	number of micro cells																	%
%		seed							-> 	seed for channel																			%
%		buildings					->	file path for coordinates of Manhattan grid						%
%		velocity					->	velocity of users																			%
%		numUsers					-> 	number of users																				%
%		utilLoThr					->	lower threshold of utilisation												%
%		utilHiThr					->	upper threshold of utilisation												%
%		Channel.mode			->	channel model to be used															%
%																																								%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

clearvars;
clc;
close all;

% Simulation parameters
param.reset = 0;
param.schRounds = 10;
param.numSubFramesMacro = 50;
param.numSubFramesMicro = 25;
param.numMacro = 1;
param.numMicro = 5;
param.seed = 122;
param.buildings = load('mobility/buildings.txt');
param.velocity = 3; %in km/h
param.numUsers = 15;
param.utilLoThr = 1;
param.utilHiThr = 51;
param.ulFreq = 1747.5;
param.dlFreq = 1842.5;
param.maxTBSize = 97896;
param.maxCwdSize = 10^5;
param.maxSymSize = 10^5;

sonohi(param.reset);

% Channel configuration
param.Channel.mode = 'fading'; % ['mobility','fading'];

% Guard for initial setup: exit of there's more than 1 macro BS
if (param.numMacro ~= 1)
	return;
end

% Create stations and users
stations = createBaseStations(param);
users = createUsers(param);

% Create channels
channels = createChannels(stations,param);

% Create channel estimator
cec = createChEstimator();

% Create structures to hold the transport blocks and codewords
[trBlocks, trBlocksInfo] = initTrBlocks(param);
[codewords, codewordsInfo] = initCwds(param);
[symbols, symbolsInfo] = initSyms(param);

% Get traffic source data and check if we have already the MAT file with the traffic data
if (exist('traffic/trafficSource.mat', 'file') ~= 2 || param.reset)
	trSource = loadTrafficData('traffic/bunnyDump.csv', true);
else
	load('traffic/trafficSource.mat', 'trSource');
end

% Utilisation ranges
if (param.utilLoThr > 0 && param.utilLoThr <= 100 && param.utilHiThr > 0 && ...
	 	param.utilHiThr <= 100)
	utilLo = 1:param.utilLoThr;
	utilHi = param.utilHiThr:100;
else
	return;
end


% Main loop
for (utilLoIx = 1: length(utilLo))
	for (utilHiIx = 1:length(utilHi))
		for (roundIx = 1:param.schRounds)
			% In each scheduling round, check UEs associated with each station and
			% allocate PRBs through the scheduling function per each station

			% check which UEs are associated to which eNB
			[users, stations] = checkAssociatedUsers(users, stations, param);
			simTime = roundIx*10^-3;

			for (stationIx = 1:length(stations))
				% schedule the associated users for this round
				stations(stationIx).schedule = allocatePRBs(stations(stationIx));
			end;

			% per each user, create the codeword
			for (userIx = 1:length(users))
				% get the eNodeB thie UE is connected to
				svIx = find([stations.NCellID] == users(userIx).eNodeB);

				% Check if this UE is scheduled otherwise skip
				if (checkUserSchedule(users(userIx), stations(svIx)))
					% check if the UE has anything in the queue or if frame delivery expired
					if (users(userIx).queue.size == 0 || users(userIx).queue.time >= simTime)
						% in this case, call the updateTrQueue
						users(userIx).queue = updateTrQueue(trSource, roundIx,	users(userIx).queue);
					end;

					% if after the update, queue size is still 0, then the UE does not have
					% anything to send, otherwise create TB
					if (users(userIx).queue.size ~= 0)
						[trBlocks(svIx, userIx, :), trBlocksInfo(svIx, userIx)] = ...
							createTrBlk(stations(svIx), users(userIx), stations(svIx).schedule,...
								users(userIx).queue.size, param);

						% generate codeword (RV defaulted to 0)
						[codewords(svIx, userIx, :), codewordsInfo(svIx, userIx)] = ...
							createCodeword(trBlocks(svIx,	userIx, :), trBlocksInfo(svIx, userIx), ...
							param);

						% finally, generate the arrays of complex symbols by setting the
						% correspondent values per each eNodeB-UE pair
						% setup current subframe for serving eNodeB
						stations(svIx).NSubframe = roundIx;
						[symbols(svIx, userIx, :), symbolsInfo(svIx, userIx)] = createSymbols(...
							stations(svIx), channels(svIx, userIx), codewords(svIx, userIx), ...
							codewordsInfo(svIx, userIx));

					end
				end
			end





			% Obtain the number of transmit antennas.
			% P = lteDLResourceGridSize(stations(stationIx)(3));
			% generate txWaveform
	    % txWaveforms(stationIx) = [lteOFDMModulate(stations(stationIx),dlschTransportBlk);...
			% 	zeros(25,P)];
			% set channel init time
			% channels(stationIx).InitTime = subFrameIx/1000;
			% pass the tx waveform through the LTE fading channel
			% rxWaveforms(stationIx) = lteFadingChannel(channels(stationIx),...
			% 	txWaveforms(stationIx));
			% generate background AWGN
			% noise(stationIx) = No*complex(randn(size(rxWaveforms(stationIx))),...
      %   randn(size(rxWaveforms(stationIx))));

			% After all stations computed the tx and estiamted rx waveforms, sum
			% over all the rx waveforms and demodulate
			% TODO UE-specific summation with rx waveforms scaled by pathloss factor
			% for each user bla bla bla
			% rxWaveform = k_i * rxWaveforms(i) + noise

			% TODO demodulate rx waveform per each station again
			% for each station bla bla bla
			% rxSubFrame = lteOFDMDemodulate(stations(stationIx), rxWaveform)

			% TODO do channel estimation for the received subframe
			% for each station bla bla bla
			% [estChannelGrid,noiseEst] = lteDLChannelEstimate(stations(stationIx),cec, ...
      % 	rxSubframe);
			% TODO compute sinr and estimate CQI based on the channel estimation
			% for each station bla bla bla
			% [cqi, sinr] = lteCQISelect(stations(stationIx),stations(stationIx).PDSCH,...
			% 	estChannelGrid,noiseEst);

			% TODO Record stats and power consumed in this round
		end
	end
end
