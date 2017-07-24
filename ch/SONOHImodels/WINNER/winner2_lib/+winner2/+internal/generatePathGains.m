function [H, finalCond] = generatePathGains(cfgWim, cfgLink, bulkpar, ...
    BsGain, BsGainLOS, MsGain, MsGainLOS, offsetTime)
%GENERATEPATHGAINS generates channel coefficients
% 
%   [H,FINALCOND] = GENERATEPATHGAINS(CFGWIM,CFGLINK,BULKPAR,BSGAIN,
%   BSGAINLOS,MSGAIN,MSGAINLOS,OFFSETTIME) implements the formula in [2,
%   Eq. 4.14, 4.17, 4.19].
%
%   Outputs:
%
%   H            - Channel coefficients cell array of size NLx1 
%   FINALCOND    - Output state = bulkpar input with updated states
%
%   Inputs:
%
%   CFGWIM       - WINNER II model parameters
%   CFGLINK      - WINNER II link parameters
%   BULKPAR      - Input state without cluster splitting
%   BSGAIN       - Interpolated antenna field pattern for BS. 
%                  Nt x 3 x maxNP x M for each link.
%   BSGAINLOS    - Interpolated antenna field pattern for BS LOS paths. 
%                  Nt x 3 for each link.
%   MSGAIN       - Interpolated antenna field pattern for MS. 
%                  Nr x 3 x maxNP x M for each link.
%   MSGAINLOS    - Interpolated antenna field pattern for MS LOS paths. 
%                  Nr x 3 for each link.
%   offsetTime   - Time offset added to the initial phase
%
%   Ref. [1]: 3GPP TR 25.996 v6.1.0 (2003-09)
%        [2]: D1.1.2 V1.2, "WINNER II channel models"

% Copyright 2016 The MathWorks, Inc.

P         = bulkpar.path_powers; 
NL        = size(P, 1);
maxNP     = size(P, 2);
nonB5Idx  = find((cfgLink.ScenarioVector < 7 | cfgLink.ScenarioVector > 9));
B5Idx     = setdiff(1:NL, nonB5Idx);
NP        = sum(~isnan(bulkpar.delays), 2).'; % Number of paths for each link before splitting 
finalCond = bulkpar;

% Perform path delay and power splitting for the two strongest paths
if strcmpi(cfgWim.IntraClusterDsUsed ,'yes') && ~isempty(nonB5Idx)
    numRaysPerSC = [10 6 4];          % Number of rays in each subcluster
    raysInSC1    = [1:8,19,20];       % 10 rays in subcluster 1
    raysInSC2    = [9:12,17,18];      % 6  rays in subcluster 2
    raysInSC3    = 13:16;             % 4  rays in subcluster 3
    powerPerSC   = [10/20 6/20 4/20]; % Power distribution in 3 subclusters
    delayPerSC   = (0:5:10) * 1e-9;   % Relative delays for 3 subclusters  
    
    % Initialization
    pathDelays       = nan(NL, maxNP + 4);
    pathPowers       = nan(NL, maxNP + 4);
    pathIdxToSplit   = zeros(NL, 2);
    pathToSubpathMap = zeros(NL, maxNP + 4);

    % Find two strongest paths to split
    P2 = P(nonB5Idx,:);
    P2(isnan(P2)) = -inf;
    [~, sortIdx] = sort(P2, 2); 
    pathIdxToSplit(nonB5Idx, :) = sort(sortIdx(:,end-1:end), 2);

    % Path delay and power stay the same for B5 scenarios
    D = bulkpar.delays;
    if ~isempty(B5Idx)
        pathDelays(B5Idx,1:maxNP) = D(B5Idx, :);
        pathPowers(B5Idx,1:maxNP) = P(B5Idx, :);
    end
    
   for i = 1:length(nonB5Idx)
        linkIdx = nonB5Idx(i);
        s1 = pathIdxToSplit(linkIdx, 1);
        s2 = pathIdxToSplit(linkIdx, 2);
        subPathIdx = [s1 + (0:2), s2 + (2:4)];

        % Path index mapping from pre- to post-splitting
        pathToSubpathMap(linkIdx, :) = [1:(s1-1), s1*ones(1,3), ...
            (s1+1):(s2-1), s2*ones(1,3), (s2+1):maxNP];
        
        % Split delays
        pathDelays(linkIdx, :) = D(linkIdx, pathToSubpathMap(linkIdx, :));                
        pathDelays(linkIdx, subPathIdx) = ...
           [D(linkIdx, s1) + delayPerSC, D(linkIdx, s2) + delayPerSC];
                          
        % Split powers
        pathPowers(linkIdx, :) = P(linkIdx, pathToSubpathMap(linkIdx, :)); 
        pathPowers(linkIdx, subPathIdx) = ...
           [P(linkIdx, s1) * powerPerSC, P(linkIdx, s2) * powerPerSC];        
    end
    P = reshape(pathPowers, [], 1, maxNP+4);
    NP(nonB5Idx) = NP(nonB5Idx) + 4; % 4 additional paths from splitting
    
    % Update states
    finalCond.delays              = pathDelays;
    finalCond.path_powers         = pathPowers;
    finalCond.IndexOfDividedClust = pathIdxToSplit;
