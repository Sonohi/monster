classdef WINNER2Channel < matlab.System
%WINNER2Channel Filter input signal(s) through a WINNER II fading channel
%   CHAN = comm.WINNER2Channel creates a WINNER II fading channel System
%   object, CHAN, to model single or multiple links. This object generates
%   channel coefficients using the WINNER II spatial channel model. It also
%   filters a real or complex input signal through the fading channel for
%   each link.
% 
%   CHAN = comm.WINNER2Channel(Name,Value) creates a WINNER II fading
%   channel object, CHAN, with the specified property Name set to the
%   specified Value. You can specify additional name-value pair arguments
%   in any order as (Name1,Value1,...,NameN,ValueN).
%  
%   CHAN = comm.WINNER2Channel(CFGMODEL) creates a WINNER II fading channel
%   object, CHAN, with the ModelConfig property set to CFGMODEL.
%
%   CHAN = comm.WINNER2Channel(CFGMODEL,CFGLAYOUT) creates a WINNER II
%   fading channel object, CHAN, with the ModelConfig property set to
%   CFGMODEL and the LayoutConfig property set to CFGLAYOUT.
% 
%   Step method syntax:
%
%   Y = step(CHAN,X) filters input signal X through a WINNER II fading
%   channel and returns the result in Y. The input X must be a NL x 1 cell
%   array, where NL is the number of links determined from the LayoutConfig
%   property of CHAN. The i'th element of X must be a double precision data
%   type, Ns x Nt(i) matrix. Ns represents the number of samples to be
%   generated and must be the same for all elements of X. Nt(i) is the
%   number of transmit antennas at the base station (BS) for the i'th link,
%   determined by the LayoutConfig property of CHAN. When there is only one
%   link or all the links have the same number of transmit antennas, X can
%   also be a double precision data type, Ns x Nt matrix. In this case, the
%   same input signal is being filtered through all the links. The output Y
%   is a NL x 1 cell array. The i'th element of Y is a double precision
%   data type, Ns x Nr(i) complex matrix, where Nr(i) is the number of
%   receive antennas at the mobile station (MS) for the i'th link,
%   determined by the LayoutConfig property of CHAN.
% 
%   [Y,PATHGAINS] = step(CHAN,X) returns the WINNER II channel coefficients
%   PATHGAINS generated using the spatial channel model. PATHGAINS is a NL
%   x 1 cell array. The i'th element of PATHGAINS is a double precision
%   data type, Nr(i) x Nt(i) x Np(i) x Ns complex array. Np(i) is the
%   number of paths for the i'th link.
% 
%   System objects may be called directly like a function instead of using
%   the step method. For example, y = step(obj, x) and y = obj(x) are
%   equivalent.
%  
%   Notes on algorithms: 
% 
%   1). When Ns and ModelConfig.NumTimeSamples do not match, the former
%   overwrites the latter and determines the number of samples to be
%   generated. 
% 
%   2). The object uses ModelConfig.DelaySamplingInterval = 0 to obtain the
%   original path delays (not rounded to be multiples of
%   ModelConfig.DelaySamplingInterval) when performing channel filtering.
%   Any non-zero value of ModelConfig.DelaySamplingInterval is ignored.
%  
%   3). The signal sample rate for generating channel coefficients and
%   performing channel filtering is calculated per link by MSSpeed/
%   (2.99792458e8/ModelConfig.CenterFrequency/2/ModelConfig.SampleDensity).
%   When ModelConfig.UniformTimeSampling is set to 'no', MSSpeed is the
%   non-directional speed of the MS for the corresponding link, derived
%   from the LayoutConfig.Stations.Velocity field. When
%   ModelConfig.UniformTimeSampling is set to 'yes', MSSpeed is the maximum
%   speed of the MS for all links. The sample rate for each link is
%   available as a field in the info method return.
%    
%   WINNER2Channel methods:
%
%   step     - Filter input signals through a WINNER II channel (see above)
%   release  - Allow property value and input characteristics changes
%   clone    - Create WINNER II channel object with same property values
%   isLocked - Locked status (logical)
%   reset    - Reset filter states, and random stream if
%              ModelConfig.RandomSeed is not empty.
%   info     - Return characteristic information about the WINNER II channel
%
%   WINNER2Channel properties:
%   
%   ModelConfig             - WINNER II model parameter configuration
%   LayoutConfig            - WINNER II layout parameter configuration
%   NormalizeChannelOutputs - Normalize channel outputs (logical)
%   
%   % Example: Simulate a system that has two MS connected to one BS. One
%   % MS is 8 meters away from the BS; the other is 20 meters away from the
%   % BS. Impulse signals are sent through the two links. The spectrum of
%   % the received signals at MS shows frequency selectivity. It also shows
%   % the MS that is closer to the BS has a larger average received power 
%   % than the other MS. 
%   
%   rng(100);        % For repeatability
%   frmLen = 1024;   % Frame length
%   
%   % Configure layout parameters
%   BSAA  = winner2.AntennaArray('UCA', 8, 0.02);  % UCA-8 array for BS
%   MSAA1 = winner2.AntennaArray('ULA', 2, 0.01);  % ULA-2 array for MS
%   MSAA2 = winner2.AntennaArray('ULA', 4, 0.005); % ULA-4 array for MS
%   MSIdx = [2 3]; BSIdx = {1}; NL = 2; maxRange = 100; rndSeed = 101;
%   cfgLayout = winner2.layoutparset(MSIdx, BSIdx, ...
%       NL, [BSAA,MSAA1,MSAA2], maxRange, rndSeed);
% 
%   % Adjust BS and MS positions
%   cfgLayout.Stations(1).Pos(1:2) = [10, 10];
%   cfgLayout.Stations(2).Pos(1:2) = [18, 10];  % 8 meters away from BS
%   cfgLayout.Stations(3).Pos(1:2) = [22, 26];  % 20 meters away from BS
%
%   % NLOS for both links
%   cfgLayout.Pairing = [1 1; 2 3];
%   cfgLayout.PropagConditionVector = [0 0];    
% 
%   % Configure model parameters
%   cfgModel = winner2.wimparset;
%   cfgModel.NumTimeSamples     = frmLen; % Frame length
%   cfgModel.IntraClusterDsUsed = 'no';   % No cluster splitting
%   cfgModel.SampleDensity      = 2e5;    % For lower sample rate
%   cfgModel.PathLossModelUsed  = 'yes';  % Turn on path loss
%   cfgModel.ShadowingModelUsed = 'yes';  % Turn on shadowing  
%  
%   % Create a WINNER II channel System object
%   wimChan = comm.WINNER2Channel(cfgModel, cfgLayout);
%   
%   % Call the info method of the object to get some system information
%   chanInfo = info(wimChan)
%   numTx    = chanInfo.NumBSElements(1);
%   Rs       = chanInfo.SampleRate(1);
% 
%   % Create a Spectrum Analyzer System object
%   SA = dsp.SpectrumAnalyzer( ...
%       'SampleRate',   Rs, ...
%       'YLimits',      [-180, -100], ...
%       'ShowLegend',   true, ...
%       'ChannelNames', {'MS 1 (8 meters away)','MS 2 (20 meters away)'});
%
%   % Pass impulse signals through the two links and show spectra of the
%   % received signals at the two MS
%   for i = 1:10
%       x = [ones(1, numTx); zeros(frmLen-1, numTx)]; 
%       y = wimChan(x);
%       SA([y{1}(:,1), y{2}(:,1)]);
%   end
%   
%   References: 
%   [1] IST WINNER II, "WINNER II Channel Models", D1.1.2, Sep. 2007.
% 
%   See also winner2.AntennaArray, comm.MIMOChannel, comm.RayleighChannel,
%   comm.RicianChannel, winner2.layoutparset, winner2.wim,
%   winner2.wimparset.

