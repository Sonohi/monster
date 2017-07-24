function bulkParam = generateBulkParam(wimpar,linkpar,fixpar,uniStream,normStream)
%GENERATE_BULK_PAR Generation of WIM2 interim channel model parameters
% 
%   [BULK_PAR]=GENERATE_BULK_PAR(WIMPAR,LINKPAR,FIXPAR) generates the
%   "bulk" parameters according to WINNER D5.4 with some Phase II modifications.
%   For explanation of the input structs, see WIMPARSET, LAYOUT2LINK and LAYOUTPARSET.
%   Denoting with K the number of links, N the number of paths,
%   M the number of subpaths, the fields BULK_PAR are as follows:
%
%   delays           - path delays in seconds [KxN]
%   path_powers      - relative path powers [KxN]
%   aods             - angles of departure in degrees over (-180,180) [KxNxM]
%   aoas             - angles of arrival in degrees over (-180,180) [KxNxM]
%   subpath_phases   - random phases for subpaths in degrees over (0,360) [KxNxM]
%   path_losses      - path losses in linear scale [Kx1]
%   MsBsDistance     - distances between MSs and BSs in meters [1xK]
%   shadow_fading    - shadow fading losses in linear scale [Kx1]
%   propag_condition -whether the user is in LoS condition (1) or in nlos (0)
%   sigmas           -correlation coefficients fo large scale parameters
%
%   In addition, when users with LoS condition exists (in addition to the above):
%   Kcluster        - K factors for all links [Kx1]
%   Phi_LOS         - random phases for LOS paths in degrees over (-180,180) [Kx1]
%
%   In addition, when users wimpar.PolarisedArrays is 'yes' (in addition to the above):
%   xprV            -vertical xpr values, [KxNxM]
%   xprH            -horizontal xpr values, [KxNxM]
%
%   In addition, when users in B5 scenario exist (in addition to the above):
%   scatterer_freq  -Doppler frequency for scatterers, [KxNxM]

% Copyright 2016 The MathWorks, Inc.

% Loop over all scenarios
allScen = unique(linkpar.ScenarioVector);
numScen = length(allScen);
scenParam = cell(1, numScen);
for idx = 1:numScen
    scenario = mapScenarioNumToLetter(allScen(idx)); % Scenario name in letters
    userIdx  = find(linkpar.ScenarioVector == allScen(idx));
    if any(strcmp(scenario, {'B5a','B5b','B5c','B5f'})) % Static feeder
        scenParam{idx} = static( ...
            wimpar,linkpar,fixpar,scenario,userIdx,uniStream,normStream);
    else % Geometric based stochastic models        
        scenParam{idx} = stochastic(...
            wimpar,linkpar,fixpar,scenario,userIdx,uniStream,normStream);
    end
end

% Initialize bulk structure
NL  = length(linkpar.MsBsDistance); 
NSP = 20; % wimpar.NumSubPathsPerPath;
allScenNP = cellfun(@(x) size(x.delays, 2), scenParam, 'UniformOutput', false);
maxNP = max(cell2mat(allScenNP));
bulkParam = struct( ...
    'delays',           nan(NL, maxNP), ...
    'path_powers',      nan(NL, maxNP), ...
    'aods',             nan(NL, maxNP, NSP), ...
    'aoas',             nan(NL, maxNP, NSP), ...
    'path_losses',      nan(NL, 1), ...
    'MsBsDistance',     nan(1,  NL), ...
    'shadow_fading',    nan(NL, 1), ...
    'sigmas',           nan(NL, 5), ...
    'propag_condition', nan(NL, 1), ...
    'Kcluster',         nan(NL, 1), ...
    'Phi_LOS',          nan(NL, 1), ...
    'scatterer_freq',   nan(NL, maxNP, NSP));

if strcmp(wimpar.PolarisedArrays,'no')
    bulkParam.subpath_phases = nan(NL, maxNP, NSP);
elseif strcmp(wimpar.PolarisedArrays,'yes')
    bulkParam.subpath_phases = nan(NL, 4, maxNP, NSP);
    bulkParam.xpr = nan(NL, maxNP, NSP);
end

% Fill bulk structure
for idx = 1:numScen
    thisScenParam = scenParam{idx};
    linkIdx = thisScenParam.user_indeces;
    NP = size(thisScenParam.delays, 2);
    bulkParam.delays(linkIdx, 1:NP)      = thisScenParam.delays;
    bulkParam.path_powers(linkIdx, 1:NP) = thisScenParam.path_powers;
    bulkParam.aods(linkIdx, 1:NP,:)      = thisScenParam.aods;
    bulkParam.aoas(linkIdx, 1:NP,:)      = thisScenParam.aoas;
    bulkParam.path_losses(linkIdx)       = thisScenParam.path_losses;
    bulkParam.MsBsDistance(linkIdx)      = thisScenParam.MsBsDistance;
    bulkParam.shadow_fading(linkIdx)     = thisScenParam.shadow_fading;
    bulkParam.propag_condition(linkIdx)  = thisScenParam.propag_condition;
    bulkParam.Kcluster(linkIdx)          = thisScenParam.Kcluster;
    bulkParam.Phi_LOS(linkIdx)           = thisScenParam.Phi_LOS;
    if any(strcmp(thisScenParam.Scenario, {'B5a','B5b','B5c','B5f'}))
        bulkParam.scatterer_freq(linkIdx, 1:NP, :) = thisScenParam.scatterer_freq; 
    else
        bulkParam.sigmas(linkIdx,:) = thisScenParam.sigmas;
    end
    
    if strcmp(wimpar.PolarisedArrays, 'no')
        bulkParam.subpath_phases(linkIdx,1:NP,:)   = ...
            thisScenParam.subpath_phases;
    elseif strcmp(wimpar.PolarisedArrays, 'yes')
        bulkParam.subpath_phases(linkIdx,:,1:NP,:) = ...
            thisScenParam.subpath_phases;
        bulkParam.xpr(linkIdx,1:NP,:) = thisScenParam.xpr;
    end    
end

end

function bulkParam = stochastic(wimpar,linkpar,fixpar,scenario,userIdx,uniStream,normStream)
% Generate bulk parameters for stochastic models [1, Sec.4.2].

% STEP 1: Extract certain parameters from the input structs
Ts       = wimpar.DelaySamplingInterval;
distMSBS = linkpar.MsBsDistance(userIdx);
NL       = length(userIdx);
NSP      = 20;  % wimpar.NumSubPathsPerPath

scenParam.Scenario = scenario;
scenParam.UserIndeces = userIdx;

% STEP 2: Get scenario specific parameters
switch scenario
  case {'A1', 'B1', 'B3', 'C1', 'C2', 'D1',}
        scenParam.LoS  = fixpar.(scenario).LoS;
        scenParam.NLoS = fixpar.(scenario).NLoS;
        if strcmpi(wimpar.UseManualPropCondition, 'yes') 
            propCond = linkpar.PropagConditionVector(userIdx);
        else
            propCond = pickRandomLOSLinks(scenario, NL, distMSBS, ...
                linkpar.Dist1(userIdx), linkpar.StreetWidth(userIdx), uniStream);
        end
        % numClusters = [scenParam.LoS.NumClusters, scenParam.NLoS.NumClusters];
  case {'D2a'} % All LOS
        scenParam.LoS  = fixpar.(scenario).LoS;
        propCond = ones(1, NL);
        % numClusters = [scenParam.LoS.NumClusters, 0];
  otherwise % {'A2', 'B2', 'B4', 'C3', 'C4'} All NLOS
        scenParam.NLoS = fixpar.(scenario).NLoS;
        propCond = zeros(1, NL);
        % numClusters = [0, scenParam.NLoS.NumClusters];
end

% Make sure that user-specific parameters are row vectors
ThetaBs = linkpar.ThetaBs(userIdx);
ThetaMs = linkpar.ThetaMs(userIdx);

% Indices of LOS & NLOS links and the amount of them
LOSLinkIdx   = find(propCond > 0);
numLOSLinks  = length(LOSLinkIdx);
NLOSLinkIdx  = find(propCond == 0);
numNLOSLinks = length(NLOSLinkIdx);

% Number of clusters/paths for LOS links
if (numLOSLinks > 0) 
    N1 = scenParam.LoS.NumClusters;
else
    N1 = 0;
end

% Number of clusters/paths for NLOS links
if (numNLOSLinks > 0)
    N2 = scenParam.NLoS.NumClusters;
else
    N2 = 0;
end

NP = max(N1, N2); % Larger of N1 and N2 to define the path/cluster dimnesion
scenParam.N = [N1, N2];

% All users exhibit bad urban effect (long delays)
isB2OrC3Secnario = any(strcmp(scenario, {'B2', 'C3'}));
if isB2OrC3Secnario % B2 and C3 are all NLOS links
    if strcmp(scenario, 'B2') 
        % Generate 2 scatterers for each user with distances from [1, table 4-3]
        MsScatBsDist = sort(1000 - (1000-300)*rand(uniStream, numNLOSLinks, 2), 2); 
        % Power loss due to excess delay dB per us
        FSLoss = 4; 
    else % C3
        % Generate 2 scatterers for each user with distances from [1, table 4-3]
        MsScatBsDist = sort(3000 - (3000-600)*rand(uniStream, numNLOSLinks,2), 2); 
        % Power loss due to excess delay dB per us
        FSLoss = 2; 
    end

    NumFSConnectionLinks = numNLOSLinks; % = NL xxx
    FSConnectionLinks = NLOSLinkIdx; % = 1:NL xxx
    NumFSPaths = 2; % Two last clusters for each path are created as FS (Far Scatter) clusters
