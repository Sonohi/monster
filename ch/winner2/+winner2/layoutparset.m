function cfgLayout = layoutparset(MSIdx, BSIdx, K, arrays, maxRange, seed)
%LAYOUTPARSET WINNER II layout parameter configuration
% 
%   CFGLAYOUT = WINNER2.LAYOUTPARSET(MSIDX,BSIDX,K,ARRAYS) returns a
%   structure of randomly generated WINNER II network layout parameters.
%   The base station (BS) positions, mobile station (MS) positions, and MS
%   velocities are randomly set. BS and MS are also randomly paired to form
%   K links. ARRAYS is a vector of antenna array structures, defining all
%   available arrays. All MS and BS sectors are chosen from this vector.
%   MSIdx is an integer-valued row vector to indicate the indices in ARRAYS
%   to serve as MS. BSIdx is a column, cell array with each element
%   representing one BS. Each cell element is an integer-valued row vector
%   to indicate the indices in ARRAYS to serve as different sectors of this
%   BS. K is the number of links to be formulated.
%           
%   CFGLAYOUT = WINNER2.LAYOUTPARSET(...,RMAX) specifies the maximum layout
%   range RMAX (in meters) used to randomly generate the MS and BS
%   positions. When RMAX is not specified, the default value is 500.
%   
%   CFGLAYOUT = WINNER2.LAYOUTPARSET(...,RMAX,SEED) specifies the random
%   number generator seed for creating the layout parameters. Specifying a
%   seed provides repeatability. When SEED is not specified, the global
%   random number generator is used. If RMAX is not used in this syntax,
%   specify it to be [].
%
%   CFGLAYOUT fields:
%
%   Stations              - Vector of antenna array structures, created
%                           from the ARRAYS input, to describe BS sectors
%                           and then MS. The BS sector and MS positions are
%                           randomly assigned. The BS sectors have no
%                           velocity. Each MS has a velocity of about 1.42
%                           m/s with a randomly assigned direction.
%   NofSect               - Vector of number of sectors in each BS.
%   Pairing               - 2 x K matrix defining K randomly generated 
%                           links to be modelled.
%   ScenarioVector        - 1 x K vector of scenario numbers for each link.
%                           The default value is 1 for each link.  
%   PropagConditionVector - 1 x K randomly generated propagation condition 
%                           vector (LOS = 1/NLOS = 0) for each link.
%   StreetWidth           - Average width (in meters) of the streets for
%                           path loss model of the B1 and B2 scenarios. The
%                           default value is 25.
%   Dist1                 - Distance from BS to the last LOS point for path
%                           loss model of the B1 and B2 scenarios. The
%                           default value is NaN, which means the distance
%                           is randomly determined in path loss function.
%   NumFloors             - Floor number where the indoor BS/MS is located
%                           for path loss model of the A2 and B4 scenarios.
%                           The default value is 1. 
%   NumPenetratedFloors   - Number of penetrated floors between BS and MS
%                           for NLOS path loss model of the A1 scenario.
%                           The default value is 0.
% 
%   % Example: Create a system layout with 2 MS connecting to the same BS
%
%   BSAA  = winner2.AntennaArray('UCA', 8, 0.02);  % UCA-8 array for BS
%   MSAA1 = winner2.AntennaArray('ULA', 2, 0.01);  % ULA-2 array for MS
%   MSAA2 = winner2.AntennaArray('ULA', 4, 0.005); % ULA-4 array for MS
% 
%   % Create system layout
%   MSIdx = [2 3]; BSIdx = {1}; K = 2; rndSeed = 5;
%   cfgLayout = winner2.layoutparset(MSIdx,BSIdx, ...
%       K,[BSAA,MSAA1,MSAA2],[],rndSeed);
% 
%   % Visualize BS and MS positions
%   BSPos  = cfgLayout.Stations(cfgLayout.Pairing(1,1)).Pos;
%   MS1Pos = cfgLayout.Stations(cfgLayout.Pairing(2,1)).Pos;
%   MS2Pos = cfgLayout.Stations(cfgLayout.Pairing(2,2)).Pos;
%   plot3(BSPos(1),  BSPos(2),  BSPos(3),  'bo', ...
%         MS1Pos(1), MS1Pos(2), MS1Pos(3), 'rs', ...
%         MS2Pos(1), MS2Pos(2), MS2Pos(3), 'rd');
%   grid on; xlim([0 500]); ylim([0 500]); zlim([0 35]);
%   xlabel('X-position (m)'); 
%   ylabel('Y-position (m)'); 
%   zlabel('Elevation (m)'); 
%   legend('BS', 'MS1', 'MS2', 'Location', 'northeast');
% 
%   See also comm.WINNER2Channel, winner2.wim, winner2.wimparset,
%   winner2.AntennaArray.