% Copyright 2016 The MathWorks, Inc.

properties(Nontunable)
    %ModelConfig Model configuration
    %   Specify the WINNER II model parameters in a structure. Refer to
    %   <a href="matlab: help('winner2.wimparset')">winner2.wimparset</a> for the parameters (structure fields) and 
    %   their default values.
    ModelConfig = comm.WINNER2Channel.getModelConfigDefault;
    %LayoutConfig Layout configuration
    %   Specify the WINNER II layout parameters in a structure. Refer to
    %   <a href="matlab: help('winner2.layoutparset')">winner2.layoutparset</a> for the parameters (structure fields). The     
    %   default configuration is for a single-link system from a 2-antenna
    %   base station (BS) to a 2-antenna mobile station (MS) which is 60
    %   meters apart, in the A1 (indoor office) line-of-sight (LOS)
    %   scenario. The signal sample rate is 100 MHz by default.
    LayoutConfig = comm.WINNER2Channel.getLayoutConfigDefault
end
  
properties (Nontunable, Logical)
    %NormalizeChannelOutputs Normalize outputs by number of receive antennas
    %   Set this property to true to normalize the channel outputs by the
    %   number of receive antennas at the mobile station (MS) for each
    %   link. The default value of this property is true.
    NormalizeChannelOutputs = true