end

scenParam.PropagCondition = propCond;

if strcmp(wimpar.PathLossModel, 'pathloss')
    pathLossFileName = 'winner2.internal.pathloss';
else
    pathLossFileName = wimpar.PathLossModel;
end

% STEP 3: Employ the user-defined path loss model
if strcmpi(wimpar.PathLossModelUsed, 'yes')
    [pathLoss, linkpar, ~, scenParam] = feval( ...
        pathLossFileName,wimpar,linkpar,fixpar,scenParam,uniStream);
    pathLoss = 10.^(-pathLoss(:)/10); % db to linear
else
    pathLoss = nan(1, NL);
end

% STEP 4: Generation of correlated DS, AS's and SF for all links. This step
% takes into account channel scenario automatically
sigmas = zeros(NL, 5);
if numLOSLinks > 0
    sigmas(LOSLinkIdx, :) = genLargeScaleCorrPerCond([linkpar.Stations.Pos], ...
        linkpar.Pairing(:,userIdx(LOSLinkIdx)), scenParam.LoS, normStream);
end
if numNLOSLinks > 0
    sigmas(NLOSLinkIdx, :) = genLargeScaleCorrPerCond([linkpar.Stations.Pos], ...
        linkpar.Pairing(:,userIdx(NLOSLinkIdx)), scenParam.NLoS, normStream);
end

sigma_asD = sigmas(:,1);
sigma_asA = sigmas(:,2);
sigma_ds  = sigmas(:,3);
sigma_sf  = sigmas(:,4);
sigma_kf  = sigmas(:,5);

% STEP 5: Generate delays in a (NL x NP) matrix
if strcmpi(wimpar.FixedPdpUsed,'no')
    sigma_ds = repmat(sigma_ds, 1, NP); % delay spreads for all clusers/users
    taus     = nan(NL, NP);

    switch scenario  % See distributions in [1, table 4-5]
      case {'A1','A2','B3','B4','C1','C2','C3','C4','D1','D2A'}
        if numLOSLinks > 0 % [1, eq. 4.1]            
            taus(LOSLinkIdx, 1:N1) = sort(-scenParam.LoS.r_DS * ...
                sigma_ds(LOSLinkIdx,1:N1) .* log(rand(uniStream,numLOSLinks,N1)),2);  
        end

        if numNLOSLinks > 0 % [1, eq. 4.1]            
            taus(NLOSLinkIdx, 1:N2) = sort(-scenParam.NLoS.r_DS * ...
                sigma_ds(NLOSLinkIdx, 1:N2) .* log(rand(uniStream,numNLOSLinks,N2)),2);  
        end

      otherwise % {'B1','B2'}
        if numLOSLinks > 0 % [1, eq. 4.1]            
            taus(LOSLinkIdx,1:N1) = sort(-scenParam.LoS.r_DS * ...
                sigma_ds(LOSLinkIdx,1:N1) .* log(rand(uniStream,numLOSLinks,N1)),2);
        end

        if numNLOSLinks > 0 % [1, eq. 4.1]            
            taus(NLOSLinkIdx,1:N2) = sort(800E-9*rand(uniStream,numNLOSLinks,N2),2); 
        end
    end

    % Normalize min delay to zero
    taus_sorted = taus - taus(:, 1);       

    if isB2OrC3Secnario
        taus_sorted(FSConnectionLinks, N2+1-NumFSPaths:N2) = 0; % xxx shoudl be end-1:end
    end

    % in case of los, extra factor. Not be used in clusterpower calculation
    % need to extract taus_sorted to taus_los, since the next step is not
    % applied for the taus that is given as input parameter to powers
    % generation  xxx DO NOT UNDERSTAND
    taus_without_los_factor = taus_sorted;
    
    if isB2OrC3Secnario
        taus_sorted(FSConnectionLinks,end-1:end) = MsScatBsDist/3e8;         
    end
    
    if numLOSLinks > 0
        K_factors(LOSLinkIdx) = sigma_kf(LOSLinkIdx)'; % [1 NL]
        K_factors_dB((LOSLinkIdx)) = 10*log10(abs(sigma_kf((LOSLinkIdx))))'; % [1 NL]
        ConstantD = 0.7705 - ... 
                    0.0433   * K_factors_dB(LOSLinkIdx) + ...
                    0.0002   * K_factors_dB(LOSLinkIdx).^2 + ...
                    0.000017 * K_factors_dB(LOSLinkIdx).^3; %[1, eq.4.3]
        taus_sorted(LOSLinkIdx,1:N1) = taus_sorted(LOSLinkIdx,1:N1) ./ ConstantD';
    end
else  % Use fixed delays from a table. 
    [PDPLOS, PDPNLOS] = getFixedPDP(scenario);

    % Same tau for all LOS/NOLOS links
    taus_sorted = nan(NL, NP);
    taus_sorted(LOSLinkIdx,  1:N1) = repmat(PDPLOS.taus,  numLOSLinks,  1);
    taus_sorted(NLOSLinkIdx, 1:N2) = repmat(PDPNLOS.taus, numNLOSLinks, 1);
    K_factors_dB(LOSLinkIdx) = PDPLOS.KCluster(1,:); 
    K_factors(LOSLinkIdx) = 10.^(K_factors_dB(LOSLinkIdx)/10);
end

% Rounding to delay grid
if (Ts > 0)
    taus_rounded = Ts*floor(taus_sorted/Ts + 0.5);
else
    taus_rounded = taus_sorted;
end

