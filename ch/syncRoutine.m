function [UsersNew, StationsNew, ChannelNew]  = syncRoutine(FrameNo, Stations, Users, Channel, Param, varargin)
%% SYNC ROUTINE Computes the timing offset required for synchronization between TX and RX.
% For using debug mode, forward a channel estimator, e.g.
% Users = sync_routine(FrameNo,Stations, Users, Channel, Param,'Debug',ChannelEstimator);
%
% 1. Computes a full frame with PSS and SSS (given base station configuration)
% 2. Traverse the channel setup and compute the offset based on the PSS and SSS
% TODO
% * Test with multiple antennas
% * Add BER curve of demodulated frame.
sonohilog('Performing full frame sync routine...','NFO')
if nargin > 5
	nVargs = length(varargin);
	for k = 1:nVargs
		if strcmp(varargin{k},'Debug')
			ChannelEstimator = varargin{k+1};
		end
	end
end
% Save in temp variable
UsersNew = Users;
StationsNew = Stations;

% Generate dummy data for all stations, e.g. one full frame
for i = 1:length(StationsNew)
	[StationsNew(i).TxWaveform, StationsNew(i).WaveformInfo, StationsNew(i).ReGrid] = ...
		generateDummyFrame(StationsNew(i));
	StationsNew(i).WaveformInfo.OfdmEnergyScale = 1; % Full RB is used, so scale is set to one
end

% Initial association.
% check which UEs are associated to which eNB
[Users, StationsNew] = refreshUsersAssociation(Users, StationsNew, Channel, Param);

% Traverse channel

 sonohilog(sprintf('Traversing channel (mode: %s)...',Param.channel.mode),'NFO')
[StationsNew, Users, ChannelNew] = Channel.traverse(StationsNew,Users);

% Compute offset
for p = 1:length(Users)
	% Find serving station
	iSStation = find([StationsNew.NCellID] == Users(p).ENodeB);
	% Compute offset
	UsersNew(p).Rx.Offset(FrameNo) = lteDLFrameOffset(struct(StationsNew(iSStation)), Users(p).Rx.Waveform);

	%% DEBUGGING STUFF
	if exist('ChannelEstimator', 'var')
		rxWaveform = Users(p).Rx.Waveform(1+UsersNew(p).Rx.Offset(FrameNo):end,:);

		rxGrid = lteOFDMDemodulate(struct(StationsNew(iSStation)),rxWaveform);

		%enb.NSubframe = 0;
		[estChannel, noiseEst] = lteDLChannelEstimate(struct(StationsNew(iSStation)),ChannelEstimator,rxGrid);


		constDiagram = comm.ConstellationDiagram('SamplesPerSymbol',1, ...
			'SymbolsToDisplaySource','Property','SymbolsToDisplay',600);
		%rxGrid_r = reshape(rxGrid,length(rxGrid(:,1))*length(rxGrid(1,:)),1);
		%for i= 1:30:length(rxGrid_r)-30
		%     constDiagram(rxGrid_r(i:i+30))
		%end

		% get PDSCH indexes
		[indPdsch, info] = StationsNew(iSStation).getPDSCHindicies;

		eqGrid = lteEqualizeMMSE(rxGrid, estChannel, noiseEst);
		eqGrid_r = eqGrid(indPdsch);
		for i= 1:2:length(eqGrid_r)-2
			constDiagram(eqGrid_r(i:i+2))
		end


		%constDiagram(reshape(eqGrid,length(eqGrid(:,1))*length(eqGrid(1,:)),1))

		txGrid = StationsNew(iSStation).ReGrid;
		%eqError = txGrid - eqGrid;
		%rxError = txGrid - rxGrid;


		EVM = comm.EVM;
		EVM.AveragingDimensions = [1 2];
		preEqualisedEVM = EVM(txGrid,rxGrid);
		fprintf('Percentage RMS EVM of Pre-Equalized signal: %0.3f%%\n', ...
			preEqualisedEVM);
		%EVM of post-equalized receive signal
		postEqualisedEVM = EVM(txGrid,eqGrid);
		fprintf('Percentage RMS EVM of Post-Equalized signal: %0.3f%%\n', ...
			postEqualisedEVM);

		% Plot the received and equalized resource grids
		hDownlinkEstimationEqualizationResults(rxGrid, eqGrid);
	end
end
end
