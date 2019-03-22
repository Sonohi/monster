%% PDSCH Throughput Conformance Test for Single Antenna (TM1), Transmit Diversity (TM2), Open Loop (TM3) and Closed Loop (TM4/6) Spatial Multiplexing
% This example demonstrates how to measure the Physical Downlink Shared
% Channel (PDSCH) throughput performance using LTE Toolbox(TM) for the
% following transmission modes (TM):
%
% * TM1: Single antenna (Port 0)
% * TM2: Transmit diversity
% * TM3: Open loop codebook based precoding: Cyclic Delay Diversity (CDD)
% * TM4: Closed loop codebook based spatial multiplexing
% * TM6: Single layer closed loop codebook based spatial multiplexing
%
% The example also shows how to parameterize and customize the settings for
% the different TMs. It also supports the use of 
% Parallel Computing Toolbox(TM) to reduce effective simulation time.

% Copyright 2016-2018 The MathWorks, Inc.

%% Introduction
% This example measures the throughput for a number of SNR points. The
% provided code can operate under a number of transmission modes: TM1, TM2,
% TM3, TM4 and TM6. For information on how to model TM7, TM8, TM9 and TM10
% check the following example: <PDSCHThroughputTM7to10Example.html PDSCH
% Throughput for Non-Codebook Based Precoding Schemes: Port 5 (TM7), Port 7
% or 8 or Port 7-8 (TM8), Port 7-14 (TM9 and TM10)>
%
% The example works on a subframe by subframe basis. For each of the
% considered SNR points a populated resource grid is generated and OFDM
% modulated to create a transmit waveform. The generated waveform is passed
% through a noisy fading channel. The following operations are then
% performed by the receiver: channel estimation, equalization, demodulation
% and decoding. The throughput performance of the PDSCH is determined using
% the block CRC result at the output of the channel decoder.
%
% Precoder Matrix Indication (PMI) feedback is implemented for the TMs
% requiring the feedback of a precoding matrix (TM4 and TM6).
% 
% A <matlab:doc('parfor') parfor> loop can be used instead of the
% <matlab:doc('for') for> loop for the SNR calculation. This is indicated
% within the example. The <matlab:doc('parfor') parfor> statement is part
% of the Parallel Computing Toolbox and executes the SNR loop in parallel
% to reduce the total simulation time.

%% Simulation Configuration
% The example is executed for a simulation length of 2 frames for a number
% of SNR points. A large number of |NFrames| should be used to produce
% meaningful throughput results. |SNRIn| can be an array of values or a
% scalar. Some TMs and certain modulation schemes are more robust to noise
% and channel impairments than others, therefore different values of SNR
% may have to be used for different parameter sets.

NFrames = 10;                % Number of frames
SNRIn = linspace(0,20,20);%[10.3 12.3 14.3];   % SNR range in dB

%% eNodeB Configuration
% This section selects the TM of interest and sets the eNodeB parameters.
% The TM is selected using the variable |txMode|, which can take the values
% TM1, TM2, TM3, TM4 and TM6.

txMode = 'TM1'; % TM1, TM2, TM3, TM4, TM6

