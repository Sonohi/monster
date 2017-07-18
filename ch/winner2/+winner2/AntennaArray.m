function AA = AntennaArray(varargin)
%ANTENNAARRAY Construct an antenna array
%  
%   AA = WINNER2.ANTENNAARRAY returns a structure AA representing an
%   antenna array at position [0;0;0] and without any rotation. It has one
%   antenna element represented by a structure in its 'Element' field. The
%   element is also at position [0;0;0] and has no rotation. AA also has an
%   'Aperture' field to represent the aperture for an isotropic antenna.
% 
%   AA = WINNER2.ANTENNAARRAY('Pos',POS) specifies the positions (in
%   meters) for each antenna element by each row of the POS input. The
%   elements have no rotation. POS must be a matrix with 3 columns
%   representing x, y, and z coordinates. The number of rows of POS
%   determines the number of antenna elements in the array. When there is
%   more than one element, the 'Element' field of AA is a row vector of
%   structures representing all the elements.
% 
%   AA = WINNER2.ANTENNAARRAY('Pos',POS,'Rot',ROT) specifies the rotation
%   (in radians) for each antenna element by each row of the ROT input. The
%   ROT input must have the same size as the POS input.
% 
%   AA = WINNER2.ANTENNAARRAY('UCA',N,RAD) specifies a uniform circular
%   array (UCA) with N elements and radius of RAD (in meters). When RAD is
%   not specified, its default value is 1 meter.
% 
%   AA = WINNER2.ANTENNAARRAY('ULA',N,SPACING) specifies a uniform linear
%   array (ULA) with N elements which have SPACING meters between two
%   adjacent elements. When SPACING is not specified, its default value is
%   1/N meters.
% 
%   AA = WINNER2.ANTENNAARRAY(...,'FP-ECS',PATTERN) specifies the field
%   pattern for all antenna elements in the element-coordinate-system
%   (ECS). PATTERN must be a P x 2 x 1 x Naz array. P can be either 1 or
%   any number larger than or equal to N, the number of antenna elements in
%   the array. Naz is the number of azimuth angles which are uniformly
%   spaced between -180 and 180 degrees. The first dimension of PATTERN
%   applies to individual elements of the array. When P=1, the same pattern
%   applies to all elements. When P>N, PATTERN(1:N,:,:,:) applies.
% 
%   AA = WINNER2.ANTENNAARRAY(...,'FP-ACS',PATTERN) is the same as the
%   'FP-ECS' syntax above except that the field pattern is specified in the
%   array-coordinate-system (ACS).
% 
%   AA = WINNER2.ANTENNAARRAY(...,'FP-ECS'|'FP-ACS',PATTERN,'Azimuth',AZ)
%   specifies the azimuth angles (in degrees) for the 'FP-ACS' or 'FP-ECS'
%   field patterns, instead of using the default uniformly spaced angles.
%   AZ must be a 1 x Naz row vector.
%   
%   AA fields:
% 
%   Name     - Antenna array name.
%   Pos      - Antenna array position (meters).
%   Rot      - Antenna array rotation (radians).
%   Element  - Row vector of structures with each structure representing 
%              one antenna element.
%   Aperture - Structure representing the antenna aperture.
%   
%   % Example 1: Create a UCA-8 with 1cm radius
%   
%   UCA8 = winner2.AntennaArray('UCA', 8, .01);
%   % Plot element positions
%   pos = {UCA8.Element(:).Pos};
%   plot(cellfun(@(x) x(1), pos), cellfun(@(x) x(2), pos), '+');
%   xlim([-0.02 0.02]); ylim([-0.02 0.02]);
%   title('UCA-8 Element Positions');
% 
%   % Example 2: Create a ULA-2 with 50cm spacing and +45/-45 degree
%   % slanted dipole elements
%   
%   az = -180:179; % 1-degree spacing
%   pattern = cat(1, shiftdim(winner2.dipole(az,  45),-1), ...
%                    shiftdim(winner2.dipole(az, -45),-1));
%   ULA2 = winner2.AntennaArray('ULA', 2, .5, ...
%       'FP-ECS', pattern, 'Azimuth', az);
% 
%   See also winner2.dipole, winner2.layoutparset.

