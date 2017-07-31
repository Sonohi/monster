function [txWaveform, info, txGrid] = generateDummyFrame(enbObj)

%   GENERATE DUMMY FRAME  is used to generate a full LTE frame for piloting
%
%   Function fingerprint
%   enbObj						->  a EvolvedNodeB object
%
%   txWaveform		->  resulting transmitted waveform
%		info									->	resulting waveform info
%		txGrid							-> resulting transmission grid

enb = cast2Struct(enbObj);
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
