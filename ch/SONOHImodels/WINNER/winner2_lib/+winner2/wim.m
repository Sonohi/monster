function [H, D, finalCond] = wim(cfgWim, cfgLayout, initCond)
%WIM Generate channel coefficients using WINNER II channel model
% 
%   H = WINNER2.WIM(CFGWIM,CFGLAYOUT) generates channel coefficients, H,
%   for all links defined in the CFGLAYOUT input. CFGWIM, a structure
%   defined by WINNER2.WIMPARSET, specifies the model parameter
%   configurations. CFGLAYOUT, a structure defined by WINNER2.LAYOUTPARSET,
%   specifies the link parameter configurations. H is a NL x 1 cell array
%   for all NL links in the system. The i'th element of H is a Nr(i) x
%   Nt(i) x Np(i) x Ns array. Nr(i) is the number of receive antenna
%   elements at MS for the i'th link. Nt(i) is the number of transmit
%   antenna elements at BS for the i'th link. Np(i) is the number of paths
%   for the i'th link. Ns is the number of time samples given by
%   CFGWIM.NumTimeSamples. Nr, Nt and Np are link specific, and Ns is the
%   same for all the links.
% 
%   [H,D] = WINNER2.WIM(CFGWIM,CFGLAYOUT) returns path delays D for all
%   links in a NL x maxNp matrix, where maxNp is the maximum number of
%   paths among all links. Each row of the matrix applies to each link.
%   When a link has fewer than maxNp paths, the corresponding row in D is
%   NaN padded.
% 
%   [H,D,FINALCOND] = WINNER2.WIM(CFGWIM,CFGLAYOUT) records final condition
%   of the system in a structure, FINALCOND, after generating the channel
%   coefficients H.
% 
%   [H,D,FINALCOND] = WINNER2.WIM(CFGWIM,CFGLAYOUT,INITCOND) uses a given
%   system initial condition INITCOND which is of the same form as
%   FINALCOND, instead of performing random initialization, to generate the
%   channel coefficients H. INITCOND is usually the FINALCOND output from
%   the last call to this function. Use this syntax to repeatedly generate
%   channel coefficients for continuous time samples.
%
%   % Example: Continuously generate channel coefficients for each link in
%   % a 2-link system layout
%   
%   % Configure model parameters
%   cfgWim = winner2.wimparset; 
%   cfgWim.SampleDensity = 20;
%   cfgWim.RandomSeed    = 10; % For repeatability
%   
%   % Configure layout parameters
%   BSAA  = winner2.AntennaArray('UCA', 8, 0.02);  % UCA-8 array for BS
%   MSAA1 = winner2.AntennaArray('ULA', 2, 0.01);  % ULA-2 array for MS
%   MSAA2 = winner2.AntennaArray('ULA', 4, 0.005); % ULA-4 array for MS
%   MSIdx = [2,3]; BSIdx = {1}; NL = 2; rndSeed = 5;
%   cfgLayout = winner2.layoutparset(MSIdx,BSIdx, ...
%       NL,[BSAA,MSAA1,MSAA2],[],rndSeed);
%   
%   % Generate channel coefficients for the first time
%   [H1, ~, finalCond] = winner2.wim(cfgWim, cfgLayout);
%   % Generate a second set of channel coefficients
%   [H2, ~, finalCond] = winner2.wim(cfgWim, cfgLayout, finalCond);
%  
%   % Concatenate H1 and H2 in time domain
%   H = cellfun(@(x,y) cat(4,x,y), H1, H2, 'UniformOutput', false);
%   
%   % Plot H for the first link, 1st Tx, 1st Rx and 1st path. It shows the
%   % continuity of the channel over the two outputs from the wim function.
%   figure;
%   Ts = finalCond.delta_t(1);  % Sample time for the 1st link
%   plot(Ts*(0:2*cfgWim.NumTimeSamples-1)', abs(squeeze(H{1}(1,1,1,:))));
%   xlabel('Time (s)'); ylabel('Amplitude');
%   title('First Path Coefficient of 1st Link, 1st Tx and 1st Rx');
% 
%   See also comm.WINNER2Channel, winner2.wimparset, winner2.AntennaArray,
%   winner2.layoutparset.

% Copyright 2016 The MathWorks, Inc.

registerrealtimecataloglocation(winner2.internal.resourceRoot);

narginchk(2,3);

% Validate cfgWim
winner2.internal.validateWimConfig(cfgWim);

% Validate cfgLayout
winner2.internal.validateLayoutConfig(cfgLayout, true, true);

% Validate initCond
if nargin == 3 
    validateInitCond(initCond, size(cfgLayout.Pairing, 2), ...
        strcmp(cfgWim.IntraClusterDsUsed, 'yes'), ...
        strcmp(cfgWim.PolarisedArrays, 'yes'));
    [H, D, finalCond] = winner2.internal.wim(cfgWim, cfgLayout, initCond);
else
    [H, D, finalCond] = winner2.internal.wim(cfgWim, cfgLayout);
end

end

function validateInitCond(initCond, NL, isClusterDivided, isPolarized)

validateattributes(initCond,{'struct'},{'scalar','nonempty'}, ...
    'wim', 'the initial condition input');

% Check all necessary fields are present
expFields = {'delays','path_powers','aods','aoas','path_losses', ...
    'MsBsDistance','shadow_fading','sigmas','propag_condition', ...
    'Kcluster','Phi_LOS','scatterer_freq','subpath_phases'};
for i = 1:length(expFields)
    coder.internal.errorIf(~isfield(initCond, expFields{i}), ...
        'winner2:wim:MissingField', expFields{i});
end

% Validate 'delays' field
validateattributes(initCond.delays,{'double'}, ...
    {'real','nonnegative','nonempty','2d','nrows',NL}, ...
    'wim', 'the initCond.delays');
coder.internal.errorIf(isClusterDivided && (size(initCond.delays, 2)<5), ...
    'winner2:wim:NPLesThan5WithSplitting');
NP = size(initCond.delays, 2) - 4*isClusterDivided;

% Vaildate 'path_powers' field
validateattributes(initCond.path_powers,{'double'}, ...
    {'real','positive','nonempty','size',size(initCond.delays)}, ...
    'wim', 'the initCond.path_powers');

% Vaildate 'aods' field
validateattributes(initCond.aods,{'double'}, ...
    {'real','size',[NL, NP, 20]}, ...
    'wim', 'the initCond.aods');

% Vaildate 'aoas' field
validateattributes(initCond.aoas,{'double'}, ...
    {'real','size',[NL, NP, 20]}, ...
    'wim', 'the initCond.aoas');

% Vaildate 'path_losses' field
validateattributes(initCond.path_losses,{'double'}, ...
    {'real','size',[NL, 1]}, ...
    'wim', 'the initCond.path_losses');

% Vaildate 'MsBsDistance' field
validateattributes(initCond.MsBsDistance,{'double'}, ...
    {'real','size',[1, NL]}, ...
    'wim', 'the initCond.MsBsDistance');

% Vaildate 'shadow_fading' field
validateattributes(initCond.shadow_fading,{'double'}, ...
    {'real','size',[NL, 1]}, ...
    'wim', 'the initCond.shadow_fading');

% Vaildate 'sigmas' field
validateattributes(initCond.sigmas,{'double'}, ...
    {'real','size',[NL, 5]}, ...
    'wim', 'the initCond.sigmas');

% Vaildate 'propag_condition' field
validateattributes(initCond.propag_condition,{'double'}, ...
    {'real','integer','>=',0,'<=',1,'size',[NL, 1]}, ...
    'wim', 'the initCond.propag_condition');

% Validate 'Kcluster' field
validateattributes(initCond.Kcluster,{'double'}, ...
    {'real','size',[NL, 1]}, ...
    'wim', 'the initCond.Kcluster');

% Validate 'Phi_LOS' field
validateattributes(initCond.Phi_LOS,{'double'}, ...
    {'real','size',[NL, 1]}, ...
    'wim', 'the initCond.Phi_LOS');

% Valiate 'scatterer_freq' field
validateattributes(initCond.scatterer_freq,{'double'}, ...
    {'real','size',[NL, NP, 20]}, ...
    'wim', 'the initCond.scatterer_freq');

% Valiate 'subpath_phases' field
if isPolarized
    expScatFreqSize = [NL, 4, NP, 20];
else
    expScatFreqSize = [NL, NP, 20];
end
validateattributes(initCond.subpath_phases,{'double'}, ...
    {'real','size',expScatFreqSize}, ...
    'wim', 'the initCond.subpath_phases');

% Validate 'xpr' field for polarized arrays
if isPolarized 
    coder.internal.errorIf(~isfield(initCond, 'xpr'), ...
        'winner2:wim:MissingField', 'xpr');    
    
    validateattributes(initCond.xpr,{'double'}, ...
        {'real','size',[NL, NP, 20]}, ...
        'wim', 'the initCond.xpr');
end

% Validate 'IndexOfDividedClust' field when 'IntraClusterDsUsed' is on
if isClusterDivided
    coder.internal.errorIf(~isfield(initCond, 'IndexOfDividedClust'), ...
        'winner2:wim:MissingField', 'IndexOfDividedClust');
    
    validateattributes(initCond.IndexOfDividedClust,{'double'}, ...
        {'real','positive','integer','<=',NP,'size',[NL, 2]}, ...
        'wim', 'the initCond.IndexOfDividedClust');

    coder.internal.errorIf(any( ...
        diff(initCond.IndexOfDividedClust, 1, 2) <= 0), ...
        'winner2:wim:DivCluIdxNotIncreasing');
end

% Not validate 'delta_t' field as it doesn't do anything in the algorithms

end

% [EOF]