% Copyright 2016-2017 The MathWorks, Inc.

registerrealtimecataloglocation(winner2.internal.resourceRoot);

Labels = {'Pos','Rot','UCA','ULA','FP-ACS','FP-ECS','Azimuth'};
AA = struct('Name',    [],...
            'Pos',     zeros(3,1),...
            'Rot',     zeros(3,1),...
            'Element', []);

% Analyze inputs
lb = [];
for i = 1:length(varargin)
    if ischar(varargin{i})
        tmp = find(strcmp(varargin{i}, Labels));
        if ~isempty(tmp)
            lb = [lb; i tmp]; %#ok<AGROW>
        else
            coder.internal.warning( ...
                'winner2:AntennaArray:UnknownInputArg', varargin{i});
        end
    end
end
lb = [lb;length(varargin)+1 0]; % Dummy to make getValueIdx() work

% Define array geometry
PosValueIdx = getValueIdx(lb, 1); % Pos overrides ULA or UCA setings
UCAValueIdx = getValueIdx(lb, 3); % UCA
ULAValueIdx = getValueIdx(lb, 4); % ULA

if ~isempty(PosValueIdx) % Customized positions and/or rotations
    pos = varargin{PosValueIdx(1)};  % Take the first V following the P
    validateattributes(pos,{'double'},{'real','2d','ncols',3}, ...
        'AntennaArray', 'the ''Pos'' input value');

    numElem = size(pos, 1);
    AA.Name=['Custom-' num2str(numElem)];    
    for n = 1:numElem
        AA.Element(n).Pos = pos(n,:)';
    end
    
    RotValueVIdx = getValueIdx(lb, 2);
    if ~isempty(RotValueVIdx)
        rot = varargin{RotValueVIdx(1)};  % Take the first V following the P
        validateattributes(rot,{'double'}, ...
            {'real','size',[numElem, 3]}, ...
            'AntennaArray', 'the ''Rot'' input value');
        for n = 1:numElem
            AA.Element(n).Rot = rot(n,:)'; % Unit: radians
        end
    else
        for n = 1:length(AA.Element)
            AA.Element(n).Rot = [0;0;0];
        end
    end
elseif ~isempty(UCAValueIdx) % UCA
    numElem = varargin{UCAValueIdx(1)};
    validateattributes(numElem,{'double'}, ...
        {'real','positive','integer','scalar'}, ...
        'AntennaArray', 'the number of elements input value for ''UCA''');

    if length(UCAValueIdx) > 1
        radius = varargin{UCAValueIdx(2)};
        validateattributes(radius,{'double'},{'real','positive','scalar'}, ...
            'AntennaArray', 'the radius input value for ''UCA''');
    else
        radius = 1;
    end

    AA.Name=['UCA-' num2str(numElem)];
    for n = 1:numElem
        phi = 2*pi/numElem*(n-1);
        [x,y,z] = sph2cart(phi,0,radius);
        AA.Element(n).Pos = [x; y; z];
        AA.Element(n).Rot = [0; 0; phi];
    end
elseif ~isempty(ULAValueIdx) % ULA
    numElem = varargin{ULAValueIdx(1)};
    validateattributes(numElem,{'double'}, ...
        {'real','positive','integer','scalar'}, ...
        'AntennaArray', 'the number of elements input value for ''ULA''');
    
    if length(ULAValueIdx) > 1
        elementDist = varargin{ULAValueIdx(2)};
        validateattributes(elementDist,{'double'}, ...
            {'real','positive','scalar'}, ...
            'AntennaArray', 'the element distance input value for ''ULA''');
    else
        elementDist = 1/numElem;
    end
    
    AA.Name=['ULA-' num2str(numElem)];
    for n = 1:numElem
        % Place elements along x-axis and array center at [0;0;0]
        AA.Element(n).Pos = [(n-1)*elementDist - ...
                             (numElem-1)*elementDist/2; 0; 0];
        AA.Element(n).Rot = [0;0;0];
    end