end

properties (Access = private, Nontunable)
    % Same as ModelConfig, except that 
    %   pModelConfig.NumTimeSamples        = Ns
    %   pModelConfig.DelaySamplingInterval = 0
    pModelConfig        % Struct
    % Signal sample rate for each link
    pSampleRate         % [1 NL]
    % Number of links/users (1 in default config)
    pNumLinks           % Scalar
    % Number of transmit antennas (2 in default config)
    pNumTx              % [1 NL]
    % Number of receive antennas (2 in default config)
    pNumRx              % [1 NL]
    % Number of *true* paths for each link
    pNumPaths           % [1 NL]
    % Number of samples for all links
    pNumSamp            % Scalar 
    % Number of channel taps for each link
    pNumChannelTaps     % [1 NL]
    % Range of channel taps for each link
    pTapIdxRange        % [2 NL]
    % Channel filter delay for each link
    pChannelFilterDelay % [1 NL]
    % Constant path delay or not for all links
    pIsConstPathDelay   % [1 NL] logical
end
  
properties (Access = private)
    % Channel filter tap gain sinc interpolation matrix
    pSincInterpMatrix       % [1 NL] cell, [NP numTaps] for each element
    % State for path gain generation using 'wim' function
    pPGState                % struct
    % Channel filter state, for frequency-selective fading only
    pChannelFilterState     % [1 NL] cell, [numTaps Nt NP] for each element
    % Number of input samples that have been processed since the last reset
    pNumSampProcessed = 0   % Scalar
end

methods
  function obj = WINNER2Channel(varargin) 
    registerrealtimecataloglocation(winner2.internal.resourceRoot);
    setProperties(obj, nargin, varargin{:}, 'ModelConfig', 'LayoutConfig');
  end
  
  function set.ModelConfig(obj, cfgModel)
    % Validate the structure before assigning
    winner2.internal.validateWimConfig(cfgModel);
    
    obj.ModelConfig = cfgModel;
  end
  
  function set.LayoutConfig(obj, cfgLayout)
    % Perform individual field checking on layout config. Cross-field
    % checking will happen in validatePropertiesImpl.
    winner2.internal.validateLayoutConfig(cfgLayout, true, false);
    
    obj.LayoutConfig = cfgLayout;    
  end
end    
  
