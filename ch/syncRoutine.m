function [UsersNew, ChannelNew]  = syncRoutine(Stations, Users, Channel, Param, varargin)
%% SYNC ROUTINE Computes the timing offset required for synchronization between TX and RX. Should be run explicit at the start of a new temporal iteration where a discrete synchronization is required.
% For using debug mode, forward a channel estimator, e.g.
% Users = sync_routine(Stations, Users, Channel, Param,'Debug',ChannelEstimator);
%
% 1. Traverse the channel setup (with a full frame) and compute the offset based on the PSS and SSS
% 2. Mutates Users and Channels (saves WINNER response or fading seed)
%
% TODO Test with multiple antennas
% TODO Add BER curve of demodulated frame.
% TODO Validate input

validateChannel(Channel);
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

% In the stations copy, set the txWaveform etc from the dummy frames info
for iStation = 1:length(StationsNew)
	StationsNew(iStation).Tx.Waveform = StationsNew(iStation).Tx.Frame;
	StationsNew(iStation).Tx.WaveformInfo = StationsNew(iStation).Tx.FrameInfo;
	StationsNew(iStation).Tx.ReGrid = StationsNew(iStation).Tx.FrameGrid;
end

% Traverse channel
sonohilog(sprintf('Traversing channel (mode: %s)...',Param.channel.mode),'NFO')
[StationsNew, Users, ChannelNew] = Channel.traverse(StationsNew,Users,'downlink');

% Compute offset
for p = 1:length(Users)
	% Find serving station
	station = StationsNew(find([StationsNew.NCellID] == Users(p).ENodeBID));
	% Compute offset
	% TODO add try catch as lteDLFrameOffset could throw a size mismatch error
	NotAbleToDemod = 1;
	maxTries = 5;
	tries = 0;
	while NotAbleToDemod
		try
			if tries == maxTries
				UsersNew(p).Rx.Offset = 0;
				NotAbleToDemod = 0;
			else
				UsersNew(p).Rx.Offset = lteDLFrameOffset(struct(station), Users(p).Rx.Waveform);
				NotAbleToDemod = 0;
			end

		catch ME
			sonohilog(sprintf('Not able to locate synchronization signal, trying again for user %i, (try %i)',p,tries),'WRN')
			NotAbleToDemod = 1;
			tries = tries +1;
		end

	end

	%% DEBUGGING STUFF
	if exist('ChannelEstimator', 'var')
		rxWaveform = Users(p).Rx.Waveform(1+UsersNew(p).Rx.Offset:end,:);

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
		[indPdsch, ~] = StationsNew(iSStation).getPDSCHindicies;

		eqGrid = lteEqualizeMMSE(rxGrid, estChannel, noiseEst);
		eqGrid_r = eqGrid(indPdsch);
		for i= 1:2:length(eqGrid_r)-2
			constDiagram(eqGrid_r(i:i+2))
		end


		%constDiagram(reshape(eqGrid,length(eqGrid(:,1))*length(eqGrid(1,:)),1))

		txGrid = StationsNew(iSStation).Tx.ReGrid;
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