else % Default single antenna
    AA.Name='Single';
    AA.Element(1).Pos = [0; 0; 0];
    AA.Element(1).Rot = [0; 0; 0];
end
        
% Express field patterns as EADF
numElem = length(AA.Element);
 
% Get azimuth angles if specified from input
AZValueIdx = getValueIdx(lb,7);
hasAZInput = ~isempty(AZValueIdx);
if hasAZInput
    Azimuth = varargin{AZValueIdx(1)};
    validateattributes(Azimuth,{'double'},{'real','row','finite'}, ...
        'AntennaArray', 'the azimuth input value');
    coder.internal.errorIf( ...
        length(unique(mod(Azimuth,360))) ~= length(Azimuth), ...
        'winner2:AntennaArray:AZAnglesNotUnique')
end

ACSValueIdx = getValueIdx(lb,5); 
ECSValueIdx = getValueIdx(lb,6); 

if ~isempty(ACSValueIdx) % FP-ACS
    ACSFP = varargin{ACSValueIdx(1)};
    validateattributes(ACSFP,{'double'},...
        {'nonempty','ndims',4,'ncols',2}, ...
        'AntennaArray','the ACS field pattern input value');    
    
    coder.internal.errorIf((size(ACSFP, 1) > 1) && ...
        (size(ACSFP, 1) < numElem), ...
        'winner2:AntennaArray:FPAndElementMismatch');
    
    coder.internal.errorIf(hasAZInput && ...
        (size(ACSFP, 4) ~= length(Azimuth)), ...
        'winner2:AntennaArray:FPAndAzimuthMismatch');
    
    if ~hasAZInput
        numAZAngles = size(ACSFP, 4); 
        Azimuth = linspace(-180, 180-1/numAZAngles, numAZAngles); 
    end
    
    if size(ACSFP, 1) == 1
        ACSFP = repmat(ACSFP, numElem, 1);
    end    
    
    AA.Aperture = BP2Aperture1D(ACSFP(1:numElem,:,:,:), Azimuth); 
elseif ~isempty(ECSValueIdx) % FP-ECS
    ECSFP = varargin{ECSValueIdx(1)}; 
    validateattributes(ECSFP,{'double'}, ...
        {'nonempty','ndims',4,'ncols',2}, ...
        'AntennaArray','the ECS field pattern input value');    
    
    coder.internal.errorIf((size(ECSFP, 1) > 1) && ...
        (size(ECSFP, 1) < numElem), ...
        'winner2:AntennaArray:FPAndElementMismatch');
    
    coder.internal.errorIf(hasAZInput && ...
        (size(ECSFP, 4) ~= length(Azimuth)), ...
        'winner2:AntennaArray:FPAndAzimuthMismatch');
    
    if ~hasAZInput
        numAZAngles = size(ECSFP, 4); 
        Azimuth = linspace(-180, 180-1/numAZAngles, numAZAngles); 
    end
    
    % Calculate EADF in ECS
    numFP = size(ECSFP, 1);
    if numFP == 1
        AA.CommonAperture = BP2Aperture1D(ECSFP, Azimuth);
    else
        for n = 1:numElem
            AA.Element(n).Aperture = BP2Aperture1D(ECSFP(n,:,:,:), Azimuth);
        end
    end
    
    % FP rotation from ECS to ACS: recalculating EADF in ACS.    
    AA = arrayPreprocess(AA);
else  % Default FP: Vertical-Isotropic, XPD=Inf
    FP = cat(2, ones( numElem,1,1,360), ... 
                zeros(numElem,1,1,360));    
    Azimuth = linspace(-180,180-1/360,360);
    AA.Aperture = BP2Aperture1D(FP, Azimuth);
end

end

function valueIdx = getValueIdx(lb, code)

i = find(lb(:,2) == code);
if ~isempty(i)
    valueIdx = (lb(i,1)+1) : (lb(i+1,1)-1);
else
    valueIdx = [];
end

end

