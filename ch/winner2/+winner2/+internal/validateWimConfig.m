function validateWimConfig(cfgWim)
%VALIDATEWIMCONFIG Validate WINNER II model parameter configuration

% Copyright 2016 The MathWorks, Inc.

validateattributes(cfgWim,{'struct'},{'scalar','nonempty'}, ...
    'validateWimConfig', 'the model parameter configuration');

% Check all necessary fields are present
expFields = fields(winner2.wimparset);
for i = 1:length(expFields)
    coder.internal.errorIf(~isfield(cfgWim, expFields{i}), ...
        'winner2:validateWimConfig:MissingField', expFields{i});
end

% Validate 'NumTimeSamples' field
validateattributes(cfgWim.NumTimeSamples,{'double'}, ...
    {'real','positive','integer','scalar','finite'}, ...
    'validateWimConfig', 'the cfgWim.NumTimeSamples');

% Validate 'FixedPdpUsed' field
validatestring(cfgWim.FixedPdpUsed,{'yes','no'}, ...
    'validateWimConfig', 'the cfgWim.FixedPdpUsed');

% Validate 'FixedAnglesUsed' field
validatestring(cfgWim.FixedAnglesUsed,{'yes','no'}, ...
    'validateWimConfig', 'the cfgWim.FixedAnglesUsed');

% Validate 'IntraClusterDsUsed' field
validatestring(cfgWim.IntraClusterDsUsed,{'yes','no'}, ...
    'validateWimConfig', 'the cfgWim.IntraClusterDsUsed');

% Validate 'PolarisedArrays' field
validatestring(cfgWim.PolarisedArrays,{'yes','no'}, ...
    'validateWimConfig', 'the cfgWim.PolarisedArrays');

% Validate 'UseManualPropCondition' field
validatestring(cfgWim.UseManualPropCondition,{'yes','no'}, ...
    'validateWimConfig', 'the cfgWim.UseManualPropCondition');

% Validate 'UniformTimeSampling' field
validatestring(cfgWim.UniformTimeSampling,{'yes','no'}, ...
    'validateWimConfig', 'the cfgWim.UniformTimeSampling');

% Validate 'SampleDensity' field
validateattributes(cfgWim.SampleDensity,{'double'}, ...
    {'real','integer','scalar','>',1,'finite'}, ...
    'validateWimConfig', 'the cfgWim.SampleDensity');

% Validate 'CenterFrequency' field
validateattributes(cfgWim.CenterFrequency,{'double'}, ...
    {'real','positive','scalar','finite'}, ...
    'validateWimConfig', 'the cfgWim.CenterFrequency');

% Validate 'DelaySamplingInterval' field
validateattributes(cfgWim.DelaySamplingInterval,{'double'}, ...
    {'real','nonnegative','scalar','finite'}, ...
    'validateWimConfig', 'the cfgWim.DelaySamplingInterval');

% Validate 'ShadowingModelUsed' field
validatestring(cfgWim.ShadowingModelUsed,{'yes','no'}, ...
    'validateWimConfig', 'the cfgWim.ShadowingModelUsed');

% Validate 'PathLossModelUsed' field
validatestring(cfgWim.PathLossModelUsed,{'yes','no'}, ...
    'validateWimConfig', 'the cfgWim.PathLossModelUsed');

% Do not validate 'range' field which doesn't apply to any supported scenario
% validateattributes(cfgWim.range,{'numeric'}, ...
%    {'real','integer','>=',1,'<=',3}, ...
%    'validateWimConfig', 'the cfgWim.range');    
    
if strcmp(cfgWim.PathLossModelUsed, 'yes')
    % Validate 'PathLossModel' field
    coder.internal.errorIf(~ischar(cfgWim.PathLossModel) || ...
        ~isrow(cfgWim.PathLossModel), ...
        'winner2:validateWimConfig:InvalidPathLossFile');
    fullFileName = which(cfgWim.PathLossModel);
    coder.internal.errorIf(~strcmp(cfgWim.PathLossModel, 'pathloss') && ...
        isempty(fullFileName), ...
        'winner2:validateWimConfig:PathLossFileNotExist', ...
        cfgWim.PathLossModel)
    
    % Validate 'PathLossOption' field
    validatestring(cfgWim.PathLossOption, ...
        {'CR_light','CR_heavy','RR_light','RR_heavy'}, ...
        'validateWimConfig', 'the cfgWim.PathLossOption');
    
    % Do not validate 'end_time' field which only applies to B5 scenarios
    % validateattributes(cfgWim.end_time,{'double'}, ...
    %    {'real','positive','scalar','finite'}, ...
    %    'validateWimConfig', 'the cfgWim.end_time');    
end

% Validate 'RandomSeed' field
if ~isempty(cfgWim.RandomSeed)
    validateattributes(cfgWim.RandomSeed,{'double'}, ...
        {'real','nonnegative','integer','scalar','finite'}, ...
        'validateWimConfig', 'the cfgWim.RandomSeed');    
end

% Warn if the NumSubPathsPerPath field is present, but not equal to 20
if isfield(cfgWim, 'NumSubPathsPerPath') && (cfgWim.NumSubPathsPerPath ~= 20)
    coder.internal.warning('winner2:validateWimConfig:NumRaysNot20');
end

% Warn if the TimeEvolution field is present, but not set to 'no'
if isfield(cfgWim, 'TimeEvolution') && ~strcmpi(cfgWim.TimeEvolution, 'no')
    coder.internal.warning('winner2:validateWimConfig:NoTimeEvolution');
end

end

% [EOF]