function validateAntennaArray(arrays, hasVelocityField, AAName)
%VALIDATEANTENNAARRAY Validate a vector of antenna array structures

% Copyright 2016 The MathWorks, Inc.

validateattributes(arrays,{'struct'},{'vector','nonempty'}, ...
    'validateAntennaArray', ['the ' AAName]);
numAA = length(arrays);

% Validate necessary fields
expFields = {'Name', 'Pos', 'Rot', 'Element'};
if hasVelocityField
    expFields{end + 1} = 'Velocity';
end
for i = 1:length(expFields)    
    coder.internal.errorIf(~isfield(arrays, expFields{i}), ...
        'winner2:validateAntennaArray:MissingField', expFields{i}, AAName);
end

expElementFields = {'Pos', 'Rot'};
for i = 1:numAA
    % Validate 'Name' field
    coder.internal.errorIf(~ischar(arrays(i).Name) || ~isrow(arrays(i).Name), ...
        'winner2:validateAntennaArray:InvalidName', AAName);

    % Validate 'Pos' field
    validateattributes(arrays(i).Pos,{'double'}, ...
        {'real','size',[3,1],'nonnegative','finite'}, 'validateAntennaArray', ...
        ['the ''Pos'' field of ', AAName]);
    
    % Validate 'Rot' field
    validateattributes(arrays(i).Rot,{'double'}, ...
        {'real','size',[3,1],'finite'}, 'validateAntennaArray', ...
        ['the ''Rot'' field of ', AAName]);
    
    % Validate 'Element' field
    validateattributes(arrays(i).Element,{'struct'},{'row','nonempty'}, ...
        'validateAntennaArray', ['the ''Element'' field of ', AAName]);    
    
    for k = 1:length(expElementFields)    
        coder.internal.errorIf( ...
            ~isfield(arrays(i).Element, expElementFields{k}), ...
            'winner2:validateAntennaArray:MissingElementField', ...
            expElementFields{k}, AAName);
    end
    
    for j = 1:length(arrays(i).Element)
        % Validate 'Element.Pos' field
        validateattributes(arrays(i).Element(j).Pos,{'double'}, ...
            {'real','size',[3,1],'finite'}, 'validateAntennaArray', ...
            ['the ''Element.Pos'' field of ', AAName]);
        
        % Validate 'Element.Rot' field
        validateattributes(arrays(i).Element(j).Rot,{'double'}, ...
            {'real','size',[3,1],'finite'}, 'validateAntennaArray', ...
            ['the ''Element.Rot'' field of ', AAName]);
        
        if isfield(arrays(1).Element, 'Aperture')
            validateAperture(arrays(i).Element(j).Aperture, ...
                'Element.Aperture', AAName);
        end        
    end
    
    if hasVelocityField
        validateattributes(arrays(i).Velocity,{'double'}, ...
            {'real','size',[3,1],'finite'}, 'validateAntennaArray', ...
            ['the ''Velocity'' field of ', AAName]);
    end
    
    if isfield(arrays, 'Aperture')
        validateAperture(arrays(i).Aperture, 'Aperture', AAName)
    end    
end

end

function validateAperture(aperStruct, aperName, AAName)
% xxx The value checking here could be more strict

validateattributes(aperStruct,{'struct'},{'scalar'}, ...
    'validateAntennaArray', ['the ''', aperName, ''' field of ', AAName]); 

% Validate necessary fields
expFields = {'pol', 'elements', 'saz', 'sele', 'G13', 'G24'};
for i = 1:length(expFields)    
    coder.internal.errorIf(~isfield(aperStruct, expFields{i}), ...
        'winner2:validateAntennaArray:MissingApertureField', ...
        expFields{i}, AAName);
end

% Validate 'pol' field
validateattributes(aperStruct.pol,{'numeric'},{'real','scalar'}, ...
    'validateAntennaArray', ...
    ['the ''', aperName, '.pol'' field of ', AAName]);

% Validate 'elements' field
validateattributes(aperStruct.elements,{'numeric'},{'real','scalar'}, ...
    'validateAntennaArray', ...
    ['the ''', aperName, '.elements'' field of ', AAName]);

% Validate 'saz' field
validateattributes(aperStruct.saz,{'numeric'},{'real','scalar'}, ...
    'validateAntennaArray', ...
    ['the ''', aperName, '.saz'' field of ', AAName]);

% Validate 'sele' field
validateattributes(aperStruct.sele,{'numeric'},{'real','scalar'}, ...
    'validateAntennaArray', ...
    ['the ''', aperName, '.sele'' field of ', AAName]);

% Validate 'G13' field
validateattributes(aperStruct.G13,{'double'},{'row'}, ...
    'validateAntennaArray', ...
    ['the ''', aperName, '.G13'' field of ', AAName]);

% Validate 'G24' field
validateattributes(aperStruct.G24,{'double'},{'row'}, ...
    'validateAntennaArray', ...
    ['the ''', aperName, '.G24'' field of ', AAName]);

end

% [EOF]