function aperture = BP2Aperture1D(BP, Az)
% BP has dimension NUMEL x POL x EL x AZ, where POL denotes vertical and
% horizontal polarizations, AZ is a vector containing the azimuth angles
% (in [-180, 180) degrees) at which the beam pattern is sampled. 

NAz = length(Az);
opt = struct( ...
    'Typ',                    'BP2Aperture', ...
    'pol',                    size(BP,2), ... % Number of polarizations
    'save',                   0, ...           
    'positioning_correction', 0, ...
    'thrs',                   -320, ...       % Power threshold in dB for input data
    'darst',                  0, ...
    'NAzh',                   (2:2:NAz), ...  % Grid to search for optimal aperture size 
    'Sampleflag',             1, ...
    'NoFreeSpaceCorrection',  1, ...
    'phase_optimisation',     0);

ym = squeeze(cat(1, BP(:,1,1,:),BP(:,2,1,:)));
RawData = struct( ...
    'Az',  Az, ...
    'Ele', 90*ones(1,NAz), ...
    'YM1', ym, ...
    'YM2', ym, ...
    'YM3', ym); 

aperture = calcAperture(RawData, opt);

end

function aperture = calcAperture(RawData, opt)

[arraydef, Nopt] = estimateAperture(RawData, opt);

if ~isempty(Nopt)
    opt.NAzh = Nopt;
    arraydef = estimateAperture(RawData, opt);   
end

aperture = arraydef.apertur;

end

function [arraydef, varargout] = estimateAperture(RawData, opt)
% Calculates 2D-EADF (azimuth-only) of beampattern given in 'RawData',
% which covers the whole azimuth range [-180,180). The first output is a
% structure containing EADF. The second output is the optimal aperture
% size. 

if isfield(opt, 'pol')
    pol = opt.pol;
else
    pol = 1;
end

if isfield(opt,'dimension')
    opt.dimension = opt.dimension;
elseif (RawData.Az(1) == RawData.Az(2)) && (RawData.Ele(1) ~= RawData.Ele(2))
    opt.dimension = 2;
elseif (RawData.Az(1) ~= RawData.Az(2)) && (RawData.Ele(1) == RawData.Ele(2))
    if sum(RawData.Az(1) == RawData.Az) > 1
        opt.dimension = 3;
    else
        opt.dimension = 1;
    end
end

% Array definition
arraydef.agc=0;

if isfield(opt, 'Typ')
    arraydef.Typ = opt.Typ; 
else
    arraydef.Typ = 'Test_Array';
end

arraydef.PosData = zeros(size(RawData.YM1,1)/pol,3); % numEl * 3
arraydef.Date = date;

if isfield(opt, 'pol')
    arraydef.pol = opt.pol;
else
    arraydef.pol{1} = 'hv';
    arraydef.pol{2} = 'hv';
end

if isfield(opt, 'sector')
    arraydef.sector = opt.sector;
end

if ~isfield(RawData,'YM2')
    RawData.YM2 = RawData.YM1;
end
if ~isfield(RawData,'YM3')
    RawData.YM3 = RawData.YM1;
end

RawData.ym_ref = ones(1,size(RawData.YM1,2)); % AZ length

% Part 1 aperture calculation
PHASE = angle(RawData.ym_ref);
azvec = RawData.Az*pi/180;

