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



% Generate dummy data for all stations, e.g. one full frame
for i = 1:length(Stations)
	[Stations(i).TxWaveform, Stations(i).WaveformInfo, Stations(i).ReGrid] = ...
		generateDummyFrame(cast2Struct(Stations(i)));
	Stations(i).WaveformInfo.OfdmEnergyScale = 1; % Full RB is used, so scale is set to one
end


% Initial association.
% check which UEs are associated to which eNB
[Users, Stations] = refreshUsersAssociation(Users, Stations, Channel, Param);

% Traverse channel
[Stations, Users, ChannelNew] = Channel.traverse(Stations,Users);


% Compute offset
for p = 1:length(Users)
	% Find serving station
	iSStation = find([Stations.NCellID] == Users(p).ENodeB);
	% Compute offset
	UsersNew(p).Offset(FrameNo) = lteDLFrameOffset(struct(Stations(iSStation)), Users(p).RxWaveform);

	%% DEBUGGING STUFF
	if exist('ChannelEstimator', 'var')
		rxWaveform = Users(p).RxWaveform(1+UsersNew(p).Offset(FrameNo):end,:);
        
		rxGrid = lteOFDMDemodulate(struct(Stations(iSStation)),rxWaveform);

		%enb.NSubframe = 0;
		[estChannel, noiseEst] = lteDLChannelEstimate(struct(Stations(iSStation)),ChannelEstimator,rxGrid);


		constDiagram = comm.ConstellationDiagram('SamplesPerSymbol',1, ...
			'SymbolsToDisplaySource','Property','SymbolsToDisplay',600);
		%rxGrid_r = reshape(rxGrid,length(rxGrid(:,1))*length(rxGrid(1,:)),1);
		%for i= 1:30:length(rxGrid_r)-30
		%     constDiagram(rxGrid_r(i:i+30))
		%end

		% get PDSCH indexes
		[indPdsch, info] = Stations(iSStation).getPDSCHindicies;

		eqGrid = lteEqualizeMMSE(rxGrid, estChannel, noiseEst);
		eqGrid_r = eqGrid(indPdsch);
		for i= 1:2:length(eqGrid_r)-2
			constDiagram(eqGrid_r(i:i+2))
		end


		%constDiagram(reshape(eqGrid,length(eqGrid(:,1))*length(eqGrid(1,:)),1))

		txGrid = Stations(iSStation).ReGrid;
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

% At the end of the sync routine check whether we need to rerutn the newStations
% for generating the heatmap
if Param.generateHeatMap
	StationsNew = Stations;
else
	StationsNew = [];
end
end


function [txWaveform, info, txGrid] = generateDummyFrame(enb)


gridsize = lteDLResourceGridSize(enb);
K = gridsize(1);    % Number of subcarriers
L = gridsize(2);    % Number of OFDM symbols in one subframe
P = gridsize(3);    % Number of transmit antenna ports


%% Transmit Resource Grid
% An empty resource grid |txGrid| is created which will be populated with
% subframes.
txGrid = [];

%% Payload Data Generation
% As no transport channel is used in this example the data sent over the
% channel will be random QPSK modulated symbols. A subframe worth of
% symbols is created so a symbol can be mapped to every resource element.
% Other signals required for transmission and reception will overwrite
% these symbols in the resource grid.

% Number of bits needed is size of resource grid (K*L*P) * number of bits
% per symbol (2 for QPSK)
numberOfBits = K*L*P*2;

% Create random bit stream
inputBits = randi([0 1], numberOfBits, 1);

% Modulate input bits
inputSym = lteSymbolModulate(inputBits,'QPSK');

%% Frame Generation
% The frame will be created by generating individual subframes within a
% loop and appending each created subframe to the previous subframes. The
% collection of appended subframes are contained within |txGrid|. This
% appending is repeated ten times to create a frame. When the OFDM
% modulated time domain waveform is passed through a channel the waveform
% will experience a delay. To avoid any samples being missed due to this
% delay an extra subframe is generated, therefore 11 subframes are
% generated in total. For each subframe the Cell-Specific Reference Signal
% (Cell RS) is added. The Primary Synchronization Signal (PSS) and
% Secondary Synchronization Signal (SSS) are also added. Note that these
% synchronization signals only occur in subframes 0 and 5, but the LTE
% System Toolbox takes care of generating empty signals and indices in the
% other subframes so that the calling syntax here can be completely uniform
% across the subframes.

% For all subframes within the frame
for sf = 0:10

	% Set subframe number
	enb.NSubframe = mod(sf,10);

	% Generate empty subframe
	subframe = lteDLResourceGrid(enb);

	% Map input symbols to grid
	subframe(:) = inputSym;

	% Generate synchronizing signals
	pssSym = ltePSS(enb);
	sssSym = lteSSS(enb);
	pssInd = ltePSSIndices(enb);
	sssInd = lteSSSIndices(enb);

	% Map synchronizing signals to the grid
	subframe(pssInd) = pssSym;
	subframe(sssInd) = sssSym;

	% Generate cell specific reference signal symbols and indices
	cellRsSym = lteCellRS(enb);
	cellRsInd = lteCellRSIndices(enb);

	% Map cell specific reference signal to grid
	subframe(cellRsInd) = cellRsSym;

	% check whether we want to generate

	% Append subframe to grid to be transmitted
	txGrid = [txGrid subframe]; %#ok

end

[txWaveform,info] = lteOFDMModulate(enb,txGrid);


end
