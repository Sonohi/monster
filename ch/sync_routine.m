function offset  = sync_routine(Stations,Users, Channel, Param,ChannelEstimator)

% Initial association.

% check which UEs are associated to which eNB
[Users, Stations] = refreshUsersAssociation(Users, Stations, Param);

% Generate dummy data for all stations, e.g. one full frame
for i = 1:length(Stations)
    [Stations(i).TxWaveform, Stations(i).WaveformInfo, Stations(i).ReGrid] = generate_dummy_frame(Stations(i));
    Stations(i).WaveformInfo.OfdmEnergyScale = 1; % Full RB is used, so scale is set to one
end

% Traverse channel 
[Stations, Users] = Channel.traverse(Stations,Users);
    
% Compute offset
%% Synchronization
% The offset caused by the channel in the received time domain signal is
% obtained using <matlab:doc('lteDLFrameOffset') lteDLFrameOffset>. This
% function returns a value |offset| which indicates how many samples the
% waveform has been delayed. The offset is considered identical for
% waveforms received on all antennas. The received time domain waveform can
% then be manipulated to remove the delay using |offset|.
for p = 1:length(Users)
   iSStation = find([Stations.NCellID] == Users(p).ENodeB);
    
   offset(p) = lteDLFrameOffset(struct(Stations(iSStation)), Users(p).RxWaveform); 
   rxWaveform = Users(p).RxWaveform(1+offset(p):end,:);



    %% OFDM Demodulation
    % The time domain waveform undergoes OFDM demodulation to transform it to
    % the frequency domain and recreate a resource grid. This is accomplished
    % using <matlab:doc('lteOFDMDemodulate') lteOFDMDemodulate>. The resulting
    % grid is a 3-dimensional matrix. The number of rows represents the number
    % of subcarriers. The number of columns equals the number of OFDM symbols
    % in a subframe. The number of subcarriers and symbols is the same for the
    % returned grid from OFDM demodulation as the grid passed into
    % <matlab:doc('lteOFDMModulate') lteOFDMModulate>. The number of planes
    % (3rd dimension) in the grid corresponds to the number of receive
    % antennas.

    rxGrid = lteOFDMDemodulate(struct(Stations(iSStation)),rxWaveform);

    %% Channel Estimation
    % To create an estimation of the channel over the duration of the
    % transmitted resource grid <matlab:doc('lteDLChannelEstimate')
    % lteDLChannelEstimate> is used. The channel estimation function is
    % configured by the structure |cec|. <matlab:doc('lteDLChannelEstimate')
    % lteDLChannelEstimate> assumes the first subframe within the resource grid
    % is subframe number |enb.NSubframe| and therefore the subframe number must
    % be set prior to calling the function. In this example the whole received
    % frame will be estimated in one call and the first subframe within the
    % frame is subframe number 0. The function returns a 4-D array of complex
    % weights which the channel applies to each resource element in the
    % transmitted grid for each possible transmit and receive antenna
    % combination. The possible combinations are based upon the eNodeB
    % configuration |enb| and the number of receive antennas (determined by the
    % size of the received resource grid). The 1st dimension is the subcarrier,
    % the 2nd dimension is the OFDM symbol, the 3rd dimension is the receive
    % antenna and the 4th dimension is the transmit antenna. In this example
    % one transmit and one receive antenna is used therefore the size of
    % |estChannel| is 180-by-140-by-1-by-1.

    enb.NSubframe = 0;
    [estChannel, noiseEst] = lteDLChannelEstimate(struct(Stations(iSStation)),ChannelEstimator,rxGrid);


    %constDiagram = comm.ConstellationDiagram('SamplesPerSymbol',1, ...
    %    'SymbolsToDisplaySource','Property','SymbolsToDisplay',600);
    % rxGrid_r = reshape(rxGrid,length(rxGrid(:,1))*length(rxGrid(1,:)),1);
    % for i= 1:30:length(rxGrid_r)-30
    %     constDiagram(rxGrid_r(i:i+30))
    % end
    %% MMSE Equalization
    % The effects of the channel on the received resource grid are equalized
    % using <matlab:doc('lteEqualizeMMSE') lteEqualizeMMSE>. This function uses
    % the estimate of the channel |estChannel| and noise |noiseEst| to equalize
    % the received resource grid |rxGrid|. The function returns |eqGrid| which
    % is the equalized grid. The dimensions of the equalized grid are the same
    % as the original transmitted grid (|txGrid|) before OFDM modulation.

    eqGrid = lteEqualizeMMSE(rxGrid, estChannel, noiseEst);
    %eqGrid_r = reshape(eqGrid,length(eqGrid(:,1))*length(eqGrid(1,:)),1);
    %for i= 1:30:length(eqGrid_r)-30
    %    constDiagram(eqGrid_r(i:i+30))
    %end

    %constDiagram(reshape(eqGrid,length(eqGrid(:,1))*length(eqGrid(1,:)),1))

    %% Analysis
    % The received resource grid is compared with the equalized resource grid.
    % The error between the transmitted and equalized grid and transmitted and
    % received grids are calculated. This creates two matrices (the same size
    % as the resource arrays) which contain the error for each symbol. To allow
    % easy inspection the received and equalized grids are plotted on a
    % logarithmic scale using <matlab:doc('surf') surf> within
    % <matlab:edit('hDownlinkEstimationEqualizationResults.m')
    % hDownlinkEstimationEqualizationResults.m>. These diagrams show that
    % performing channel equalization drastically reduces the error in the
    % received resource grid.

    % Calculate error between transmitted and equalized grid
    %txGrid = Stations(iSStation).ReGrid;
    %eqError = txGrid - eqGrid;
    %rxError = txGrid - rxGrid;

    % Compute EVM across all input values
    % EVM of pre-equalized receive signal
    %EVM = comm.EVM;
    %EVM.AveragingDimensions = [1 2];
    %preEqualisedEVM = EVM(txGrid,rxGrid);
    %fprintf('Percentage RMS EVM of Pre-Equalized signal: %0.3f%%\n', ...
    %        preEqualisedEVM); 
    % EVM of post-equalized receive signal
    %postEqualisedEVM = EVM(txGrid,eqGrid);
    %fprintf('Percentage RMS EVM of Post-Equalized signal: %0.3f%%\n', ...
    %        postEqualisedEVM); 

    % Plot the received and equalized resource grids 
    %hDownlinkEstimationEqualizationResults(rxGrid, eqGrid);

   
end

   

end


function [txWaveform, info, txGrid] = generate_dummy_frame(enb)
    
    %% Subframe Resource Grid Size
    % In this example it is useful to have access to the subframe resource grid
    % dimensions. These are determined using
    % <matlab:doc('lteDLResourceGridSize') lteDLResourceGridSize>. This
    % function returns an array containing the number of subcarriers, number of
    % OFDM symbols and number of transmit antenna ports in that order.

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
        
        % Append subframe to grid to be transmitted
        txGrid = [txGrid subframe]; %#ok
        
    end
    
    [txWaveform,info] = lteOFDMModulate(enb,txGrid);
    

end