% Copyright 2016 The MathWorks, Inc.

registerrealtimecataloglocation(winner2.internal.resourceRoot);

narginchk(4, 6);

% Validate antenna arrays
winner2.internal.validateAntennaArray(arrays, false, 'antenna array input');

% Number of antenna arrays
numAA = length(arrays);

% Validate MSIdx
validateattributes(MSIdx,{'double'},{'real','positive','integer', ...
    'row','<=',numAA},'layoutparset','the MS index input');

% Validate BSIdx
validateattributes(BSIdx,{'cell'},{'column'}, ...
    'layoutparset','the BS index input');
for i = 1:length(BSIdx)
    validateattributes(BSIdx{i},{'double'},{'real','positive','integer', ...
        'row','<=',numAA},'layoutparset','each element of the BS index input');
end

% Validate K
if ~isempty(K)
    validateattributes(K,{'double'},{'real','positive','integer','scalar'}, ...
        'layoutparset','the number of links input');    
else % 1 link by default 
    K = 1;
end

% Validate maxRange
if nargin >= 5 && (~isempty(maxRange))
    validateattributes(maxRange,{'double'},{'real','positive','scalar'}, ...
        'layoutparset','the maximum layout range input');    
else
    maxRange = 500;
end

% Validate seed
if (nargin == 6) && ~isempty(seed)
    validateattributes(seed,{'double'}, {'real','nonnegative', ...
        'integer','scalar'}, 'layoutparset','the random seed input');    
    % rng(seed, 'v5uniform');
    s = RandStream('v5uniform','Seed',seed);
else
    s = RandStream.getGlobalStream;
end

numMS   = length(MSIdx);
numSect = cellfun(@length, BSIdx)'; 
BSAAIdx = cell2mat(cellfun(@(x) x(:),BSIdx,'UniformOutput',false))';
numBS   = length(BSAAIdx);  

if K > numBS*numMS
    coder.internal.warning('winner2:layoutparset:KExceedTotalLinks', numBS*numMS);
    K = numBS*numMS;
end

% Initialization
tmpStn = arrays(1);
tmpStn.Velocity = [0;0;0];
stations = repmat(tmpStn, 1, numBS + numMS);

% Create stations
for i = 1:numBS
    aa = arrays(BSAAIdx(i));
    % Update name and position
    aa.Name = ['BS' num2str(i) ' ' aa.Name];
    % YS: We can do a better job by assigning the same position to all
    % sectors that belong to one BS
    aa.Pos  = [round(rand(s,2,1)*maxRange); 32];
    % Static BS stations
    aa.Velocity = [0;0;0];
    stations(i) = aa;
end

for i = 1:numMS 
    aa = arrays(MSIdx(i));
    % Update name and position
    aa.Name = ['MS' num2str(i) ' ' aa.Name];
    aa.Pos  = [round(rand(s,2,1)*maxRange); 1.5];   
    % Append random-valued velocity field
    velocity = rand(s, 3,1) - 0.5; 
    aa.Velocity = (2.99792458e8/5.25e9/.04) * ...
        (velocity/sqrt(sum(abs(velocity).^2))); % About 1.42m/s
    stations(numBS + i) = aa;
end

% Create link pairs
tmp = randperm(s, numBS*numMS);
linkPairing = [floor((tmp(1:K)-1)/numMS) + 1; ...
               mod(tmp(1:K)-1,numMS) + 1 + numBS];

% Create output
cfgLayout = struct(...
    'Stations',              stations,...
    'NofSect',               numSect,...
    'Pairing',               linkPairing, ...
    'ScenarioVector',        ones(1,K),... 
    'PropagConditionVector', round(rand(s,1,K)),...
    'StreetWidth',           20*ones(1,K),...
    'Dist1',                 nan(1,K),...
    'NumFloors',             ones(1,K),...
    'NumPenetratedFloors',   zeros(1,K)); 

end

% [EOF]