% STEP 6: Determine random average powers in a (NL x NP) matrix 
if strcmpi(wimpar.FixedPdpUsed, 'no')
    if numLOSLinks > 0   % Per-path shadowing
        ksi_LoS = randn(normStream,numLOSLinks,N1) * scenParam.LoS.LNS_ksi;
    end
    if numNLOSLinks > 0  % Per-path shadowing 
        ksi_NLoS = randn(normStream,numNLOSLinks,N2) * scenParam.NLoS.LNS_ksi; 
    end
    
    P = nan(NL,NP);
    P1 = nan(NL,NP);

    % See distributions in [1, table 4-5]
    if numLOSLinks > 0
        % For LOS links, with exponential distribution of delays [1, eq 4.3]
        P1(LOSLinkIdx,1:N1) = ...
            exp(-taus_without_los_factor(LOSLinkIdx,1:N1) .* ...
            ((scenParam.LoS.r_DS-1) ./ (scenParam.LoS.r_DS .* ...
            sigma_ds(LOSLinkIdx, 1:N1)))) .* (10.^(-ksi_LoS/10));
    end
    if numNLOSLinks > 0
        if strcmpi(scenario,'B1')
            % For NLoS links B1, with uniform distribution of delays [1, eq.4.4]
            P1(NLOSLinkIdx,1:N2) = ...
                exp(-taus_without_los_factor(NLOSLinkIdx,1:N2) ./ ...
                sigma_ds(NLOSLinkIdx, 1:N2)) .* (10.^(-ksi_NLoS/10));
        else
            % For NLoS links, with exponential distribution of delays [1, eq 4.3]
            P1(NLOSLinkIdx,1:N2) = ...
                exp(-taus_without_los_factor(NLOSLinkIdx,1:N2) .* ...
                ((scenParam.NLoS.r_DS-1) ./ (scenParam.NLoS.r_DS .* ...
                sigma_ds(NLOSLinkIdx, 1:N2)))) .* (10.^(-ksi_NLoS/10));
        end
        
        if isB2OrC3Secnario
            excessDelayLoss = ((MsScatBsDist - repmat(distMSBS(FSConnectionLinks).',1, NumFSPaths))./ ...
                (repmat(3e8,NumFSConnectionLinks,NumFSPaths))).*1e6*FSLoss; % [NL 2]
            P1(FSConnectionLinks,    N2+1-NumFSPaths:N2) = ...
                P1(FSConnectionLinks,N2+1-NumFSPaths:N2) .* 10.^(-excessDelayLoss./10);
        end
    end

    % For LOS links
    if numLOSLinks > 0
        % Used to replace P(LOSLinkIdx,1:N1) after the angular directions have been created
        normP1 = P1(LOSLinkIdx,1:N1)./ sum(P1(LOSLinkIdx,1:N1),2); % Normalization
        % Kfactor calculations are here only for angular domain use
        specularRayPower = K_factors(LOSLinkIdx)./(K_factors(LOSLinkIdx)+1); %[1, eq.4.8]
        diracVector = [ones(numLOSLinks, 1), zeros(numLOSLinks,N1-1)];
        P(LOSLinkIdx,1:N1) = 1./(1+K_factors(LOSLinkIdx).') .* ...
            normP1 + diracVector .* specularRayPower.'; %[1, eq.4.9]
    end

    if numNLOSLinks > 0 % Normalization
        P(NLOSLinkIdx,1:N2) = P1(NLOSLinkIdx,1:N2)./repmat(sum(P1(NLOSLinkIdx,1:N2),2),1,N2);
    end
else % Use fixed powers from a table
    P = nan(NL, NP);
    P(LOSLinkIdx, 1:N1) = repmat(PDPLOS.P1 /sum(PDPLOS.P1),  numLOSLinks,  1); % xxx Not apply K factor here?
    P(NLOSLinkIdx,1:N2) = repmat(PDPNLOS.P1/sum(PDPNLOS.P1), numNLOSLinks, 1);
end

% STEP 7: Determine AoDs & AoAs [1, Table 4-1] 

% Initialization
AoD_path  = nan(NL, NP);
AoA_path  = nan(NL, NP);   

if strcmpi(wimpar.FixedAnglesUsed, 'no')
    [offset_matrix_AoD, offset_matrix_AoA] = formulateOffsetMatrix(scenParam);
    
    % Table of constant C in [1, step 7]
    FcTable = [4     5     8     10    11    12    14    15    16    20; ...
               0.779 0.860 1.018 1.090 1.123 1.146 1.190 1.211 1.226 1.289];
       
    if numLOSLinks > 0
        % [1, eq. 4.11]
        Fc = repmat(FcTable(2, FcTable(1,:) == N1), numLOSLinks, N1);
        Fc = Fc .* (1.1035 - 0.028 .*  K_factors_dB(LOSLinkIdx).' - ...
                             0.002 .* (K_factors_dB(LOSLinkIdx).').^2 + ...
                             0.0001.* (K_factors_dB(LOSLinkIdx).').^3);  

        % [1, eq. 4.10]
        AoDPrimer = 2 * sigma_asD(LOSLinkIdx) / 1.4 .* ...
            sqrt(-log(P(LOSLinkIdx,1:N1) ./ ...
            max(P(LOSLinkIdx,1:N1),[],2))) ./ Fc; 
        
        % [1, eq. 4.13]
        AoD_path(LOSLinkIdx,1:N1) = AoDPrimer .* ...
            (2*round(rand(uniStream, numLOSLinks, N1))-1) + ...
            sigma_asD(LOSLinkIdx)/1.4/5 .* randn(normStream, numLOSLinks, N1) - ...
            (AoDPrimer(:,1) .* (2 * round(rand(uniStream, numLOSLinks, N1)) - 1) + ...
            sigma_asD(LOSLinkIdx)/1.4/5 * randn(normStream,1,1) - ...
            ThetaBs(LOSLinkIdx).'); 

        % [1, eq. 4.10]
        AoAPrimer = 2 * sigma_asA(LOSLinkIdx) / 1.4 .* ...
            sqrt(-log(P(LOSLinkIdx,1:N1) ./ ...
            max(P(LOSLinkIdx,1:N1),[],2))) ./ Fc; 
        
        % [1, eq. 4.13]
        AoA_path(LOSLinkIdx,1:N1) = AoAPrimer .* ...
            (2*round(rand(uniStream,numLOSLinks,N1))-1) + ...
            sigma_asA(LOSLinkIdx)/1.4/5 .* randn(normStream, numLOSLinks, N1) - ...
            (AoAPrimer(:, 1) .* (2 * round(rand(uniStream, numLOSLinks, N1)) - 1) + ...
            sigma_asA(LOSLinkIdx)/1.4/5 * randn(normStream,1,1) - ...
            ThetaMs(LOSLinkIdx).'); 
    end

    if numNLOSLinks > 0
        Fc = repmat(FcTable(2, FcTable(1,:) == N2), numNLOSLinks, N2);
        
        % [1, eq. 4.10]
        AoDPrimer = 2 * sigma_asD(NLOSLinkIdx) / 1.4 .* ...
            sqrt(-log(P(NLOSLinkIdx,1:N2) ./ ...
            max(P(NLOSLinkIdx,1:N2),[],2))) ./ Fc;
        
        % [1, eq. 4.12]
        AoD_path(NLOSLinkIdx,1:N2) = AoDPrimer .* ...
            (2*round(rand(uniStream,numNLOSLinks,N2))-1) + ...
            sigma_asD(NLOSLinkIdx)/1.4/5 .* randn(normStream, numNLOSLinks, N2) + ...
            ThetaBs(NLOSLinkIdx).'; 

        % [1, eq. 4.10]
        AoAPrimer = 2 * sigma_asA(NLOSLinkIdx) / 1.4 .* ...
            sqrt(-log(P(NLOSLinkIdx,1:N2) ./ ...
            max(P(NLOSLinkIdx,1:N2),[],2))) ./ Fc; 
        
        % [1, eq. 4.12]
        AoA_path(NLOSLinkIdx,1:N2) = AoAPrimer .* ...
            (2*round(rand(uniStream,numNLOSLinks,N2))-1) + ...
            sigma_asA(NLOSLinkIdx)/1.4/5 .* randn(normStream, numNLOSLinks, N2) + ...
            ThetaMs(NLOSLinkIdx).'; 
    end
    
    % Apply offset [1, eq. 4.14] 
    % xxx Reconsider how to reshape/permute to make this more efficient 
    theta_nm_aod = reshape(AoD_path.', 1, []) + offset_matrix_AoD;  % [NSP, NP x NL]        
    theta_nm_aoa = reshape(AoA_path.', 1, []) + offset_matrix_AoA;  % [NSP, NP x NL]        

    % Create NP*NL random permutations of integers (1:NSP)
    [~, h] = sort(rand(uniStream, NSP, NP*NL), 1);       
    
    % Pair AoA rays randomly with AoD rays (within a cluster).
    theta_nm_aoa = theta_nm_aoa(h + (0:NSP:NSP*NP*NL-1));    
else % Fixed AoD/AoAs
    if strcmpi(scenario, 'B5b') 
        range = wimpar.range;
    else
        range = 0;
    end
    
    % Determine AoDs 
    % xxx Shouldn't the following be scenParam.LOS.PerClusterAS_D and
    % scenParam.LOS.PerClusterAS_A? BUG???
    [AoD_path_los,  scenParam.PerClusterAS_D,...
     AoD_path_nlos, scenParam.NLoS.PerClusterAS_D] = getFixedAoD(scenario, range);

    % Determine AoAs
    [AoA_path_los,  scenParam.PerClusterAS_A,...
     AoA_path_nlos, scenParam.NLoS.PerClusterAS_A] = getFixedAoA(scenario, range);
    
    if numLOSLinks > 0  % Same for each link        
        AoD_path(LOSLinkIdx,1:N1) = repmat(AoD_path_los, numLOSLinks, 1);
        AoA_path(LOSLinkIdx,1:N1) = repmat(AoA_path_los, numLOSLinks, 1);
    end

    if numNLOSLinks > 0 % Same for each link
        AoD_path(NLOSLinkIdx,1:N2) = repmat(AoD_path_nlos, numNLOSLinks, 1);
        AoA_path(NLOSLinkIdx,1:N2) = repmat(AoA_path_nlos, numNLOSLinks, 1);
    end

    [offset_matrix_AoD, offset_matrix_AoA] = formulateOffsetMatrix(scenParam);
    
    % Apply offset. NOTE! now array orientation parameter ThetaBs is
    % disabled and AoD is always like in CDL model tables, 17.5.2006 PekKy.
    theta_nm_aod = reshape(AoD_path.', 1, []) + offset_matrix_AoD; % [NSP, NP x NL]        
    theta_nm_aoa = reshape(AoA_path.', 1, []) + offset_matrix_AoA; % [NSP, NP x NL]        
end

% Wrapping of angles to range (-180,180)
theta_nm_aoa = prin_value(theta_nm_aoa);
theta_nm_aod = prin_value(theta_nm_aod);

% Put AoDs and AoAs into a 3D-array with dims [NL NP NSP]
theta_nm_aod = permute(reshape(theta_nm_aod, NSP, NP, NL), [3 2 1]);
theta_nm_aoa = permute(reshape(theta_nm_aoa, NSP, NP, NL), [3 2 1]);

% STEP 10a
phi = 360*rand(uniStream, NL, NP, NSP); % Random phases for all users, Uni(0,360)

% Set to NaN those that are not valid
if N1 < N2
    phi(LOSLinkIdx,  end+1-(N2-N1):end,:) = NaN;
elseif N1 < N2
    phi(NLOSLinkIdx, end+1-(N1-N2):end,:) = NaN;
end

% Replace the Kfactor related powers with powers independent of Kfactor
if (numLOSLinks > 0) && strcmp(wimpar.FixedPdpUsed, 'no')
    P(LOSLinkIdx,1:N1) = normP1; 
end

% xxx Both branches are the same??? Because K_factors is a row vector!
if strcmpi(wimpar.FixedPdpUsed, 'no')
    Phi_LOS = nan(NL, 1);
    Phi_LOS(LOSLinkIdx) = 360*(rand(uniStream,numLOSLinks,1)-0.5);
else
    Phi_LOS = nan(NL,1);
    Phi_LOS(LOSLinkIdx) = 360*(rand(uniStream,numLOSLinks,size(K_factors,1))-0.5);
end

% Output generation
bulkParam = struct( ...
    'Scenario',         scenario, ...
    'user_indeces',     userIdx.',...
    'delays',           taus_rounded,...
    'path_powers',      P,...
    'aods',             theta_nm_aod,...  % in degrees
    'aoas',             theta_nm_aoa,...  % in degrees
    'subpath_phases',   phi,...           % in degrees
    'path_losses',      pathLoss,...      % in linear scale
    'MsBsDistance',     distMSBS,...  
    'shadow_fading',    sigma_sf,...      % in linear scale
    'sigmas',           sigmas, ...
    'propag_condition', propCond.',...
    'Kcluster',         sigmas(:,5)', ...
    'Phi_LOS',          Phi_LOS);

% STEP 9 to 10b
if strcmpi(wimpar.PolarisedArrays, 'yes')
    % Generate random phases for 2x2 polarisation matrix elements
    phi = 360*rand(uniStream, NL, 4, NP, NSP); 
    
    % Generate random XPR
    xpr_dB = randn(normStream, NL, NP, NSP);
    
    % Get XPR distribution parameters (log-Normal)
    if numLOSLinks > 0
        xpr_mu_los = scenParam.LoS.xpr_mu;         % XPR mean [dB]
        xpr_sigma_los = scenParam.LoS.xpr_sigma;   % XPR std  [dB]
        xpr_dB(LOSLinkIdx, 1:N1,:) = ...       % XPR [dB] 
            xpr_dB(LOSLinkIdx, 1:N1,:)*xpr_sigma_los+xpr_mu_los; 
    end

    if numNLOSLinks > 0 
        xpr_mu_nlos = scenParam.NLoS.xpr_mu;         % XPR mean [dB]
        xpr_sigma_nlos = scenParam.NLoS.xpr_sigma;   % XPR std  [dB]
        xpr_dB(NLOSLinkIdx, 1:N2,:) = ...        % XPR [dB]
            xpr_dB(NLOSLinkIdx, 1:N2,:)*xpr_sigma_nlos+xpr_mu_nlos;
    end

    % Convert XPR to linear scale
    xpr = 10.^(xpr_dB/10); 
    
    if N1 < N2
        phi(LOSLinkIdx,:,end+1-(N2-N1):end,:) = NaN;
        xpr(LOSLinkIdx,end+1-(N2-N1):end,:) = NaN;
    elseif N1 < N2
        phi(NLOSLinkIdx,:,end+1-(N1-N2):end,:) = NaN;
        xpr(NLOSLinkIdx,end+1-(N1-N2):end,:) = NaN;
    end
    
    % Add to output structure
    bulkParam.subpath_phases = phi; % Degrees
    bulkParam.xpr            = xpr; % Linear scale
end

end

function bulk_parameters = static(wimpar,linkpar,fixpar,scenario,userIdx,uniStream,normStream)
% Generate bulk parameters for B5 feeder scenarios [1, Sec.6.12].

% xxx Move to structure check 
if  ~(linkpar.MsVelocity == 0) 
    linkpar.MsVelocity=0;
end

Ts       = wimpar.DelaySamplingInterval;
distMSBS = linkpar.MsBsDistance(userIdx);
NL       = length(userIdx);
NSP      = 20; % wimpar.NumSubPathsPerPath

scenParam.Scenario = scenario;
scenParam.UserIndeces = userIdx;

allLOSLinks = any(strcmp(scenario, {'B5a', 'B5b', 'B5c'}));
if allLOSLinks %  {'B5a', 'B5b', 'B5c'}
    scenParam.LoS = fixpar.(scenario);
    scenParam.PropagCondition = ones(1,NL);
else % {'B5f'}
    scenParam.NLoS = fixpar.(scenario);
    scenParam.PropagCondition = zeros(1,NL);
end

if strcmpi(scenario, 'B5b') 
    range = wimpar.range;
else
    range = 0;
end

% Get scenario specific PDP parameters
[PDPLOS, PDPNLOS] = getFixedPDP(scenario, range); 

% Get scenario specific AOD parameters
[AoD_path_los,scenParam.LoS.PerClusterAS_D,...
    AoD_path_nlos,scenParam.NLoS.PerClusterAS_D] = getFixedAoD(scenario, range);

% Get scenario specific AoA parameters
[AoA_path_los,scenParam.LoS.PerClusterAS_A,...
    AoA_path_nlos,scenParam.NLoS.PerClusterAS_A] = getFixedAoA(scenario, range);

% Determine path delays, path powers, AoDs, AoAs 
if allLOSLinks 
    NP = length(PDPLOS.taus); % Number of clusters/paths
    scenParam.N = [NP, 0];
    % Same config for each path
    taus_sorted = repmat(PDPLOS.taus,  NL, 1);     
    P           = repmat(PDPLOS.P1,    NL, 1);      
    AoD_path    = repmat(AoD_path_los, NL, 1);
    AoA_path    = repmat(AoA_path_los, NL, 1);
    Kcluster    = 10.^(PDPLOS.KCluster(1,:)/10);       
else
    NP = length(PDPNLOS.taus); % Number of clusters/paths
    scenParam.N   = [0, NP];    
    % Same config for each path
    taus_sorted = repmat(PDPNLOS.taus,  NL, 1);   
    P           = repmat(PDPNLOS.P1,    NL, 1);     
    AoD_path    = repmat(AoD_path_nlos, NL ,1);
    AoA_path    = repmat(AoA_path_nlos, NL ,1);
    Kcluster    = nan(NL, 1);
end

% Rounding path delays
if (Ts > 0)
    taus_rounded = Ts*floor(taus_sorted/Ts + 0.5);
else
    taus_rounded = taus_sorted;
end

% Normalize path powers
P = P./sum(P, 2);

% Apply offset matrix
[offset_matrix_AoD, offset_matrix_AoA] = formulateOffsetMatrix(scenParam);
theta_nm_aod = reshape(AoD_path.', 1, []) + offset_matrix_AoD; % [NSP, NL*NP]
theta_nm_aoa = reshape(AoA_path.', 1, []) + offset_matrix_AoA; % [NSP, NL*NP]

% Create NP*NL random permutations of integers (1:NSP)
[~, h] = sort(rand(uniStream, NSP, NP*NL), 1);       
   
% Pair AoA rays randomly with AoD rays (within a cluster).
theta_nm_aoa = theta_nm_aoa(h + (0:NSP:NSP*NP*NL-1));    

% Wrapping of angles to range (-180,180)
theta_nm_aoa = prin_value(theta_nm_aoa);
theta_nm_aod = prin_value(theta_nm_aod);

% Scatterer frequency
scatterer_freq = getB5FixedScatterFreq(scenario, wimpar.CenterFrequency); % [NSP, NP]

if allLOSLinks
    Phi_LOS = 360*(rand(uniStream, NL, 1)-0.5);
else
    Phi_LOS = nan(NL,1);
end

phi = 360*rand(uniStream, NL, NP, NSP);

% Calculate path loss
% xxx We need to check if isequal(lower(wimpar.PathLossModelUsed),'yes').
% BUG???
if strcmp(wimpar.PathLossModel, 'pathloss')
    pathLossFileName = 'winner2.internal.pathloss';
else
    pathLossFileName = wimpar.PathLossModel;
end

[path_losses, linkpar, ~, scenParam] = ...
    feval(pathLossFileName, wimpar, linkpar, fixpar, scenParam, uniStream);
path_losses = 10.^(-path_losses(:)/10); % [NL, 1]

% Calculate shadow fading
if any(strcmp(scenario, {'B5a','B5c','B5f'}))
    sigma_sf = 3.4*ones(NL,1);
else % 'B5b'
    lambda = 3e8/wimpar.CenterFrequency;
    breakpoint_distance = 4*(linkpar.MsHeight(userIdx)-1.6) .* ...
                            (linkpar.BsHeight(userIdx)-1.6)/lambda;
    within_breakpoint = (distMSBS < breakpoint_distance);
    sigma_sf = ( 3*within_breakpoint + 7*(~within_breakpoint) )';
end

% Conver to linear scale
sigma_sf = 10.^((sigma_sf.*randn(normStream, NL, 1))/10); 

% Put AoDs, AoAs, scatterFreq and power gains into a 3D-array with dims [NL N NSP]
% xxx The permute here is very expensive. Should reconsider array
% orientation.
theta_nm_aod   = permute(reshape(theta_nm_aod,   NSP, NP, NL), [3 2 1]);
theta_nm_aoa   = permute(reshape(theta_nm_aoa,   NSP, NP, NL), [3 2 1]);
scatterer_freq = permute(repmat(scatterer_freq,  1, 1, NL),  [3 2 1]);

bulk_parameters = struct(...
    'Scenario',         scenario, ...    
    'user_indeces',     userIdx.', ...
    'delays',           taus_rounded,...
    'path_powers',      P,...    
    'aods',             theta_nm_aod,...            
    'aoas',             theta_nm_aoa,...
    'subpath_phases',   phi,...
    'Kcluster',         Kcluster,... 
    'Phi_LOS',          Phi_LOS,...    
    'path_losses',      path_losses,...
    'shadow_fading',    sigma_sf,... 
    'MsBsDistance',     distMSBS,... 
    'scatterer_freq',   scatterer_freq,...
    'propag_condition', scenParam.PropagCondition.');

if strcmpi(wimpar.PolarisedArrays, 'yes')    
    % Generate random phases for 2x2 polarisation matrix elements
    phi = 360*rand(uniStream, NL, 4, NP, NSP);

    % Generate random XPR
    xpr_dB = randn(normStream, NL, NP, NSP);

    % get XPR distribution parameters (log-Normal)
    if allLOSLinks
        xpr_mu_los = scenParam.LoS.xpr_mu;               % XPR mean [dB]
        xpr_sigma_los = scenParam.LoS.xpr_sigma;         % XPR std  [dB]
        xpr_dB = xpr_dB * xpr_sigma_los + xpr_mu_los;  % XPR [dB]
            
    else
        xpr_mu_nlos = scenParam.NLoS.xpr_mu;             % XPR mean [dB]
        xpr_sigma_nlos = scenParam.NLoS.xpr_sigma;       % XPR std  [dB]
        xpr_dB = xpr_dB * xpr_sigma_nlos+xpr_mu_nlos;  % XPR [dB]            
    end

    % Generate XPRs, dimensions are [NL NP NSP]
    xpr = 10.^(xpr_dB/10); 

    % Add to output structure
    bulk_parameters.subpath_phases = phi;   % Degrees
    bulk_parameters.xpr = xpr;              % Linear scale
end

end

function y = prin_value(x)
% Map inputs from (-inf,inf) to [-180,180)

y = mod(x,360);
y = y - 360 * (y >= 180);

end

function output = mapScenarioNumToLetter(input)

switch (input)
    case 1
        output = 'A1';
    case 2
        output = 'A2';
    case 3
        output = 'B1';
    case 4
        output = 'B2';
    case 5
        output = 'B3';
    case 6
        output = 'B4';
    case 7
        output = 'B5a';
    case 8
        output = 'B5c';
    case 9
        output = 'B5f';
    case 10
        output = 'C1';
    case 11
        output = 'C2';
    case 12
        output = 'C3';
    case 13
        output = 'C4';
    case 14
        output = 'D1';
    otherwise % 15
        output = 'D2a';
end

end

function propCond = pickRandomLOSLinks(scenario,numLinks,distMSBS,dist1,streetWidth,uniStream)

% Probability of LOS links [1, sect 3.1.6 ]  eq. 3.20-25
switch scenario   
    case 'A1'
        dBp = 2.5;  % Max distance of LOS probability 1 [m]
        probLOS = ones(size(distMSBS));
    	idxOutRange = distMSBS > dBp;
        probLOS(idxOutRange) = 1-0.9*(1 - (1.24 - ...
            0.61*log10(distMSBS(idxOutRange))).^3).^(1/3); 
    case {'B1'}
        % xxx Should do the following per link. BUG???
        if any(isnan(dist1)) % Draw dist1 randomly YS:             
            dist1 = 1;
            while (dist1>5000) | (dist1 < 10)
                dist2 = (distMSBS - streetWidth/2) .* rand(uniStream,1,numLinks)...
                    + streetWidth/2;
                dist1 = sqrt(distMSBS.^2 - dist2.^2);
            end
        else
            for linkIdx = 1:numLinks 
                % Check applicability and change dist1 if needed
                if (distMSBS(linkIdx)^2 < (streetWidth(linkIdx)/2)^2 + dist1(linkIdx)^2)
                    dist1(linkIdx) = sqrt(distMSBS(linkIdx)^2 - (streetWidth(linkIdx)/2)^2);
                end
            end
            
            dist2 = sqrt(distMSBS.^2 - dist1.^2);
        end
        
        dBp = 15;      % Max distance of LOS probability 1 [m]
        probLOS = ones(1, numLinks);
        idxOutRange = distMSBS > dBp;
        probLOS(idxOutRange) = 1-(1-(1.56 - ...
            0.48*log10(sqrt(dist1(idxOutRange).^2 + ...
            dist2(idxOutRange).^2))).^3).^(1/3);
    case 'B3' 
        % Scenario B3 has two LOS probability functions, default is eq 3.22        
        dBp = 10;  % Max distance of LOS probability 1 [m]
        probLOS = ones(1, numLinks);
        idxOutRange = distMSBS > dBp;
        probLOS(idxOutRange) = exp(-(distMSBS(idxOutRange)-10)/45);         
    case 'C1'
        probLOS = exp(-distMSBS/200);        
    case 'C2'
        probLOS = min(18./distMSBS, 1) .* (1-exp(-distMSBS/63)) + exp(-distMSBS/63);
    case {'D1', 'D2a'}
        probLOS = exp(-distMSBS/1000);        
end

% Output, 0 for NLOS and 1 for LOS links
propCond = rand(uniStream,1,numLinks)<probLOS;

end

function sigmas = genLargeScaleCorrPerCond(stationPos,pairingPerCond,scenarioCond,normStream)
% Generate correlated large scale (LS) parameters DS, ASA, ASD and SF for
% all links. If layout parameters (co-ordinates etc.) are given,
% auto-correlation between channel segments is generated. If layout
% parameters are not defined, only cross-correlation between LS parameters
% is generated. Auto-correlation is generated for each BS separately. If
% two MSs are linked to same BS, correlation is distance dependent. If one
% MS is linked to two sectors of single BS, correlation is full.

DS_lambda   = scenarioCond.DS_lambda;
AS_D_lambda = scenarioCond.AS_D_lambda;
AS_A_lambda = scenarioCond.AS_A_lambda;
SF_lambda   = scenarioCond.SF_lambda;
KF_lambda   = scenarioCond.KF_lambda;

% Generate auto-correlation separately for each BS
ksi = zeros(5, size(pairingPerCond, 2));
uniqueBS = unique(pairingPerCond(1, :));
for i = 1:length(uniqueBS)
    idxBS = uniqueBS(i);
    idxLink = find(pairingPerCond(1,:) == idxBS); % Link index from this BS
    idxMs = pairingPerCond(2,idxLink);            % MS index linked to this BS

    if length(idxMs) > 1  % More than one MS linked to this BS
        % Generate grid of i.i.d Gaussian random numbers ~N(0,1) with
        % 100 extra samples to all directions (+-x and +-y coordinates)
        % xxx Go back to better understand this code
        xtra = 100;
        MsPos = stationPos(:,idxMs);
        gridn = randn(normStream, ...
                      max(MsPos(2,:)) - min(MsPos(2,:)) + 2*xtra + 1,...
                      max(MsPos(1,:)) - min(MsPos(1,:)) + 2*xtra + 1, 5);

        % Index to MS locations on the grid  
        gind = sub2ind(size(gridn), ...
            MsPos(2,:) - min(MsPos(2,:)) + xtra + 1, ...
            MsPos(1,:)-min(MsPos(1,:))+xtra+1);

        % Define auto-correlation filter for each of the 4 LS parameters
        delta = [DS_lambda AS_D_lambda AS_A_lambda SF_lambda KF_lambda];
        d = 0:100;
        h = exp(-1*repmat(d',1,5)./repmat(delta,length(d),1)); % d>0
        h = h./repmat(sum(h),length(d),1);  

        % Filter Gaussian grid in 2D to get exponential auto-correlation
        for ii=1:5
            if(delta(ii)~=0)
                tmp = filter(h(:,ii), 1, gridn(:,:,ii), [], 1); 
                grida = filter(h(:,ii), 1, tmp, [], 2);
                % Pick correlated MS locations from the grid 
                ksi(ii,idxLink) = grida(gind); 
            else
                ksi(ii,idxLink) = gridn(gind);
            end
        end
    else  % Only one MS linked, no auto-correlation
        ksi(:,idxLink) = randn(normStream,5,1);
    end 
end 

% Generate cross-correlation
% Extract cross correlation parameters from input
a = scenarioCond.asD_ds;     % Departure AS vs delay spread
b = scenarioCond.asA_ds;     % Arrival AS vs delay spread
c = scenarioCond.asA_sf;     % Arrival AS vs shadowing std
d = scenarioCond.asD_sf;     % Departure AS vs shadoving std
e = scenarioCond.ds_sf;      % Delay spread vs shadoving std
f = scenarioCond.asD_asA;    % Departure AS vs arrival AS
g = scenarioCond.asD_kf;     % Departure AS vs k-factor
h = scenarioCond.asA_kf;     % Arrival AS vs k-factor
k = scenarioCond.ds_kf;      % Delay spread vs k-factor
l = scenarioCond.sf_kf;      % Shadowing std vs k-factor

% Cross-correlation matrix: Order of rows and columns is ds -> asD ->
% asA -> sf
A = [ 1  a  b  e  k ;...
      a  1  f  d  g ;...
      b  f  1  c  h ;...
      e  d  c  1  l ;...
      k  g  h  l  1 ];

% Generate cross-correlation
ksi  = sqrtm(A)*ksi;   

a = scenarioCond.DS_mu;
b = scenarioCond.DS_sigma;
c = scenarioCond.AS_D_mu;
d = scenarioCond.AS_D_sigma;
e = scenarioCond.AS_A_mu;
f = scenarioCond.AS_A_sigma;
g = scenarioCond.SF_sigma;
h = scenarioCond.KF_mu;
k = scenarioCond.KF_sigma;

% Transform normal distributed random numbers to scenario specific
% distributions    
sigma_ds  = 10.^(b*ksi(1,:).' + a);        % Log-Normal 
sigma_asD = 10.^(d*ksi(2,:).' + c);        % Log-Normal 
sigma_asA = 10.^(f*ksi(3,:).' + e);        % Log-Normal 
sigma_sf  = 10.^(0.1*g*ksi(4,:).');        % Log-Normal dB
sigma_kf  = 10.^(0.1*(k*ksi(5,:).'+ h));   % Log-Normal dB

sigmas = [sigma_asD sigma_asA sigma_ds sigma_sf sigma_kf];

end

function [AoDOffseMatrix, AoAOffseMatrix] = formulateOffsetMatrix(scenParam)
% Formulate AoD/AoA offset matrices for all (20) subpaths, paths and links

NL = length(scenParam.PropagCondition);
LOSLinkIdx  = find(scenParam.PropagCondition > 0); 
NLOSLinkIdx = find(scenParam.PropagCondition == 0); 
N1 = scenParam.N(1);
N2 = scenParam.N(2);
NP = max(N1, N2);
NSP  = 20;

% +/- offset angles, resulting Laplacian APS, with rms AS = 1 degree
offset = [0.0447 0.1413 0.2492 0.3715 0.5129 0.6797 0.8844 1.1481 1.5195 2.1551]; 
         
% Reshape to cover all the clusters/path in columns and all the NSP subpaths in rows
offsetMatrix = [offset; -offset]; % [2, 10]
offsetMatrix = repmat(offsetMatrix(:), 1, NP, NL); % [NSP, NP*NL]

% Different AS_D/A per cluster for LoS/NLoA and AoD/AoA
if ~isempty(LOSLinkIdx)
    offsetMatrix_AoD(:,:,LOSLinkIdx) = scenParam.LoS.PerClusterAS_D * ...
        offsetMatrix(:,:,LOSLinkIdx);  % [1, eq. 4.14]
    offsetMatrix_AoA(:,:,LOSLinkIdx) = scenParam.LoS.PerClusterAS_A * ...
        offsetMatrix(:,:,LOSLinkIdx);  % [1, eq. 4.14]
end

if ~isempty(NLOSLinkIdx)
    offsetMatrix_AoD(:,:,NLOSLinkIdx) = scenParam.NLoS.PerClusterAS_D * ...
        offsetMatrix(:,:,NLOSLinkIdx);  % [1, eq. 4.14]
    offsetMatrix_AoA(:,:,NLOSLinkIdx) = scenParam.NLoS.PerClusterAS_A * ...
        offsetMatrix(:,:,NLOSLinkIdx);  % [1, eq. 4.14]
end

% Set ending paths to NaN when N1 ~= N2
if (N2 > N1) && (N1 > 0)
    offsetMatrix_AoD(:, end-(N2-N1)+1:end, LOSLinkIdx) = NaN;
    offsetMatrix_AoA(:, end-(N2-N1)+1:end, LOSLinkIdx) = NaN;
elseif (N2 < N1) && (N2 > 0)
    offsetMatrix_AoD(:, end-(N1-N2)+1:end, NLOSLinkIdx) = NaN;
    offsetMatrix_AoA(:, end-(N1-N2)+1:end, NLOSLinkIdx) = NaN;
end

% Reshape to 2D
AoDOffseMatrix = reshape(offsetMatrix_AoD, NSP, []);
AoAOffseMatrix = reshape(offsetMatrix_AoA, NSP, []);
 
end

function [PDPLOS, PDPNLOS] = getFixedPDP(scenario, range)
% Generate fixed path delays, path powers and cluster-wice K-factors for
% different scenarios. Note that Pprime power parameter values from CDL
% tables are changed to (non-dominant) ray powers. The information is same,
% but now the parameter values can be read directly from CDL tables. No
% change in B5 scenarios.

switch scenario   
  case 'A1'        
    % For LoS links
    PDPLOS.taus     = [0 10 25 50 65 75 75 115 115 145 195 350]*1e-9;  % Unit: seconds
    PDPLOS.P1       = 10.^(-[22.9 28.8 26.5 25.1 32.2 36.5 31.3 36.4 42.2 27.2 34.6 36.4]/10); % Linear scale
    PDPLOS.KCluster = [4.7; ...  % K-factors for CDL clusters [dB]
                       1];       % Cluster number

    % For NLoS links
    PDPNLOS.taus     = [0 5 5 5 15 15 15 20 20 35 80 85 110 115 150 175]*1e-9; 
    PDPNLOS.P1       = 10.^(-[15.2 19.7 15.1 18.8 16.3 17.7 17.1 21.2 13.0 14.6 23.0 25.1 25.4 24.8 33.4 29.6]/10); 
    PDPNLOS.KCluster = [-1000000; 1];             
  case 'A2'
    PDPLOS.taus     = NaN;
    PDPLOS.P1       = NaN;
    PDPLOS.KCluster = NaN;        

    PDPNLOS.taus     = [0 0 5 10 35 35 65 120 125 195 250 305]*1e-9;
    PDPNLOS.P1       = 10.^(-[13.0 21.7 16.7 24.9 29.2 19.9 13.4 23.3 33.7 29.1 34.0 35.9]/10); 
    PDPNLOS.KCluster = [-10000000; 1];
  case 'B1'        
    PDPLOS.taus     = [0 30 55 60 105 115 250 460]*1e-9;
    PDPLOS.P1       = 10.^(-[24.7 20.5 27.8 23.6 26.9 30.8 32.6 44.4]/10);
    PDPLOS.KCluster = [3.3; 1];

    % This one is not updated accordingly in D111, 15.2.2007. Values from LH
    PDPNLOS.taus     = [0 90 100 115 230 240 245 285 390 430 460 505 515 595 600 615]*1e-9;
    PDPNLOS.P1       = 10.^(-[14.0 13.0 13.9 21.1 21.6 24.7 25.0 25.9 32.6 36.9 35.1 38.6 36.4 45.2 44.7 42.9]/10); 
    PDPNLOS.KCluster = [-100000; 1 ];        
  case 'B2'        
    PDPLOS.taus     = NaN;
    PDPLOS.P1       = NaN;
    PDPLOS.KCluster = NaN;        

    PDPNLOS.taus     = [0 35 135 190 350 425 430 450 470 570 605 625 625 630 1600 2800]*1e-9;
    PDPNLOS.P1       = 10.^(-[13.0 18.4 15.0 21.2 34.8 38.5 41.7 33.8 43.7 47.9 47.5 44.5 48.3 50.5 18.7 20.7]/10);
    PDPNLOS.KCluster = [-100000; 1];         
  case 'B3'
    PDPLOS.taus     = [0 0 15 25 40 40 90 130 185 280]*1e-9;
    PDPLOS.P1       = 10.^(-[24.5 19.6 27.6 25.8 26.8 24.1 25.6 28.2 36.4 40.7]/10);
    PDPLOS.KCluster = [0.3; 1];

    PDPNLOS.taus     = [0 5 5 10 20 20 30 60 60 65 75 110 190 290 405]*1e-9;
    PDPNLOS.P1       = 10.^(-[19.6 13.0 24.0 14.3 20.1 15.7 17.3 28.1 19.2 22.1 18.5 24.1 24.8 30.1 37.9]/10);
    PDPNLOS.KCluster = [-10000000; 1];         
  case 'B4'
    PDPLOS.taus     = NaN;
    PDPLOS.P1       = NaN;
    PDPLOS.KCluster = NaN;        

    PDPNLOS.taus     = [0 0 5 10 35 35 65 120 125 195 250 305]*1e-9; 
    PDPNLOS.P1       = 10.^(-[13.0 21.7 16.7 24.9 29.2 19.9 13.4 23.3 33.7 29.1 34.0 35.9]/10);
    PDPNLOS.KCluster = [-10000000; 1];        
  case 'B5a'
    PDPLOS.taus     = [0 10 20 50 90 95 100 180 205 260]*1e-9;
    PDPLOS.P1       = 10.^([-0.39 -20.6 -26.8 -24.2 -15.3 -20.5 -28.0 -18.8 -21.6 -19.9 ]/10);
    PDPLOS.KCluster = [21.8; 1];

    PDPNLOS.taus     = NaN;
    PDPNLOS.P1       = NaN;
    PDPNLOS.KCluster = NaN;
  case 'B5b'
    if range == 1
        PDPLOS.taus     = [0 5 15 20 40 45 50 70 105 115 125 135 140 240 300 345 430 440 465 625]*1e-9;
        PDPLOS.P1       = 10.^([-0.37 -15.9 -22.2 -24.9 -26.6 -26.2 -22.3 -22.3 -29.5 -17.7 -29.6 -26.6 -23.4 -30.3 -27.7 -34.8 -38.5 -38.6 -33.7 -35.2 ]/10);
        PDPLOS.KCluster = [20.0; 1];
    elseif range == 2
        PDPLOS.taus     = [0 5 30 45 75 90 105 140 210 230 250 270 275 475 595 690 855 880 935 1245]*1e-9;
        PDPLOS.P1       = 10.^([-1.5 -10.2 -16.6 -19.2 -20.9 -20.6 -16.6 -16.6 -23.9 -12.0 -23.9 -21.0 -17.7 -24.6 -22.0 -29.2 -32.9 -32.9 -28.0 -29.6]/10); 
        PDPLOS.KCluster = [13.0; 1];
    else % range == 3
        PDPLOS.taus     = [0 10 90 135 230 275 310 420 630 635 745 815 830 1430 1790 2075 2570 2635 2800 3740]*1e-9;
        PDPLOS.P1       = 10.^([-2.6 -8.5 -14.8 -17.5 -19.2 -18.8 -14.9 -14.9 -22.1 -10.3 -22.2 -19.2 -16.0 -22.9 -20.3 -27.4 -31.1 -31.2 -26.3 -27.8]/10); 
        PDPLOS.KCluster = [10.0; 1]; 
    end

    PDPNLOS.taus     = NaN;
    PDPNLOS.P1       = NaN;
    PDPNLOS.KCluster = NaN;        
  case 'B5c'  % LOS PDP is the same as B1
    PDPLOS.taus     = [0 30 55 60 105 115 250 460]*1e-9;
    PDPLOS.P1       = 10.^([0 -11.7 -14.8 -14.8 -13.9 -17.8 -19.6 -31.4]/10);
    PDPLOS.KCluster = [3.3; 1];

    PDPNLOS.taus     = NaN;
    PDPNLOS.P1       = NaN;
    PDPNLOS.KCluster = NaN;                
  case 'B5f'     
    PDPLOS.taus     = NaN;
    PDPLOS.P1       = NaN;
    PDPLOS.KCluster = NaN;                

    PDPNLOS.taus     = [0 10 20 50 90 95 100 180 205 260]*1e-9;
    PDPNLOS.P1       = 10.^([-0.1 -5.3 -11.5 -8.9 0.0 -5.2 -12.7 -3.5 -6.3 -4.6]/10);
    PDPNLOS.KCluster = [-10000000; 1]; 
  case 'C1'
    PDPLOS.taus     = [0 85 135 135 170 190 275 290 290 410 445 500 620 655 960]*1e-9;
    PDPLOS.P1       = 10.^(-[33.1 34.7 39.3 38.1 38.4 35.0 42.2 34.3 36.2 45.2 39.5 45.1 41.5 43.5 45.6]/10);
    PDPLOS.KCluster = [12.9; 1];

    PDPNLOS.taus    = [0 25 35 35 45 65 65 75 145 160 195 200 205 770]*1e-9;
    PDPNLOS.P1      = 10.^(-[13.0 20.5 23.5 16.2 16.1 27.0 19.4 16.1 17.6 21.0 20.2 16.1 22.5 35.4]/10); 
    PDPNLOS.KCluster = [-10000000; 1];
  case 'C2'        
    PDPLOS.taus     = [0 0 30 85 145 150 160 220]*1e-9;
    PDPLOS.P1       = 10.^(-[30.6 26.2 28.3 29.7 28.2 31.2 28.3 36.1]/10);
    PDPLOS.KCluster = [7.0; 1];

    PDPNLOS.taus     = [0 60 75 145 150 190 220 335 370 430 510 685 725 735 800 960 1020 1100 1210 1845]*1e-9; 
    PDPNLOS.P1       = 10.^(-[19.5 16.4 15.0 13.0 14.9 16.4 13.4 17.7 20.8 20.8 22.3 25.0 21.5 26.2 24.2 33.8 27.5 24.7 30.2 29.7]/10); 
    PDPNLOS.KCluster = [-1000000; 1];
  case 'C3'
    PDPLOS.taus     = NaN;
    PDPLOS.P1       = NaN;
    PDPLOS.KCluster = NaN;

    PDPNLOS.taus     = [0 5 35 60 160 180 240 275 330 335 350 520 555 555 990 1160 1390 1825 4800 7100]*1e-9;
    PDPNLOS.P1       = 10.^(-[16.5 22.0 17.6 22.2 13.0 14.7 15.7 20.0 18.9 19.7 14.3 18.3 17.9 22.4 25.3 25.2 33.8 38.4 22.7 26.0]/10);
    PDPNLOS.KCluster = [-100000; 1];                   
  case 'C4'
    PDPLOS.taus     = NaN;
    PDPLOS.P1       = NaN;
    PDPLOS.KCluster = NaN;

    PDPNLOS.taus     = [0 15 95 145 195 215 250 445 525 815 1055 2310]*1e-9;
    PDPNLOS.P1       = 10.^(-[13.0 19.9 16.6 29.3 21.5 28.9 19.9 27.1 13.8 26.6 30.8 45.2]/10);
    PDPNLOS.KCluster = [-100000; 1];
  case 'D1'    
    PDPLOS.taus     = [0 20 20 25 45 65 65 90 125 180 190]*1e-9;
    PDPLOS.P1       = 10.^(-[22.8 28.5 29.2 25.3 33.5 31.9 34.2 36.6 39.1 42.4 41.3]/10);
    PDPLOS.KCluster = [5.7; 1];

    PDPNLOS.taus     = [0 0 5 10 20 25 55 100 170 420]*1e-9;
    PDPNLOS.P1       = 10.^(-[13.0 14.8 16.3 14.8 18.3 20.1 22.0 17.2 25.4 39.5]/10);
    PDPNLOS.KCluster = [-10000000; 1];
  otherwise % 'D2a'
    PDPLOS.taus     = [0 45 60 85 100 115 130 210]*1e-9;
    PDPLOS.P1       = 10.^(-[28.8 27.8 30.2 29.5 28.1 28.7 30.8 30.3]/10);
    PDPLOS.KCluster = [6.0; 1];

    PDPNLOS.taus     = NaN;
    PDPNLOS.P1       = NaN;
    PDPNLOS.KCluster = NaN;
end

end

function [AoDForLOS, clusterASDForLOS, AoDForNLOS, clusterASDForNLOS] = getFixedAoD(scenario, range)
% Generate fixed AoDs for different scenarios. 

switch scenario
  case 'A1'
    AoDForLOS = [0 -107 -100 131 118 131 116 131 146 102 -126 131];
    clusterASDForLOS = 5;      % Cluster ASD [deg], [1, table 6-1]

    AoDForNLOS = [45 77 43 72 54 -65 -60 85 0 -104 95 -104 -105 103 -135 -122];
    clusterASDForNLOS = 5;      % Cluster ASD [deg], [1, table 6-2]
 case 'A2'        
    AoDForNLOS = [0 102 -66 -119 139 91 157 -111 157 138 158 165];
    clusterASDForNLOS = 8;      

    AoDForLOS = NaN;
    clusterASDForLOS = NaN;      
  case 'B1'        
    AoDForLOS = [0 5 8 8 7 8 -9 11];
    clusterASDForLOS = 3;      

    AoDForNLOS = [8 0 -24 -24 -24 29 29 30 -37 41 -39 -42 -40 47 47 46];
    clusterASDForNLOS = 10; 
  case 'B2'
    AoDForLOS = NaN;
    clusterASDForLOS = NaN;    
    
    AoDForNLOS = [0 20 40 25 40 -44 -46 39 -48 -51 -51 -48 -51 53 -110 75];
    clusterASDForNLOS = 10;
  case 'B3'
    AoDForLOS = [0 -23 -34 -32 33 -35 32 -35 -43 47];
    clusterASDForLOS = 5;  

    AoDForNLOS = [-16 0 -21 -10 17 -10 -13 -24 -16 19 -15 -21 22 -26 -32];
    clusterASDForNLOS = 6; 
 case 'B4'
    AoDForLOS = NaN;
    clusterASDForLOS = NaN;      
    
    AoDForNLOS = [29 0 20 -18 18 20 29 24 29 -21 36 46];
    clusterASDForNLOS = 5;
  case 'B5a'
    AoDForLOS =[0 0.9 0.3 -0.3 3.9 -0.8 4.2 -1.0 5.5 7.6];
    clusterASDForLOS = 0.5;     

    AoDForNLOS = NaN;
    clusterASDForNLOS = NaN;         
  case 'B5b'    
    if range == 1
        AoDForLOS = [0 -71.7 167.4 -143.2 34.6 -11.2 78.2 129.2 -113.2 -13.5 145.2 -172.0 93.7 106.5 -67.0 -95.1 -2.0 66.7 160.1 -21.8];
        clusterASDForLOS = 2;
    elseif range == 2
        AoDForLOS = [0 -71.7 167.4 -143.2 34.6 -11.2 78.2 129.2 -113.2 -13.5 145.2 -172.0 93.7 106.5 -67.0 -95.1 -2.0 66.7 160.1 -21.8];
        clusterASDForLOS = 2;
    else % range == 3
        AoDForLOS = [0 -71.7 167.4 -143.2 34.6 -11.2 78.2 129.2 -113.2 -13.5 145.2 -172.0 93.7 106.5 -67.0 -95.1 -2.0 66.7 160.1 -21.8];
        clusterASDForLOS = 2;
    end

    AoDForNLOS = NaN;
    clusterASDForNLOS = NaN;      
  case 'B5c' 
    AoDForLOS = [0 5 8 8 7 8 -9 11];
    clusterASDForLOS = 3; 

    AoDForNLOS = NaN;
    clusterASDForNLOS = NaN;         
  case 'B5f'
    AoDForLOS = NaN;
    clusterASDForLOS = NaN;          
    
    AoDForNLOS = [0 0.9 0.3 -0.3 3.9 -0.8 4.2 -1.0 5.5 7.6];
    clusterASDForNLOS = 0.5; 
  case 'C1'
    AoDForLOS = [0 -29 -32 -31 31 29 -33 35 -30 35 -32 35 33 34 35];
    clusterASDForLOS = 5;  

    AoDForNLOS = [0 13 -15 -8 12 -17 12 -8 -10 -13 12 8 14 22];
    clusterASDForNLOS = 2;
  case 'C2'
    AoDForLOS = [0 -24 26 -27 26 28 26 -32];
    clusterASDForLOS = 6; 

    AoDForNLOS = [11 -8 -6 0 6 8 -12 -9 -12 -12 13 15 -12 -15 -14 19 -16 15 18 17];
    clusterASDForNLOS = 2;  
 case 'C3'
    AoDForLOS = NaN;
    clusterASDForLOS = NaN;        
    
    AoDForNLOS = [-9 14 -10 -14 0 -6 7 -12 11 -12 -10 -10 -10 14 16 16 21 -23 -135 80];
    clusterASDForNLOS = 2; 
  case 'C4'
    AoDForLOS = NaN;
    clusterASDForLOS = NaN;     
    
    AoDForNLOS = [0 28 -20 43 -31 43 28 -40 45 -39 45 -61];
    clusterASDForNLOS = 5;
  case 'D1'
    AoDForLOS = [0 17 17 18 -19 28 -19 -20 -22 23 -22];
    clusterASDForLOS = 2;

    AoDForNLOS = [0 -8 -10 15 13 15 -17 -12 20 29];
    clusterASDForNLOS = 2;
  case 'D2a'
    AoDForLOS = [0 12.7 -13.6 13.4 -13.9 -13 -13.9 13.7];
    clusterASDForLOS = 2;  

    AoDForNLOS = NaN;
    clusterASDForNLOS = NaN; 
end 

end

function [AoAForLOS, clusterASAForLOS, AoAForNLOS,clusterASAForNLOS] = getFixedAoA(scenario, range)
% Generate fixed AoAs for different scenarios. 
% xxx consider merging this function with getFixedAoD

switch scenario
  case 'A1'
    AoAForLOS = [0 -110 102 -134 121 -134 -118 -134 149 105 129 -134];
    clusterASAForLOS = 5;      % Cluster ASA [deg], [1, table 7-1]
    
    AoAForNLOS = [41 -70 39 66 -49 59 -55 -78 0 95 86 95 -96 -94 123 -111];
    clusterASAForNLOS = 5;      % Cluster ASA [deg], [1, table 7-2]
  case 'A2'
    AoAForLOS = NaN;
    clusterASAForLOS = NaN; 
    
    AoAForNLOS = [0 32 -21 37 -43 28 -49 -34 -49 43 49 51];
    clusterASAForNLOS = 5;      
  case 'B1'
    AoAForLOS = [0 45 63 -69 61 -69 -73 92];
    clusterASAForLOS = 18;

    AoAForNLOS = [-20 0 57 -55 57 67 -68 70 -86 -95 -92 -99 94 111 110 -107];
    clusterASAForNLOS = 22;
  case 'B2'
    AoAForLOS = NaN;
    clusterASAForLOS = NaN; 

    AoAForNLOS = [0 -46 -92 57 -92 -100 -106 90 -110 -117 -116 -111 -118 121 15 -25];
    clusterASAForNLOS = 22;  
  case 'B3'
    AoAForLOS = [0 -53 -79 -74 76 80 -73 80 -100 -108];
    clusterASAForLOS = 5; 

    AoAForNLOS = [-73 0 -94 -46 75 -46 -59 107 71 86 67 95 98 117 142];
    clusterASAForNLOS = 13;
  case 'B4'
    AoAForLOS = NaN;
    clusterASAForLOS = NaN; 

    AoAForNLOS = [0 102 -66 -119 139 91 157 -111 157 138 158 165];
    clusterASAForNLOS = 8;  
  case 'B5a'
    AoAForLOS = [0 0.2 1.5 2.0 0 3.6 -0.7 4.0 -2.0 -4.1];
    clusterASAForLOS = 0.5;  
    
    AoAForNLOS = NaN;
    clusterASAForNLOS = NaN;     
  case 'B5b'            
    if range == 1
        AoAForLOS = [0 70 -27.5 106.4 94.8 -94.0 48.6 -96.6 41.7 -83.3 176.8 93.7 -6.4 160.3 -50.1 -149.6 161.5 68.7 41.6 142.2];
        clusterASAForLOS = 2; 
    elseif range == 2
        AoAForLOS = [0 70 -27.5 106.4 94.8 -94.0 48.6 -96.6 41.7 -83.3 176.8 93.7 -6.4 160.3 -50.1 -149.6 161.5 68.7 41.6 142.2];
        clusterASAForLOS = 2; 
    else % range == 3
        AoAForLOS = [0 70 -27.5 106.4 94.8 -94.0 48.6 -96.6 41.7 -83.3 176.8 93.7 -6.4 160.3 -50.1 -149.6 161.5 68.7 41.6 142.2];
        clusterASAForLOS = 2;
    end

    AoAForNLOS = NaN;
    clusterASAForNLOS = NaN; 
  case 'B5c'
    AoAForLOS = [0 45 63 -69 61 -69 -73 92];
    clusterASAForLOS = 18; 

    AoAForNLOS = NaN;
    clusterASAForNLOS = NaN; 
  case 'B5f'
    AoAForLOS = NaN;
    clusterASAForLOS = NaN; 
    
    AoAForNLOS = [0 0.2 1.5 2.0 0 3.6 -0.7 4.0 -2.0 -4.1];
    clusterASAForNLOS = 0.5;  
  case 'C1'
    AoAForLOS = [0 -144 -159 155 156 -146 168 -176 149 -176 -159 -176 -165 -171 177];
    clusterASAForLOS = 5;   

    AoAForNLOS = [0 -71 -84 46 -66 -97 -66 -46 -56 73 70 -46 -80 123];
    clusterASAForNLOS = 10; 
  case 'C2'
    AoAForLOS = [0 -120 129 -135 -129 141 -129 -158];
    clusterASAForLOS = 12; 

    AoAForNLOS = [61 44 -34 0 33 -44 -67 52 -67 -67 -73 -83 -70 87 80 109 91 -82 99 98];
    clusterASAForNLOS = 15;
  case 'C3'
    AoAForLOS = NaN;
    clusterASAForLOS = NaN; 

    AoAForNLOS = [-52 -83 -60 -85 0 -36 46 74 68 -72 -62 -64 -62 85 -98 -97 127 140 25 40];
    clusterASAForNLOS = 15;
  case 'C4'
    AoAForLOS = NaN;
    clusterASAForLOS = NaN; 

    AoAForNLOS = [0 -91 65 -139 101 -138 -91 130 -146 128 -146 196];
    clusterASAForNLOS = 8; 
  case 'D1'
    AoAForLOS = [0 44 -45 -48 50 -48 51 -54 57 -60 59];
    clusterASAForLOS = 3; 

    AoAForNLOS = [0 28 38 -55 48 -55 62 42 -73 107];
    clusterASAForNLOS = 3;
  case 'D2a'
    AoAForLOS = [0 -80 86 84.4 87.5 -82.2 87.5 86.2];
    clusterASAForLOS = 3;   

    AoAForNLOS = NaN;
    clusterASAForNLOS = NaN; 
end

end
function scatterFreq = getB5FixedScatterFreq(scenario, fc)
% Fixed Doppler frequencies of scatterers. For B5 scenarios only.

NSP = 20; % wimpar.NumSubPathsPerPath;
switch scenario 
  case 'B5a'
    scatterFreq = [41.6,-21.5,-65.2,76.2,10.5,-20.2,1.3,2.2,-15.4,48.9]*fc/5.25e9*1e-3;
    scatterFreq = [scatterFreq; zeros(NSP-1,length(scatterFreq))];
  case 'B5b'
    scatterFreq = [744,-5,-2872,434,295,118,2576,400,71,3069,1153,-772,1298, ...
                   -343,-7,-186,-2287,26,-1342,-61]*fc/5.25e9*1e-3;
    scatterFreq = [scatterFreq; zeros(NSP-1,length(scatterFreq))];

  case 'B5c'
    scatterFreq = [-127,385,-879,0,0,-735,-274,691]*fc/5.25e9*1e-3;
    scatterFreq = [scatterFreq; zeros(NSP-1,length(scatterFreq))];
    scatterFreq(:,4) = (45:0.5:54.5)'    * fc / 5.25e9*1e-3;
    scatterFreq(:,5) = (-55:-0.5:-64.5)' * fc / 5.25e9*1e-3;

  otherwise % 'B5f'
    scatterFreq = [41.6,-21.5,-65.2,76.2,10.5,-20.2,1.3,2.2,-15.4,48.9]*fc/5.25e9*1e-3;
    scatterFreq = [scatterFreq;zeros(NSP-1,length(scatterFreq))];
end

end

% [EOF]