%% 
% For simplicity all TMs modeled in this example have a bandwidth of 50
% resource blocks with a full allocation and a code rate of 0.5. Not
% specifying an RMC number ensures that all downlink subframes are
% scheduled. If RMC is specified (e.g. 'R.0'), the subframe scheduling is
% as defined in TS 36.101 [ <#19 1> ] where subframe 5 is not scheduled in
% most cases.
% 
% The variable |txMode| selects the TM via a switch statement. For each TM,
% the required parameters are specified. This example does not perform DCI
% format decoding, so the |DCIFormat| field is not strictly necessary.
% However, since the DCI format is closely linked to the TM, it is
% included for completeness.

simulationParameters = []; % clear simulationParameters   
simulationParameters.NDLRB = 50;        
simulationParameters.PDSCH.TargetCodeRate = 0.5;
simulationParameters.PDSCH.PRBSet = (0:49)';

switch txMode
% Single antenna (Port0) mode (TM1)
    case 'TM1'
        fprintf('\nTM1 - Single antenna (port 0)\n');
        simulationParameters.PDSCH.TxScheme = 'Port0';
        simulationParameters.PDSCH.DCIFormat = 'Format1';
        simulationParameters.CellRefP = 1;
        simulationParameters.PDSCH.Modulation = {'64QAM'};

% Transmit diversity mode (TM2)
    case 'TM2'
        fprintf('\nTM2 - Transmit diversity\n');
        simulationParameters.PDSCH.TxScheme = 'TxDiversity';
        simulationParameters.PDSCH.DCIFormat = 'Format1';
        simulationParameters.CellRefP = 2;
        simulationParameters.PDSCH.Modulation = {'16QAM'};
        simulationParameters.PDSCH.NLayers = 2;           
 
% CDD mode (TM3)
    case 'TM3'
        fprintf('\nTM3 - CDD\n');        
        simulationParameters.PDSCH.TxScheme = 'CDD';
        simulationParameters.PDSCH.DCIFormat = 'Format2A';
        simulationParameters.CellRefP = 2;
        simulationParameters.PDSCH.Modulation = {'16QAM', '16QAM'};
        simulationParameters.PDSCH.NLayers = 2;
        
% Spatial multiplexing mode (TM4)
    case 'TM4'
        fprintf('\nTM4 - Codebook based spatial multiplexing\n');
        simulationParameters.CellRefP = 2;
        simulationParameters.PDSCH.Modulation = {'16QAM', '16QAM'};
        simulationParameters.PDSCH.DCIFormat = 'Format2';
        simulationParameters.PDSCH.TxScheme = 'SpatialMux';        
        simulationParameters.PDSCH.NLayers = 2;
        % No codebook restriction
        simulationParameters.PDSCH.CodebookSubset = '';

% Single layer spatial multiplexing mode (TM6)
    case 'TM6'
        fprintf(...
        '\nTM6 - Codebook based spatial multiplexing with single layer\n');
        simulationParameters.CellRefP = 4;
        simulationParameters.PDSCH.Modulation = {'QPSK'};        
        simulationParameters.PDSCH.DCIFormat = 'Format2';
        simulationParameters.PDSCH.TxScheme = 'SpatialMux';
        simulationParameters.PDSCH.NLayers = 1;
        % No codebook restriction
        simulationParameters.PDSCH.CodebookSubset = '';

    otherwise
        error('Transmission mode should be one of TM1, TM2, TM3, TM4 or TM6.')
end

% Set other simulationParameters fields applying to all TMs
simulationParameters.TotSubframes = 1; % Generate one subframe at a time
simulationParameters.PDSCH.CSI = 'On'; % Soft bits are weighted by CSI

%%
% Call <matlab:doc('lteRMCDL') lteRMCDL> to generate the default eNodeB
% parameters not specified in |simulationParameters|. These will be
% required later to generate the waveform using <matlab:doc('lteRMCDLTool')
% lteRMCDLTool>.

enb = lteRMCDL(simulationParameters);

%%
% The output |enb| structure contains, amongst other fields, the transport
% block sizes and redundancy version sequence for each codeword subframe
% within a frame. These will be used later in the simulation.

rvSequence = enb.PDSCH.RVSeq;
trBlkSizes = enb.PDSCH.TrBlkSizes;

%%
% The number of codewords, |ncw|, is the number of entries in the
% |enb.PDSCH.Modulation| field.
ncw = length(string(enb.PDSCH.Modulation));

%%
% Set the PMI delay for the closed-loop TMs (TM4 and TM6). This is the
% delay between a PMI being passed from UE to eNodeB as defined in
% TS36.101, Table 8.2.1.4.2-1 [ <#19 1> ]. 

pmiDelay = 8;

%%
% Next we print a summary of some of the more relevant simulation
% parameters. Check these values to make sure they are as expected. The
% code rate displayed can be useful to detect problems if manually
% specifying the transport block sizes. Typical values are 1/3, 1/2 and
% 3/4.

hDisplayENBParameterSummary(enb, txMode);

%% Propagation Channel Model Configuration
% The structure |channel| contains the channel model configuration
% parameters.

channel.Seed = 6;                    % Channel seed
channel.NRxAnts = 2;                 % 2 receive antennas
channel.DelayProfile = 'EPA';        % Delay profile
channel.DopplerFreq = 5;             % Doppler frequency
channel.MIMOCorrelation = 'Low';     % Multi-antenna correlation
channel.NTerms = 16;                 % Oscillators used in fading model
channel.ModelType = 'GMEDS';         % Rayleigh fading model type
channel.InitPhase = 'Random';        % Random initial phases
channel.NormalizePathGains = 'On';   % Normalize delay profile power  
channel.NormalizeTxAnts = 'On';      % Normalize for transmit antennas

% The sampling rate for the channel model is set using the value returned
% from <matlab:doc('lteOFDMInfo') lteOFDMInfo>.

ofdmInfo = lteOFDMInfo(enb);
channel.SamplingRate = ofdmInfo.SamplingRate;

%% Channel Estimator Configuration
% The variable |perfectChanEstimator| controls channel estimator behavior.
% Valid values are |true| or |false|. When set to |true| a perfect channel
% response is used as estimate, otherwise an imperfect estimation based on
% the values of received pilot signals is obtained.

% Perfect channel estimator flag
perfectChanEstimator = false;

%%
% If |perfectChanEstimator| is set to false a configuration structure |cec|
% is needed to parameterize the channel estimator. The channel changes
% slowly in time and frequency, therefore a large averaging window is used
% in order to average the noise out.

% Configure channel estimator
cec.PilotAverage = 'UserDefined';   % Type of pilot symbol averaging
cec.FreqWindow = 41;                % Frequency window size in REs
cec.TimeWindow = 27;                % Time window size in REs
cec.InterpType = 'Cubic';           % 2D interpolation type
cec.InterpWindow = 'Centered';      % Interpolation window type
cec.InterpWinSize = 1;              % Interpolation window size

%% Display Simulation Information
% The variable |displaySimulationInformation| controls the display of
% simulation information such as the HARQ process ID used for each
% subframe. In case of CRC error the value of the index to the RV sequence
% is also displayed.

displaySimulationInformation = true;

%% Processing Loop
% To determine the throughput at each SNR point, the PDSCH data is analyzed
% on a subframe by subframe basis using the following steps:
%
% * _Update Current HARQ Process._ The HARQ process either carries new
% transport data or a retransmission of previously sent transport data
% depending upon the Acknowledgment (ACK) or Negative Acknowledgment (NACK)
% based on CRC results. All this is handled by the HARQ scheduler,
% <matlab:edit('hHARQScheduling.m') hHARQScheduling.m>. The PDSCH data is
% updated based on the HARQ state.
%
% * _Set PMI._ This step is only applicable to TM4 and TM6 (closed loop
% spatial multiplexing and single layer closed loop spatial multiplexing).
% A PMI is taken sequentially from a set of PMIs, |txPMIs|, each subframe
% and used by the eNodeB to select a precoding matrix. The PMI recommended
% by the UE is used by the eNodeB for data transmission. There is a delay
% of |pmiDelay| subframes between the UE recommending the PMI and the
% eNodeB using it to select a precoding matrix. Initially a set of
% |pmiDelay| random PMIs is used.
%
% * _Create Transmit Waveform._ The data generated by the HARQ process is
% passed to <matlab:doc('lteRMCDLTool') lteRMCDLTool> which produces an
% OFDM modulated waveform, containing the physical channels and signals.
%
% * _Noisy Channel Modeling._ The waveform is passed through a fading
% channel and noise (AWGN) is added.
%
% * _Perform Synchronization and OFDM Demodulation._ The received symbols
% are offset to account for a combination of implementation delay and
% channel delay spread. The symbols are then OFDM demodulated.
%
% * _Perform Channel Estimation._ The channel response and noise levels are
% estimated. These estimates are used to decode the PDSCH.
%
% * _Decode the PDSCH._ The recovered PDSCH symbols for all transmit and
% receive antenna pairs, along with a noise estimate, are demodulated and
% descrambled by <matlab:doc('ltePDSCHDecode') ltePDSCHDecode> to obtain an
% estimate of the received codewords.
%
% * _Decode the Downlink Shared Channel (DL-SCH) and Store the Block CRC
% Error for a HARQ Process._ The vector of decoded soft bits is passed to
% <matlab:doc('lteDLSCHDecode') lteDLSCHDecode>; this decodes the codeword
% and returns the block CRC error used to determine the throughput of the
% system. The contents of the new soft buffer, |harqProc(harqID).decState|,
% is available at the output of this function to be used when decoding the
% next subframe.
%
% * _Update PMI._ A PMI is selected and fed back to the eNodeB for future
% use. This step is only applicable to TM4 and TM6 (close loop spatial
% multiplexing and single layer closed loop spatial multiplexing).

% The number of transmit antennas P is obtained from the resource grid
% dimensions. 'dims' is M-by-N-by-P where M is the number of subcarriers, N
% is the number of symbols and P is the number of transmit antennas.
dims = lteDLResourceGridSize(enb);
P = dims(3);

% Initialize variables used in the simulation and analysis
% Array to store the maximum throughput for all SNR points
maxThroughput = zeros(length(SNRIn),1); 
% Array to store the simulation throughput for all SNR points
simThroughput = zeros(length(SNRIn),1);

% The temporary variables 'enb_init' and 'channel_init' are used to create
% the temporary variables 'enb' and 'channel' within the SNR loop to create
% independent simulation loops for the 'parfor' loop
enb_init = enb;
channel_init = channel;
legendString = ['Throughput: ' char(enb.PDSCH.TxScheme)];
allRvSeqPtrHistory = cell(1,numel(SNRIn));
nFFT = ofdmInfo.Nfft;

for snrIdx = 1:numel(SNRIn)
% parfor snrIdx = 1:numel(SNRIn)
% To enable the use of parallel computing for increased speed comment out
% the 'for' statement above and uncomment the 'parfor' statement below.
% This needs the Parallel Computing Toolbox. If this is not installed
% 'parfor' will default to the normal 'for' statement. If 'parfor' is
% used it is recommended that the variable 'displaySimulationInformation'
% above is set to false, otherwise the simulation information displays for
% each SNR point will overlap.

    % Set the random number generator seed depending to the loop variable
    % to ensure independent random streams
    rng(snrIdx,'combRecursive');
    
    SNRdB = SNRIn(snrIdx);
    fprintf('\nSimulating at %g dB SNR for %d Frame(s)\n' ,SNRdB, NFrames);
    
    % Initialize variables used in the simulation and analysis
    offsets = 0;            % Initialize frame offset value
    offset = 0;             % Initialize frame offset value for radio frame
    blkCRC = [];            % Block CRC for all considered subframes
    bitTput = [];           % Number of successfully received bits per subframe
    txedTrBlkSizes = [];    % Number of transmitted bits per subframe
    enb = enb_init;         % Initialize RMC configuration
    channel = channel_init; % Initialize channel configuration
    pmiIdx = 0;             % PMI index in delay queue
    
    % The variable harqPtrTable stores the history of the value of the
    % pointer to the RV sequence values for all the HARQ processes.
    % Pre-allocate with NaNs as some subframes do not have data
    rvSeqPtrHistory = NaN(ncw, NFrames*10);        
    
    % Initialize state of all HARQ processes
    harqProcesses = hNewHARQProcess(enb);
        
    % Use random PMIs for the first 'pmiDelay' subframes until feedback is
    % available from the UE; note that PMI feedback is only applicable for
    % spatial multiplexing TMs (TM4 and TM6), but the code here is required
    % for complete initialization of variables in the SNR loop when using
    % the Parallel Computing Toolbox.
    pmidims = ltePMIInfo(enb,enb.PDSCH);
    txPMIs = randi([0 pmidims.MaxPMI], pmidims.NSubbands, pmiDelay);
    % Initialize HARQ process IDs to 1 as the first non-zero transport
    % block will always be transmitted using the first HARQ process. This
    % will be updated with the full sequence output by lteRMCDLTool after
    % the first call to the function
    harqProcessSequence = 1;

    for subframeNo = 0:(NFrames*10-1)
        
        % Update subframe number
        enb.NSubframe = subframeNo;

        % Get HARQ process ID for the subframe from HARQ process sequence
        harqID = harqProcessSequence(mod(subframeNo, length(harqProcessSequence))+1);
                
        % If there is a transport block scheduled in the current subframe
        % (indicated by non-zero 'harqID'), perform transmission and
        % reception. Otherwise continue to the next subframe
        if harqID == 0
            continue;
        end
        
        % Update current HARQ process
        harqProcesses(harqID) = hHARQScheduling( ...
            harqProcesses(harqID), subframeNo, rvSequence);

        % Extract the current subframe transport block size(s)
        trBlk = trBlkSizes(:, mod(subframeNo, 10)+1).';

        % Display run time information
        if displaySimulationInformation
            disp(' ');
            disp(['Subframe: ' num2str(subframeNo)...
                            '. HARQ process ID: ' num2str(harqID)]);
        end
        
        % Update RV sequence pointer table
        rvSeqPtrHistory(:,subframeNo+1) = ...
                               harqProcesses(harqID).txConfig.RVIdx.';

        % Update the PDSCH transmission config with HARQ process state
        enb.PDSCH = harqProcesses(harqID).txConfig;      
        data = harqProcesses(harqID).data;

        % Set the PMI to the appropriate value in the delay queue
        if strcmpi(enb.PDSCH.TxScheme,'SpatialMux')
            pmiIdx = mod(subframeNo, pmiDelay);  % PMI index in delay queue
            enb.PDSCH.PMISet = txPMIs(:, pmiIdx+1); % Set PMI
        end

        % Create transmit waveform and get the HARQ scheduling ID sequence
        % from 'enbOut' structure output which also contains the waveform
        % configuration and OFDM modulation parameters
        [txWaveform,~,enbOut] = lteRMCDLTool(enb, data);
        
        % Add 25 sample padding. This is to cover the range of delays
        % expected from channel modeling (a combination of
        % implementation delay and channel delay spread)
        txWaveform =  [txWaveform; zeros(25, P)]; %#ok<AGROW>
        
        % Get the HARQ ID sequence from 'enbOut' for HARQ processing
        harqProcessSequence = enbOut.PDSCH.HARQProcessSequence;

        % Initialize channel time for each subframe
        channel.InitTime = subframeNo/1000;

        % Pass data through channel model
        rxWaveform = lteFadingChannel(channel, txWaveform);

        % Calculate noise gain including compensation for downlink power
        % allocation
        SNR = 10^((SNRdB-enb.PDSCH.Rho)/20);

        % Normalize noise power to take account of sampling rate, which is
        % a function of the IFFT size used in OFDM modulation, and the 
        % number of antennas
        N0 = 1/(sqrt(2.0*enb.CellRefP*double(nFFT))*SNR);

        % Create additive white Gaussian noise
        noise = N0*complex(randn(size(rxWaveform)), ...
                            randn(size(rxWaveform)));

        % Add AWGN to the received time domain waveform        
        rxWaveform = rxWaveform + noise;

        % Once every frame, on subframe 0, calculate a new synchronization
        % offset
        if (mod(subframeNo,10) == 0)
            offset = lteDLFrameOffset(enb, rxWaveform);
            if (offset > 25)
                offset = offsets(end);
            end
            offsets = [offsets offset]; %#ok
        end
        
        % Synchronize the received waveform
        rxWaveform = rxWaveform(1+offset:end, :);

        % Perform OFDM demodulation on the received data to recreate the
        % resource grid
        rxSubframe = lteOFDMDemodulate(enb, rxWaveform);

        % Channel estimation
        if(perfectChanEstimator) 
            estChannelGrid = lteDLPerfectChannelEstimate(enb, channel, offset); %#ok
            noiseGrid = lteOFDMDemodulate(enb, noise(1+offset:end ,:));
            noiseEst = var(noiseGrid(:));
        else
            [estChannelGrid, noiseEst] = lteDLChannelEstimate( ...
                enb, enb.PDSCH, cec, rxSubframe);
        end

        % Get PDSCH indices
        pdschIndices = ltePDSCHIndices(enb, enb.PDSCH, enb.PDSCH.PRBSet);

        % Get PDSCH resource elements from the received subframe. Scale the
        % received subframe by the PDSCH power factor Rho. The PDSCH is
        % scaled by this amount, while the cell reference symbols used for
        % channel estimation (used in the PDSCH decoding stage) are not.
        [pdschRx, pdschHest] = lteExtractResources(pdschIndices, ...
            rxSubframe*(10^(-enb.PDSCH.Rho/20)), estChannelGrid);

        % Decode PDSCH
        dlschBits = ltePDSCHDecode(...
                             enb, enb.PDSCH, pdschRx, pdschHest, noiseEst);

        % Decode the DL-SCH
        [decbits, harqProcesses(harqID).blkerr,harqProcesses(harqID).decState] = ...
            lteDLSCHDecode(enb, enb.PDSCH, trBlk, dlschBits, ...
                           harqProcesses(harqID).decState);

        % Display block errors
        if displaySimulationInformation
            if any(harqProcesses(harqID).blkerr)
                disp(['Block error. RV index: ' num2str(harqProcesses(harqID).txConfig.RVIdx)...
                      ', CRC: ' num2str(harqProcesses(harqID).blkerr)])
            else
                disp(['No error. RV index: ' num2str(harqProcesses(harqID).txConfig.RVIdx)...
                      ', CRC: ' num2str(harqProcesses(harqID).blkerr)])
            end
        end

        % Store values to calculate throughput
        % Only for subframes with data
        if any(trBlk)
            blkCRC = [blkCRC harqProcesses(harqID).blkerr]; %#ok<AGROW>
            bitTput = [bitTput trBlk.*(1- ...
                harqProcesses(harqID).blkerr)]; %#ok<AGROW>
            txedTrBlkSizes = [txedTrBlkSizes trBlk]; %#ok<AGROW>
        end

        % Provide PMI feedback to the eNodeB
        if strcmpi(enb.PDSCH.TxScheme,'SpatialMux')
            PMI = ltePMISelect(enb, enb.PDSCH, estChannelGrid, noiseEst);
            txPMIs(:, pmiIdx+1) = PMI;
        end
    end
    
    % Calculate maximum and simulated throughput
    maxThroughput(snrIdx) = sum(txedTrBlkSizes); % Max possible throughput
    simThroughput(snrIdx) = sum(bitTput,2);      % Simulated throughput
    
    % Display the results dynamically in the command window
    fprintf([['\nThroughput(Mbps) for ', num2str(NFrames) ' Frame(s) '],...
        '= %.4f\n'], 1e-6*simThroughput(snrIdx)/(NFrames*10e-3));
    fprintf(['Throughput(%%) for ', num2str(NFrames) ' Frame(s) = %.4f\n'],...
        simThroughput(snrIdx)*100/maxThroughput(snrIdx));
    
    allRvSeqPtrHistory{snrIdx} = rvSeqPtrHistory;
    
end

% Plot the RV sequence for all HARQ processes
hPlotRVSequence(SNRIn,allRvSeqPtrHistory,NFrames);

%% RV Sequence Pointer Plots
% The code above also generates plots with the value of the pointers to the
% elements in the RV sequence for the simulated subframes. This provides an
% idea of the retransmissions required. We plot the pointers and note the
% RV values used in case these are not organized in ascending order. For
% example, in some cases the RV sequence can be [0, 2, 3, 1]. Plotting
% these values as they are used will not provide a clear idea of the number
% of retransmissions needed.
% 
% When transmitting a new transport block, the first element of the RV
% sequence is used. In the plots above a value of 1 is shown for that
% subframe. This is the case at the beginning of the simulation. If a
% retransmission is required, the next element in the RV sequence is
% selected and the pointer is increased. A value of 2 will be plotted for
% the subframe where the retransmission takes place. If further
% retransmissions are required, the pointer value will increase further.
% Note that the plots do not show any value in subframe 5 of consecutive
% frames. This is because no data is transmitted in those subframes.
%
% The figure shown below was obtained simulating 10 frames. Note how in
% some cases up to 3 retransmissions are required.
%
% <<10FramesRVSeqPointer.jpg>>

%% Throughput Results
% The throughput results for the simulation are displayed in the MATLAB(R)
% command window after each SNR point is completed. They are also captured
% in |simThroughput| and |maxThroughput|. |simThroughput| is an array with
% the measured throughput in number of bits for all simulated SNR points.
% |maxThroughput| stores the maximum possible throughput in number of bits
% for each simulated SNR point.

% Plot throughput
figure
plot(SNRIn, simThroughput*100./maxThroughput,'*-.');
xlabel('SNR (dB)');
ylabel('Throughput (%)');
legend(legendString,'Location','NorthWest');
grid on;

%%
% The generated plot has been obtained with a low number of frames,
% therefore the results shown are not representative. A longer simulation
% obtained with 1000 frames produced the results shown below.
%
% <<TM4throughout1000frames.png>>

%% Appendix
% This example uses the helper functions:
%
% * <matlab:edit('hDisplayENBParameterSummary.m') hDisplayENBParameterSummary.m>
% * <matlab:edit('hHARQScheduling.m') hHARQScheduling.m>
% * <matlab:edit('hNewHARQProcess.m') hNewHARQProcess.m>
% * <matlab:edit('hPlotRVSequence.m') hPlotRVSequence.m>

%% Selected Bibliography
% # 3GPP TS 36.101 "User Equipment (UE) radio transmission and reception"

displayEndOfDemoMessage(mfilename)