methods(Access = protected)      
  function validatePropertiesImpl(obj)
    % Perform cross-field checking on layout config
    winner2.internal.validateLayoutConfig(obj.LayoutConfig, false, true);
    
    % Need to know # Tx & Rx to validate signal input size 
    getNumTxAndRx(obj);
  end
  
  function validateInputsImpl(obj, x) 
    if isa(x, 'cell')
        % This method only locks the top-level NL x 1 cell array. Each
        % element of the cell array has to be checked and locked in the
        % stepImpl after the first step call.
        validateattributes(x, {'cell'}, {'column','numel',obj.pNumLinks}, ... 
            [class(obj) '.Signal input'], 'the cell array signal input');
        validateCellContents(obj, x);
    else
        % The input signal can also be a 2D matrix for a single-link setup
        % or when all links have the same number of Tx
        Nt = obj.pNumTx;
        coder.internal.errorIf(~isscalar(unique(Nt)), ...
            'winner2:WINNER2Channel:DiffNumTxFor2DInput');
        validateattributes(x, {'double'}, ...
            {'2d','finite','nonempty','ncols',Nt(1)}, ...
            [class(obj) '.Signal input'], 'the matrix signal input'); 
        obj.pNumSamp = size(x, 1);
    end
  end
    
  function setupImpl(obj, ~)
    % Re-config private ModelConfig 
    obj.pModelConfig = obj.ModelConfig;

    % Input length overwrites ModelConfig.NumTimeSamples if not equal
    if obj.pNumSamp ~= obj.pModelConfig.NumTimeSamples
        coder.internal.warning( ...
            'winner2:WINNER2Channel:InputLenNotMatchNumTimeSamples');
        obj.pModelConfig.NumTimeSamples = obj.pNumSamp;
    end
    
    % Get signal sample rate, initial path delays and derive number of
    % paths for each link
    pathDelays = getSampleRateAndPathDelays(obj);
    
    % Get sinc interpolation matrices (for constant path delays) and number
    % of taps for each link
    setupChannelFilter(obj, pathDelays);
  end
    
  function resetImpl(obj)
    obj.pChannelFilterState = cellfun(@(x,y,z) complex(zeros(x,y,z)), ...
        num2cell(obj.pNumChannelTaps - 1), ...
        num2cell(obj.pNumTx), ...
        num2cell(obj.pNumPaths), 'UniformOutput', false);
    
    obj.pNumSampProcessed = 0;
  end
    
  function [y, g] = stepImpl(obj, x)
    % Generate channel coefficients
    if obj.pNumSampProcessed == 0
        [g, D, obj.pPGState] = winner2.internal.wim( ...
            obj.pModelConfig, obj.LayoutConfig);
    else
        [g, D, obj.pPGState] = winner2.internal.wim( ...
            obj.pModelConfig, obj.LayoutConfig, obj.pPGState);        
        
        if iscell(x) 
            % Do not need to validate x in the first step call as it has
            % been done in validateInputsImpl
            validateCellContents(obj, x);  
        end
    end
    
    % Perform channel filtering
    y = channelFilter(obj, x, g, D);
    
    % Postprocessing - output normalization
    if obj.NormalizeChannelOutputs
       % Normalize by the number of receive antennas so that the total
       % output power is equal to the total input power
       y = cellfun(@rdivide, y, num2cell(sqrt(obj.pNumRx')), ...
           'UniformOutput', false);
    end

    % Update number of samples processed
    obj.pNumSampProcessed = obj.pNumSampProcessed + obj.pNumSamp;
  end

  function releaseImpl(obj)
    obj.pNumSampProcessed = 0;
  end
  
  function num = getNumInputsImpl(~)
    num = 1;
  end
    
  function num = getNumOutputsImpl(~)
    num = 2;
  end
  
  function flag = isInputSizeLockedImpl(~,~)
    flag = true;
  end
  
  function flag = isInputComplexityLockedImpl(~,~)
    flag = false;
  end
   
  function flag = isOutputComplexityLockedImpl(~,~)
    flag = true;
  end
  
  function flag = isInactivePropertyImpl(~,~)
    flag = false;
  end
    
  function s = infoImpl(obj)
    %info Returns characteristic information about the WINNER II channel
    %   S = info(CHAN) returns a structure S containing characteristic
    %   information about the MIMO fading channel. A description of the
    %   fields and their values is as follows:
    %     
    %   Numlinks            - Number of links in the system
    %   NumBSElements       - Number of transmit antennas at BS for each link
    %   NumMSElements       - Number of receive antennas at MS for each link
    %   NumPaths            - Number of delay paths for each link  
    %   SampleRate          - Sample rate for each link
    %   ChannelFilterDelay  - Channel filter delay per link, measured in samples 
    %   NumSamplesProcessed - Number of samples the channel has processed 
    %                         since the last reset
    
    if ~isLocked(obj)
        validatePropertiesImpl(obj);
        obj.pModelConfig = obj.ModelConfig;
        pathDelays = getSampleRateAndPathDelays(obj);
        setupChannelFilter(obj, pathDelays);
    end
    
    s = struct( ...
        'NumLinks',            obj.pNumLinks, ...
        'NumBSElements',       obj.pNumTx, ...
        'NumMSElements',       obj.pNumRx, ...           
        'NumPaths',            obj.pNumPaths, ...
        'SampleRate',          obj.pSampleRate, ...
        'ChannelFilterDelay',  obj.pChannelFilterDelay, ...
        'NumSamplesProcessed', obj.pNumSampProcessed);
  end
  
  function s = saveObjectImpl(obj)
    s = saveObjectImpl@matlab.System(obj);
    if isLocked(obj)
        s.pModelConfig        = obj.pModelConfig;
        s.pSampleRate         = obj.pSampleRate;
        s.pNumLinks           = obj.pNumLinks;
        s.pNumTx              = obj.pNumTx;             
        s.pNumRx              = obj.pNumRx;            
        s.pNumPaths           = obj.pNumPaths;             
        s.pNumSamp            = obj.pNumSamp;            
        s.pNumChannelTaps     = obj.pNumChannelTaps;             
        s.pTapIdxRange        = obj.pTapIdxRange;
        s.pChannelFilterDelay = obj.pChannelFilterDelay;
        s.pIsConstPathDelay   = obj.pIsConstPathDelay;            
        s.pSincInterpMatrix   = obj.pSincInterpMatrix;             
        s.pPGState            = obj.pPGState;            
        s.pChannelFilterState = obj.pChannelFilterState;             
        s.pNumSampProcessed   = obj.pNumSampProcessed;            
    end
  end
  
  function loadObjectImpl(obj, s, wasLocked)
    if wasLocked
        obj.pModelConfig        = s.pModelConfig;
        obj.pSampleRate         = s.pSampleRate;
        obj.pNumLinks           = s.pNumLinks;
        obj.pNumTx              = s.pNumTx;
        obj.pNumRx              = s.pNumRx;
        obj.pNumPaths           = s.pNumPaths;
        obj.pNumSamp            = s.pNumSamp;
        obj.pNumChannelTaps     = s.pNumChannelTaps;
        obj.pTapIdxRange        = s.pTapIdxRange;
        obj.pChannelFilterDelay = s.pChannelFilterDelay;
        obj.pIsConstPathDelay   = s.pIsConstPathDelay;
        obj.pSincInterpMatrix   = s.pSincInterpMatrix;
        obj.pPGState            = s.pPGState;
        obj.pChannelFilterState = s.pChannelFilterState;
        obj.pNumSampProcessed   = s.pNumSampProcessed;
    end
    loadObjectImpl@matlab.System(obj, s);
  end    
end
  
methods(Access = private)
  function validateCellContents(obj, x)
    for idxNL = 1:obj.pNumLinks
        validateattributes(x{idxNL}, {'double'}, ...
            {'2d','finite','nonempty','ncols',obj.pNumTx(idxNL)}, ...
            [class(obj) '.Signal input'], ...
            ['the signal input for the link ', num2str(idxNL)]);
    end

    % Input signals must have the same length across links
    Ns = cellfun('size', x, 1);
    coder.internal.errorIf(~isscalar(unique(Ns)), ...
        'winner2:WINNER2Channel:DiffFrmLenAcrossLinks');

    if obj.pNumSampProcessed == 0 % First step call
        obj.pNumSamp = Ns(1);
    else
        coder.internal.errorIf(obj.pNumSamp ~= Ns(1), ...
            'winner2:WINNER2Channel:VaryingNumSamp')
    end
  end

  function pathDelays = getSampleRateAndPathDelays(obj)
    % Extended configurations
    cfgLink = winner2.internal.layout2Link(obj.LayoutConfig);
    cfgFix  = winner2.internal.getScenarioParam(cfgLink.StreetWidth(1));         
    
    % Random number streams
    if ~isempty(obj.pModelConfig.RandomSeed)
        uniStream  = RandStream('v5uniform', ...
            'Seed', obj.pModelConfig.RandomSeed);
        normStream = RandStream('v5normal', ...
            'Seed', obj.pModelConfig.RandomSeed);
    else
        uniStream  = RandStream.getGlobalStream;
        normStream = RandStream.getGlobalStream;
    end
    
    % Calculate sample rate for each link
    if strcmp(obj.ModelConfig.UniformTimeSampling, 'yes')
        velocity = max(cfgLink.MsVelocity)*ones(1, obj.pNumLinks);
    else 
        velocity = cfgLink.MsVelocity;
    end
    coder.internal.errorIf(any(velocity == 0), ...
        'winner2:WINNER2Channel:ZeroMSVelocity');
    waveLength = physconst('LightSpeed')/obj.ModelConfig.CenterFrequency;
    obj.pSampleRate = velocity/(waveLength/2/obj.ModelConfig.SampleDensity); % [1 NL]      
    
    % Get path delays and number of paths for each link. 
    obj.pModelConfig.DelaySamplingInterval = 0; % To get "true" path delays
    bulkpar = winner2.internal.generateBulkParam( ...
        obj.pModelConfig, cfgLink, cfgFix, uniStream, normStream);
    
    numValidPaths = sum(~isnan(bulkpar.delays), 2).'; % [1 NL]
    pathDelays = bulkpar.delays;
    
    % Cases when the path delay values and dims stay constant:
    %    1). cfgModel.IntraClusterDsUsed == 'no' (for all links)
    %    2). cfgLink.ScenarioVector in [7, 9] inclusive (per link)
    obj.pIsConstPathDelay = ...
        strcmp(obj.pModelConfig.IntraClusterDsUsed, 'no') | ...
        ((cfgLink.ScenarioVector >= 7)  & (cfgLink.ScenarioVector <= 9));
    
    % Update number of paths to account for cluster splitting
    obj.pNumPaths = numValidPaths + (~obj.pIsConstPathDelay) * 4;
  end
  
  function [interpMtx, tapIdxRange] = calcSincInterpMatrix(obj, pathDelays, idxNL)
    err1 = 0.1;         % Small value
    c = 1/(pi*err1);    % Based on bound sinc(x) < 1/(pi*x)
    err2 = 0.01;
    
    % Initial estimate of tap index range
    tRatio = (pathDelays * obj.pSampleRate(idxNL)).';
    tapIdx = min(floor(min(tRatio) - c), 0) : ceil(max(tRatio) + c);

    % Pre-compute channel filter tap gain sinc interpolation matrix
    A = sinc(tRatio - tapIdx);

    % The following steps ensure that the tap index vector is shortened
    % when tRatio values are close to integer values
    maxA = max(abs(A), [], 1);
    significantIdx = find(maxA > (err2 * max(maxA)));

    % Update tap index range
    t1 = min(tapIdx(significantIdx(1)), 0);
    t2 = tapIdx(significantIdx(end));
    tapIdxRange = [t1, t2];
    
    % Set up channel filter tap gain sinc interpolation matrix, [NP, nTaps]
    interpMtx = sinc(tRatio - (t1:t2));
  end
  
  function setupChannelFilter(obj, pathDelays)
    NL = obj.pNumLinks;
    NP = obj.pNumPaths;
    
    obj.pSincInterpMatrix = cell(1, NL);
    obj.pTapIdxRange = zeros(2,NL);
    for idxNL = 1:NL
        if obj.pIsConstPathDelay(idxNL)
            [obj.pSincInterpMatrix{idxNL}, obj.pTapIdxRange(:,idxNL)] = ...
                calcSincInterpMatrix(obj, pathDelays(idxNL,1:NP(idxNL)), idxNL);
        else
            % Remove the 4 splitted paths that do not exist yet. The
            % maximum delay can extend up to 10e-9 seconds because of
            % cluster splitting (most powerful two paths are split into
            % three subpaths each at time 0, 5e-9 and 10e-9). Assume the
            % last path gets split (the worst case in terms of number of
            % channel taps) and we use that to calculate tap indices. 
            extPathDelays = [pathDelays(idxNL,1:NP(idxNL)-4), ...
                             pathDelays(idxNL,NP(idxNL)-4) + 5e-9, ...
                             pathDelays(idxNL,NP(idxNL)-4) + 10e-9];
            [~, obj.pTapIdxRange(:,idxNL)] = ...
                calcSincInterpMatrix(obj, extPathDelays, idxNL);
        end
        
        obj.pNumChannelTaps(idxNL) = diff(obj.pTapIdxRange(:,idxNL)) + 1;
        
        if obj.pNumChannelTaps(idxNL) > 1200
            coder.internal.warning( ...
                'winner2:WINNER2Channel:ExcessiveChanFiltLen', idxNL, 400);
        end   
    end
    
    % Log channel filter delay for each link
    obj.pChannelFilterDelay = ...
        round(pathDelays(:,1)' .* obj.pSampleRate) - obj.pTapIdxRange(1,:);
  end
    
  function y = channelFilter(obj, x, H, D)
    NL = obj.pNumLinks; 
    Ns = obj.pNumSamp;  
    
    y = cell(NL, 1);
    for idxNL = 1:NL % Calculate channel output per link        
        Nt = obj.pNumTx(idxNL);
        Nr = obj.pNumRx(idxNL);
        NP = obj.pNumPaths(idxNL);
        
        % Get H and X ready for this link
        if iscell(x)
            thisX = x{idxNL};
        else
            thisX = x;
        end
        thisH = permute(H{idxNL}, [4 1 2 3]); % [Ns Nr Nt NP]
        
        % Read or re-construct sinc interpolation matrix
        if obj.pIsConstPathDelay(idxNL) 
            sincInterpMtx = obj.pSincInterpMatrix{idxNL}; % [NP nTaps]
        else
            % Calculate sinc interpolation matrix for current path delays
            tRatio = D(idxNL,1:NP) * obj.pSampleRate(idxNL);
            tapIdx = obj.pTapIdxRange(1,idxNL):obj.pTapIdxRange(2,idxNL);
            sincInterpMtx = sinc(tRatio' - tapIdx); % [NP nTaps]
        end
        
        if obj.pNumChannelTaps(idxNL) == 1 % Frequency-flat fading
            % Note that NP could be larger than 1 in this case. For
            % example, when two paths are very close to each other, they
            % can be absorbed into one tap.
            z = reshape(thisH, [Ns*Nr*Nt, NP]); % [Ns*Nt*Nr NP]
            g = reshape(z * sincInterpMtx, Ns, Nr, []); % [Ns Nr Nt]
            y{idxNL} = sum(reshape(thisX, Ns, 1, []) .* g, 3);
        else % Frequency-selective fading
            filterState = obj.pChannelFilterState{idxNL}; % [numTaps Nt NP]
            % Note that conv((A*B), C) = A*conv(B, C). When B is a constant
            % matrix, right hand equation can have much faster
            % implementation than left-hand one by using 'filter' function.
            filterOut = coder.nullcopy(complex(zeros(Ns, Nt, NP)));
            for i = 1:NP
                [filterOut(:,:,i), filterState(:,:,i)] = ...
                    filter(sincInterpMtx(i, :), 1, thisX, ...
                    filterState(:,:,i), 1);
            end

            y{idxNL} = sum( ...
                reshape(thisH, Ns, Nr, Nt*NP) .* ...
                reshape(filterOut, Ns, 1, Nt*NP), 3);

            % Save filter state
            obj.pChannelFilterState{idxNL} = filterState;
        end
    end    
  end
        
  function getNumTxAndRx(obj)
    cfgLayout = obj.LayoutConfig;
    obj.pNumLinks = size(cfgLayout.Pairing, 2);
    obj.pNumTx = cellfun('length', ...
        {cfgLayout.Stations(cfgLayout.Pairing(1,:)).Element});
    obj.pNumRx = cellfun('length', ...
        {cfgLayout.Stations(cfgLayout.Pairing(2,:)).Element});
  end     
end

methods(Static, Hidden)
  function cfgModel = getModelConfigDefault(~)
    cfgModel = winner2.wimparset;
    cfgModel.DelaySamplingInterval = 0;
  end
  
  function cfgLayout = getLayoutConfigDefault
    % Load the pre-saved layout configuration for better performance. The
    % saved layout is calculated using the following commented-out script.
    configFile = fullfile(fileparts(mfilename('fullpath')), ...
        '+internal', 'LayoutConfigDefault.mat');
    cfgLayout = coder.load(configFile).cfgLayout;
    
    % Script to create the default LayoutConfig - it takes ~10 seconds
    % az = -180:179;
    % pattern(1,:,1,:) = winner2.dipole(az); 
    % BSAA = winner2.AntennaArray('UCA', 2, 0.02, 'FP-ECS', pattern, 'Azimuth', az);
    % MSAA = winner2.AntennaArray('ULA', 2, 0.01, 'FP-ECS', pattern, 'Azimuth', az);
    % cfgLayout = winner2.layoutparset(2, {1}, 1, [BSAA, MSAA], 200, 1);
    % cfgLayout.Stations(1).Pos(1:2)  = [100;100];
    % cfgLayout.Stations(2).Pos(1:2)  = [160;100];
    % cfgLayout.Stations(2).Velocity  = [physconst('LightSpeed')/52.5e9/.04;0;0];
    % cfgLayout.PropagConditionVector = 1;
  end  
end

methods(Static, Access = protected)
  function groups = getPropertyGroupsImpl
    params = matlab.system.display.Section(...
        'Title', 'Parameters',...
        'PropertyList', {'ModelConfig','LayoutConfig',...
                         'NormalizeChannelOutputs'});
    groups = params;
  end
end

end

% [EOF]