if opt.dimension==1
    YM1=RawData.YM2;
    YM2=RawData.YM3;

    Power=sum(abs(YM1).^2,2);
    
    thrs = opt.thrs;
    
    elevec = find(10*log10(Power)>thrs);

    YMh1 = YM1;
    YMh2 = YM2;

    YM1=YMh1(elevec,:);
    YM2=YMh2(elevec,:);

    [antennen, SAMPLES] = size(YM1);

    ini=PHASE;
    phid=ini;
    
    if isfield(opt,'phidIni')
        phid=angle(exp(1i*phid).*exp(1i*opt.phidIni));
    end
    
    if isfield(opt,'NAzh')
        Nh = opt.NAzh; %/4:2:opt.NAzh;
    else
        Nh = SAMPLES-1;
    end
    
    ctt=0;
    idx1=0;
    err = zeros(1, length(Nh));
    apS = zeros(1, length(Nh));
    for N = Nh
        ctt=ctt+1;
        idx1=idx1+1;

        mue=(-N/2:N/2)';
        F=exp(1i*mue*azvec);
        ini=phid;

        P = diag(exp(1i*ini));
        G = (YM1/(F*P));
        err(idx1) = -10*log10( SAMPLES*antennen*sum(sum(abs(YM2).^2))/ ...
            ( (SAMPLES*antennen - (N+1)*antennen)*sum(sum(abs(YM2-G*F*P).^2))));
        apS(idx1) = N;
    end
    
    arraydef.err_dep_AP=err;
     
    d=diff(err);
    [~,I] = find(diff(d./abs(d))==2);
    if(~isempty(I))
        if(nargout>1)
            varargout{1}=apS(I(1));
        end
    else
        if(nargout>1)
            varargout{1}=[];
        end
    end    

    YM1 = RawData.YM2;
    
    P = diag(exp(1i*phid(1:end)));
    G = (RawData.YM1/(F*P));
    
    [elements, apertur]=size(G);

    [~, ApAz]=size(G);
    ApEle=1;

    arraydef.apertur.pol=pol;
    arraydef.apertur.elements=size(YM1,1)/pol;
    arraydef.apertur.saz=1+(ApAz-1)/2;
    arraydef.apertur.sele=1+(ApEle-1)/2;

    H = permute(G,[3 2 1]);

    arraydef.apertur.G14(1,1:1+(apertur-1)/2,1:elements,1) = ...
        H(1,1:1+(apertur-1)/2,1:elements);
    arraydef.apertur.G14(1,1:(apertur-1)/2,1:elements,1) = ...
        arraydef.apertur.G14(1,1:(apertur-1)/2,1:elements,1) + ...
        H(1,apertur:-1:2+(apertur-1)/2,1:elements);
    G1 = arraydef.apertur.G14(1,1:1+(apertur-1)/2,1:elements,1);
    arraydef.apertur.G14(1,1:1+(apertur-1)/2,1:elements,1) = G1;

    arraydef.apertur.G14(1,1:1+(apertur-1)/2,1:elements,2) = ...
        H(1,1:1+(apertur-1)/2,1:elements);
    arraydef.apertur.G14(1,1:(apertur-1)/2,1:elements,2) = ...
        arraydef.apertur.G14(1,1:(apertur-1)/2,1:elements,2) - ...
        H(1,apertur:-1:2+(apertur-1)/2,1:elements);

    G2 = arraydef.apertur.G14(1,1:1+(apertur-1)/2,1:elements,2);
    arraydef.apertur.G14(1,1:1+(apertur-1)/2,1:elements,2) = 1i*G2;

    % Remove first singleton dimension
    hh = shiftdim(arraydef.apertur.G14);

    G13 = hh(:,:,1);
    arraydef.apertur.G13 = G13(:).';

    G24 = hh(:,:,2);
    G24(1+(apertur-1)/2,:,1) = 0;  

    arraydef.apertur.G24 = G24(:).';
    
    arraydef.apertur = rmfield(arraydef.apertur,'G14');
end

end

function ACSAA = arrayPreprocess(ECSAA)

ACSAA = ECSAA;
ACSAA.Rot = [0;0;0];

% Even if no element is rotated, the following steps are performed to
% create one aperture for the whole array
phi = linspace(-180,180-1/360,360); 
g = winner2.internal.calcAntennaResponse(ACSAA, phi*pi/180); 
BP = g{1}(:,1:2,:);  % Leave out phase term
% Add the (singleton) elevation dimension to BP
ACSAA.Aperture = BP2Aperture1D(permute(BP, [1 2 4 3]), phi);

ACSAA.Rot = ECSAA.Rot;
for n = 1:length(ACSAA.Element)
    ACSAA.Element(n).Rot = zeros(3,1);
end

if isfield(ACSAA, 'CommonAperture')
    ACSAA = rmfield(ACSAA, 'CommonAperture');
else
    ACSAA.Element = rmfield(ACSAA.Element, 'Aperture');
end

end

% [EOF]