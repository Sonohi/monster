function [H, D, finalCond] = wim(cfgWim, cfgLayout, initCond)
%WIM Generate channel coefficients using WINNER II channel model without
%input argument validation

% Copyright 2016 The MathWorks, Inc.

% Derive link parameters
cfgLink = winner2.internal.layout2Link(cfgLayout);

% Read fixed scenario dependent parameters from a table
fixpar = winner2.internal.getScenarioParam(cfgLink.StreetWidth(1)); 

% Number of links
numLinks = size(cfgLink.Pairing, 2);

% Links for B5 and non-B5 scenarios
nonB5Idx = find((cfgLink.ScenarioVector < 7 | cfgLink.ScenarioVector > 9));
B5Idx = setdiff(1:numLinks, nonB5Idx);

if nargin == 2 % Generate random bulk parameters for all links
    % Cannot switch to use rng as rand and randn are controlled by separate
    % generators in legacy mode
    if ~isempty(cfgWim.RandomSeed)
        s = rng; % Save current settings of the generator
        % rand( 'state', cfgWim.RandomSeed); 
        uniStream  = RandStream('v5uniform','Seed',cfgWim.RandomSeed);
        % randn('state', cfgWim.RandomSeed); 
        normStream = RandStream('v5normal','Seed',cfgWim.RandomSeed);
    else
        uniStream  = RandStream.getGlobalStream;
        normStream = RandStream.getGlobalStream;
    end

    bulkpar = winner2.internal.generateBulkParam( ...
        cfgWim, cfgLink, fixpar, uniStream, normStream); 
    
    if ~isempty(cfgWim.RandomSeed)
        rng(s);  % Restore previous settings of the generator.
    end
else % State-in-state-out    
    bulkpar = initCond;
    
    % Remove intra cluster delay spread effects from initial values
    if strcmp(cfgWim.IntraClusterDsUsed,'yes') && ~isempty(nonB5Idx)
        numPaths = size(initCond.delays, 2); 
        bulkpar.delays      = nan(numLinks, numPaths - 4);
        bulkpar.path_powers = nan(numLinks, numPaths - 4);
        
        % Path delay and power stay the same for B5 scenarios
        if ~isempty(nonB5Idx)
            bulkpar.delays(B5Idx,:)      = initCond.delays(B5Idx, 1:numPaths-4);
            bulkpar.path_powers(B5Idx,:) = initCond.path_powers(B5Idx, 1:numPaths-4);
        end
        
        for i = 1:length(nonB5Idx)
            linkIdx = nonB5Idx(i);
            pathIdxToRemove = [initCond.IndexOfDividedClust(linkIdx,1)+(1:2), ...
                               initCond.IndexOfDividedClust(linkIdx,2)+(3:4)];
            pathIdxToKeep = setdiff(1:numPaths, pathIdxToRemove);
            % Remove intra cluster delay values from initial values
            bulkpar.delays(linkIdx, :) = initCond.delays(linkIdx, pathIdxToKeep);
            % Remove intra cluster power values from initial values
            bulkpar.path_powers(linkIdx, :) = initCond.path_powers(linkIdx, pathIdxToKeep);
        end
    end
end

% Perform antenna field pattern interpolation. Since elevation will not be
% supported, dismiss the elevation dimension for now.
aods = bulkpar.aods; % Unit: degree
aoas = bulkpar.aoas; % Unit: degree

% Perform gain pattern interpolation
BsGainPattern = winner2.internal.calcAntennaResponse( ...
    cfgLink.Stations(cfgLink.Pairing(1,:)), pi/2-aods*pi/180);
MsGainPattern = winner2.internal.calcAntennaResponse( ...
    cfgLink.Stations(cfgLink.Pairing(2,:)), pi/2-aoas*pi/180);

% Perform antenna field pattern interpolation
BsGainLOS = winner2.internal.calcAntennaResponse( ...
    cfgLink.Stations(cfgLink.Pairing(1,:)), pi/2 - cfgLink.ThetaBs(:) * pi/180);
MsGainLOS = winner2.internal.calcAntennaResponse( ...
    cfgLink.Stations(cfgLink.Pairing(2,:)), pi/2 - cfgLink.ThetaMs(:) * pi/180);

% Channel matrix generation
[H, finalCond] = winner2.internal.generatePathGains( ...
    cfgWim, cfgLink, bulkpar, ...
    BsGainPattern, ...
    BsGainLOS, ...            
    MsGainPattern, ...
    MsGainLOS, ...            
    0);  

% Apply path loss
if strcmpi(cfgWim.PathLossModelUsed, 'yes')
    H = cellfun(@times, H, num2cell(sqrt(bulkpar.path_losses)), ...
        'UniformOutput', false);
end

% Apply shadowing
if strcmpi(cfgWim.ShadowingModelUsed, 'yes')
    H = cellfun(@times, H, num2cell(sqrt(bulkpar.shadow_fading)), ...
        'UniformOutput', false);
end

D = finalCond.delays;

end

% [EOF]