else
    P = reshape(P, [], 1, maxNP); % [NL, 1, maxNP]
end

% Channel coefficient calculation
T = cfgWim.NumTimeSamples;      % Number of time samples
M = 20;                         % Number of rays per cluster
waveLength = physconst('LightSpeed')/cfgWim.CenterFrequency;
k_CONST = 2*pi/waveLength;      % Wave number
phasePerSec = cfgLink.MsVelocity' .* ...
    cos((bulkpar.aoas - cfgLink.MsDirection') * pi/180); % [NL, maxNP, M]

if strcmp(cfgWim.UniformTimeSampling, 'yes')
    velocity = max(cfgLink.MsVelocity)*ones(NL,1);
else 
    velocity = cfgLink.MsVelocity.';
end
deltaT = waveLength./velocity./2./cfgWim.SampleDensity ; % [NL, 1]

% Time axes for input links 
t = deltaT .* ((0:T-1) + offsetTime); % [NL, Ns]  

% Time axis generation for fixed feeder links (B5 scenarios)
% if ~isempty(B5Idx)
%     xxx Enable the following when B5 is supported
%     cfgLink.MsVelocity(B5LinkIdx) = zeros(length(B5LinkIdx), 1);
%     % not final 
%     % xxx What does this ("not final") mean?
%     timeVector = linspace(0, cfgWim.end_time, T);
%     % not final
%     
%     t(localB5LinkIdx,:) = repmat(timeVector, length(B5LinkIdx), 1);
%     deltaT(localB5LinkIdx) = timeVector(2) - timeVector(1); % Dummy value
% end

H = cell(NL,1);

if strcmpi(cfgWim.PolarisedArrays, 'no')    
    subpathPhase = ...
        reshape(bulkpar.subpath_phases, [], 1, maxNP, 1, M); % [NL, 1, maxNP, 1, M]

    for linkIdx = 1:NL 
        thisNP     = NP(linkIdx);
        thisBsGain = permute(BsGain{linkIdx}, [2 1 3 5 4]); % [3, Nt, maxNP, 1, M];
        thisMsGain = permute(MsGain{linkIdx}, [1 2 3 5 4]); % [Nr, 3, maxNP, 1, M];
        
        % Calculate Doppler frequency nu
        % if any(linkIdx == B5Idx)
        %     xxx Enable this when B5 is supported
        %     nu = bulkpar.scatterer_freq(linkIdx, :, :);
        % else
            nu = reshape(phasePerSec(linkIdx,:,:)/waveLength, ...
                [1 1 maxNP 1 M]); % [1 1 maxNP 1 M]
        % end
        
        numRays = M*ones(1, 1, thisNP);
        if strcmp(cfgWim.IntraClusterDsUsed ,'yes') && ~any(linkIdx == B5Idx)
            pathMap = pathToSubpathMap(linkIdx,:);
            thisBsGain = thisBsGain(:,:,pathMap,:,:);         % [3, Nt, maxNP+4, 1, M]
            thisMsGain = thisMsGain(:,:,pathMap,:,:);         % [Nr, 3, maxNP+4, 1, M]
            phase      = subpathPhase(linkIdx,:,pathMap,:,:); % [1,  1, maxNP+4, 1, M]
            nu         = nu(:,:,pathMap,:,:);                 % [1,  1, maxNP+4, 1, M]
            
            for i = 1:2 
                % Only making subpaths to be zero for one multipler in the
                % temp calculation is enough
                s = pathIdxToSplit(linkIdx, i) + 2*(i == 2);
                thisBsGain(:,:,s,  :,[raysInSC2, raysInSC3]) = 0;
                thisBsGain(:,:,s+1,:,[raysInSC1, raysInSC3]) = 0;
                thisBsGain(:,:,s+2,:,[raysInSC1, raysInSC2]) = 0;
                numRays(1, 1, s:s+2) = numRaysPerSC;
            end
        else
            phase = subpathPhase(linkIdx,:,:,:,:); % [1, 1, maxNP, 1, M]
        end
        
        % Break down the following for performance reason
        noTimeH = ...
            thisBsGain(1,:,1:thisNP,:,:) .* ...
            thisMsGain(:,1,1:thisNP,:,:) .* ...
            exp(1i * (phase(:,:,1:thisNP,:,:)*pi/180 + ...
            k_CONST * thisBsGain(3,:,1:thisNP,:,:) +...
            k_CONST * thisMsGain(:,3,1:thisNP,:,:))); % [Nt, Nr, NP, 1, M]

        thisH = applyTimeDim(noTimeH, t(linkIdx, :), nu, thisNP, T); % [Nt, Nr, NP, T]
        
        H{linkIdx} = sqrt(P(linkIdx,1,1:thisNP) ./ numRays) .* thisH;
    end
    
    subPathPhases = prin_value( ...
        k_CONST*phasePerSec.*deltaT*T*180/pi + ...
        bulkpar.subpath_phases);
else 
    r_n1 = reshape(1./bulkpar.xpr, ...
        [], 1, 1, maxNP, 1, M); % [NL, 1, 1, maxNP, 1, M]
    sqrtR = cat(3, ones(size(r_n1)), sqrt(r_n1), ...
                   sqrt(r_n1), ones(size(r_n1))); % [NL, 1, 4, maxNP, 1, M]

    subpathPhase = sqrtR .* exp(1i * ... % [NL, 1, 4, maxNP, 1, M]
        reshape(bulkpar.subpath_phases, [], 1, 4, maxNP, 1, M)*pi/180); 

    for linkIdx = 1:NL 
        thisNP = NP(linkIdx);
        thisBsGain = permute(BsGain{linkIdx}, [5 1 2 3 6 4]); % [1,  Nt, 3, maxNP, 1, M];
        thisMsGain = permute(MsGain{linkIdx}, [1 5 2 3 6 4]); % [Nr, 1,  3, maxNP, 1, M];
        
        % Calculate Doppler frequency nu
        % if any(linkIdx == B5Idx)
        %    xxx Enable this when B5 is supported
        %    nu = bulkpar.scatterer_freq(linkIdx, :, :);
        %else  
            nu = reshape(phasePerSec(linkIdx,:,:)/waveLength, ... 
                [1 1 maxNP 1 M]); % [1 1 maxNP 1 M]
        % end
        
        numRays = M*ones(1, 1, thisNP);
        if strcmp(cfgWim.IntraClusterDsUsed ,'yes') && ~any(linkIdx == B5Idx)
            pathMap = pathToSubpathMap(linkIdx,:);
            thisBsGain = thisBsGain(:,:,:,pathMap,:,:);         % [1, Nt, 3, maxNP+4, 1, M]
            thisMsGain = thisMsGain(:,:,:,pathMap,:,:);         % [Nr, 1, 3, maxNP+4, 1, M]
            phase      = subpathPhase(linkIdx,:,:,pathMap,:,:); % [1,  1, 4, maxNP+4, 1, M]
            nu         = nu(:,:,pathMap,:,:);                   % [1,  1, maxNP+4, 1, M]
            
            for i = 1:2 
                % Only making subpaths to be zero for one multipler in the
                % temp calculation is enough
                s = pathIdxToSplit(linkIdx, i) + 2*(i == 2);
                thisBsGain(:,:,:,s,  :,[raysInSC2, raysInSC3]) = 0;
                thisBsGain(:,:,:,s+1,:,[raysInSC1, raysInSC3]) = 0;
                thisBsGain(:,:,:,s+2,:,[raysInSC1, raysInSC2]) = 0;
                numRays(1, 1, s:s+2) = numRaysPerSC;
            end
        else
            phase = subpathPhase(linkIdx,:,:,:,:,:); % [1, 1, 4, maxNP, 1, M]
        end
        
        expBsGain = cat(3, thisBsGain(:,:,1,:,:,:), thisBsGain(:,:,1,:,:,:), ...
                           thisBsGain(:,:,2,:,:,:), thisBsGain(:,:,2,:,:,:));
        expMsGain = cat(3, thisMsGain(:,:,1,:,:,:), thisMsGain(:,:,2,:,:,:), ...
                           thisMsGain(:,:,1,:,:,:), thisMsGain(:,:,2,:,:,:));

        % Break down the following for performance reason
        noTimeH = ...
            expBsGain(:,:,:,1:thisNP,:,:,:) .* ...
            expMsGain(:,:,:,1:thisNP,:,:,:) .* ...
            phase(:,:,:,1:thisNP,:,:) .* ...
            exp(1i * (k_CONST * thisBsGain(:,:,3,1:thisNP,:,:) + ...
            k_CONST * thisMsGain(:,:,3,1:thisNP,:,:))); % [Nt, Nr, 4, NP, 1, M]
        noTimeH = reshape(sum(noTimeH, 3), ...
            size(noTimeH, 1), size(noTimeH, 2), thisNP, 1, M); % [Nt, Nr, NP, 1, M]
        
        thisH = applyTimeDim(noTimeH, t(linkIdx, :), nu, thisNP, T); % [Nt, Nr, NP, T]
         
        H{linkIdx} = sqrt(P(linkIdx,1,1:thisNP) ./ numRays) .* thisH;
    end

    subPathPhases = prin_value(reshape(k_CONST*phasePerSec.* ...
        deltaT*T*180/pi, NL, 1, [], M) + ... % [NL, 1, maxNP, M]
        bulkpar.subpath_phases);
end 

% Index to LOS but not B5 links
nonB5LOSIdx = intersect(find(bulkpar.propag_condition), nonB5Idx);
% xxx Enable this when B5 is supported
% B5LOSIdx = intersect(find(bulkpar.propag_condition), B5Idx);

% Apply K factor to the first path of LOS links
phiLOS = bulkpar.Phi_LOS;
if ~isempty(nonB5LOSIdx)
    phaseLOS = k_CONST * cfgLink.MsVelocity .* ...
            cos((cfgLink.ThetaMs - cfgLink.MsDirection)*pi/180);
    
    for i = 1:length(nonB5LOSIdx) % cycles links
        linkIdx = nonB5LOSIdx(i);
        K_factor = bulkpar.Kcluster(linkIdx);

        thisBsGainLOS = (BsGainLOS{linkIdx}).'; % [3 Nt]
        thisMsGainLOS = MsGainLOS{linkIdx};     % [Nr 3]
        thisT = reshape(t(linkIdx,:), 1, 1, 1, []);     % [1 1 1 Ns]
        
        temp = ...
            thisBsGainLOS(1,:) .* ...
            thisMsGainLOS(:,1) .* ...
            exp(1i* (k_CONST * thisBsGainLOS(3,:) + ...
            k_CONST * thisMsGainLOS(:,3) + ...
            bulkpar.Phi_LOS(linkIdx,1) * pi/180 + ...
            phaseLOS(linkIdx) .* thisT)); % [Nr, Nt, 1, Ns]
        
        H{linkIdx}(:,:,1,:) = ...
            sqrt(1/(K_factor+1)) * H{linkIdx}(:,:,1,:) + ...
            sqrt(K_factor/(K_factor+1)) * temp;
        H{linkIdx}(:,:,2:end,:) = sqrt(1/(K_factor+1)) * ...
            H{linkIdx}(:,:,2:end,:);        
    end 

    phiLOS(nonB5LOSIdx) = prin_value( phaseLOS(nonB5LOSIdx).' .* ...
        (deltaT(nonB5LOSIdx) + t(nonB5LOSIdx,end))*180/pi + ...
        phiLOS(nonB5LOSIdx));
    
    % Update states
    finalCond.Phi_LOS = phiLOS;    
end 

% xxx Update the following code when B5 is supported
% if ~isempty(B5LOSIdx)>0
% B5 links 
%   direct rays are added and cluster powers adjusted
%   according to cluster-wise K-factors given in [2, tables 7.17-24]
%
% index to links which are LOS and B5
% LosB5ind = find(bulkpar.propag_condition'.*(cfgLink.ScenarioVector>=7 & cfgLink.ScenarioVector<=9));
% 
% 
%     Kcluster = bulkpar.Kcluster;             % read cluster-wise K-factors
% 
%     %    phiLOS       = zeros(K,1);
% 
%     for localLIdx = 1:length(LosB5ind) % cycles links
%         linkIdx = LosB5ind(localLIdx);
%         k_ind = find(linkIdx==PCind);     % index to current LOS/NLOS links which are LOS and B5
%         for rxIdx = 1:Nr % cycles (MS) antennas
%             du = antpar.MsElementPosition(rxIdx)*waveLength;
%             for txIdx = 1:Nt % cycles (BS) atennas
% 
%                 pathIdx = 1;     % index to cluster with a direct ray, in WIM2 always 1st cluster
%                 ds = antpar.BsElementPosition(txIdx)*waveLength;
% 
%                 aod_direct = bulkpar.aods(linkIdx,pathIdx,1)-bulkpar.aods(linkIdx,pathIdx,2);     % AoD for the direct ray (middle)
%                 aoa_direct = bulkpar.aoas(linkIdx,pathIdx,1)-bulkpar.aoas(linkIdx,pathIdx,2);     % AoA for the direct ray (middle)
% 
%                 % antenna gain of direct ray is approximated by linear interpolation
%                 BsGain_direct = mean(BsGain(linkIdx,txIdx,pathIdx,1:2));
%                 MsGain_direct = mean(MsGain(linkIdx,rxIdx,pathIdx,1:2));        % 22.8.2006 PekKy, index txIdx corrected to rxIdx
% 
%                 nu = 0;     % LOS ray has always 0 Hz Doppler in B5 scenarios
% 
%                 temp =  BsGain_direct * exp(1i * k_CONST * ds * sin( aod_direct*pi/180))* ...
%                     MsGain_direct * exp(1i * (k_CONST * du * sin( aoa_direct*pi/180  ) + bulkpar.Phi_LOS(linkIdx,1) * pi/180 )) * ...
%                     exp(1j*2*pi*nu * t(k_ind,:) );
% 
%                 H(rxIdx,txIdx,pathIdx,:,k_ind) = (sqrt(1/(Kcluster(linkIdx,1)+1)) * squeeze(H(rxIdx,txIdx,pathIdx,:,k_ind)) + sqrt(Kcluster(linkIdx,1)/(Kcluster(linkIdx,1)+1)) * temp.').';
% 
%                 phiLOS(k_ind,pathIdx) = 0;
% 
%             end % Rx antennas
%         end % Tx antennas
% 
%     end % links
% 
%     phiLOS(k_ind,:) = prin_value((phiLOS(k_ind,:)*180/pi + bulkpar.Phi_LOS(k_ind,:)));
% 
% end

% Update states
finalCond.delta_t        = deltaT';
finalCond.subpath_phases = subPathPhases;
end

function y = prin_value(x)
% Maps inputs from (-inf,inf) to [-180,180)

y = mod(x,360);
y = y - 360 * (y >= 180);
end

function H = applyTimeDim(noTimeH, t, nu, thisNP, T)

M = 20;
sampBlkLen = floor(T/M);

H = complex(zeros(size(noTimeH, 1), size(noTimeH, 2), thisNP, T));
sampIdx = 0;
while sampIdx < T
    sampBlk = (sampIdx+1):min(sampIdx+sampBlkLen, T);
    sampIdx = sampBlk(end);
    phi = exp(1i * 2 * pi * nu(:,:,1:thisNP,:,:) .* ...
        reshape(t(sampBlk), 1, 1, 1, [])); % [1, 1, NP, Ns/M, M]
    H(:,:,:,sampBlk) = sum(noTimeH .* phi, 5); % [Nt, Nr, NP, Ns/M]
end

end

% [EOF]