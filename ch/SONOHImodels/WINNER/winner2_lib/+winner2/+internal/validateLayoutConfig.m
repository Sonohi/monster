function validateLayoutConfig(cfgLayout, performIndChk, performCrossChk)
%VALIDATELAYOUTCONFIG Validate WINNER II layout parameter configuration

% Copyright 2016 The MathWorks, Inc.

% Check all necessary fields are present
expFields = {'Stations','NofSect','Pairing','ScenarioVector', ...
    'PropagConditionVector','StreetWidth', ...
    'Dist1','NumFloors','NumPenetratedFloors'};

if performIndChk
    validateattributes(cfgLayout,{'struct'},{'scalar','nonempty'}, ...
        'validateLayoutConfig', 'the layout parameter configuration');

    for i = 1:length(expFields)
        coder.internal.errorIf(~isfield(cfgLayout, expFields{i}), ...
            'winner2:validateLayoutConfig:MissingField', expFields{i});
    end

    % Validate 'Stations' field
    winner2.internal.validateAntennaArray(cfgLayout.Stations, true, ...
        'Stations field');

    % Validate 'Pairing' field
    pairing = cfgLayout.Pairing;
    validateattributes(pairing,{'numeric'}, ...
        {'real','positive','integer','finite','2d','nrows',2}, ...
        'validateLayoutConfig', 'the cfgLayout.Pairing');
    % MS indexing numbers must be larger than BS indexing numbers 
    coder.internal.errorIf(max(pairing(1,:)) >= min(pairing(2,:)), ... 
        'winner2:validateLayoutConfig:BSIdxLargerThanMSIdx');
    % Check uniqueness of the NL links
    coder.internal.errorIf(...
        length(unique([max(pairing(:)) 1] * pairing)) ~= size(pairing, 2), ...
        'winner2:validateLayoutConfig:RepetitiveLinks');

    % Validate 'NofSect' field
    validateattributes(cfgLayout.NofSect,{'numeric'}, ...
        {'real','positive','integer','vector','finite'}, ...
        'validateLayoutConfig', 'the cfgLayout.NofSect');

    % Validate 'ScenarioVector' field
    validateattributes(cfgLayout.ScenarioVector,{'numeric'}, ...
        {'real','integer','row','>=',1,'<=',15}, ...
        'validateLayoutConfig', 'the cfgLayout.ScenarioVector');
    coder.internal.errorIf(any((cfgLayout.ScenarioVector >= 7) & ...
        (cfgLayout.ScenarioVector <= 9)), ...
        'winner2:validateLayoutConfig:NotSupportB5');

    % Validate 'PropagConditionVector' field
    validateattributes(cfgLayout.PropagConditionVector,{'numeric'}, ...
        {'real','integer','row','>=',0,'<=',1}, ...
        'validateLayoutConfig', 'the cfgLayout.PropagConditionVector');

    % Validate 'StreetWidth' field
    validateattributes(cfgLayout.StreetWidth,{'double'},{'real', ...
        'positive','row','finite','nonincreasing','nondecreasing'}, ...
        'validateLayoutConfig', 'the cfgLayout.StreetWidth');

    % Validate 'Dist1' field
    dist1 = cfgLayout.Dist1;
    validateattributes(dist1,{'double'},{'real','positive','row'}, ...
        'validateLayoutConfig', 'the cfgLayout.Dist1');
    % Check all non-NaN elements to be finite
    validateattributes(dist1(~isnan(dist1)),{'double'},{'finite'}, ...
        'validateLayoutConfig', 'the non-NaN elements in cfgLayout.Dist1');

    % Validate 'NumFloors' field
    validateattributes(cfgLayout.NumFloors,{'numeric'}, ...
        {'real','nonnegative','integer','finite','row',}, ...
        'validateLayoutConfig', 'the cfgLayout.NumFloors');

    % Validate 'NumPenetratedFloors' field
    validateattributes(cfgLayout.NumPenetratedFloors,{'numeric'}, ...
        {'real','nonnegative','integer','finite','row'}, ...
        'validateLayoutConfig', 'the cfgLayout.NumPenetratedFloors');

    % MS velocity must be 0 for B5 scenarios. Enable this when B5 is supported
end

if performCrossChk
    pairing = cfgLayout.Pairing;
    
    % Numbers in 'Pairing' field must be no larger than number of stations
    coder.internal.errorIf(any(pairing(:) > length(cfgLayout.Stations)),...
        'winner2:validateLayoutConfig:StnIdxExceedNumStn');
   
    % Total number of sections cannot exceed the minimum MS index
    coder.internal.errorIf(sum(cfgLayout.NofSect) >= min(pairing(2,:)), ...
        'winner2:validateLayoutConfig:TooManySectors');
    
    for i = 4:length(expFields) 
        % Each field after 'Pairing' must be of length NL
        coder.internal.errorIf( ...
            length(cfgLayout.(expFields{i})) ~= size(pairing, 2), ...
            'winner2:validateLayoutConfig:NumLinksMismatch', expFields{i});
    end
end

end

% [EOF]