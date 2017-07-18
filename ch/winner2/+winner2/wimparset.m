function cfgWim = wimparset
%WIMPARSET WINNER II model parameter configuration
% 
%   CFGWIM = WINNER2.WIMPARSET returns WINNER II model parameters with
%   their default values in structure CFGWIM.
%
%   CFGWIM fields:
%
%   NumTimeSamples          - Number of time samples. The default value is
%                             100. 
%   FixedPdpUsed            - Set to 'yes' to use pre-defined path delays
%                             and powers for specific scenarios. The 
%                             default value is 'no'.
%   FixedAnglesUsed         - Set to 'yes' to use pre-defined angles of
%                             departure (AoDs) and angles of arrival (AoAs)
%                             for specific scenarios. The default value is
%                             'no'.
%   IntraClusterDsUsed      - Set to 'yes' to divide each of the two
%                             strongest clusters into three subclusters per
%                             link. The default value is 'yes'.
%   PolarisedArrays         - Set to 'yes' to use dual polarised arrays. 
%                             The default value is 'yes'.
%   UseManualPropCondition  - Set to 'yes' to use manually defined
%                             propagation conditions (LOS/NLOS) in the
%                             PropagConditionVector field of LAYOUTPARSET's
%                             returned structure. Set to 'no' to draw
%                             propagation conditions from pre-defined LOS
%                             probabilities. The default value is 'yes'.
%   CenterFrequency         - Carrier frequency in Hertz. The default value
%                             5.25e9.
%   UniformTimeSampling     - Set to 'yes' to enforce all links to be 
%                             sampled at the same time instants. The
%                             default value is 'no'.
%   SampleDensity           - Number of time samples per half wavelength. 
%                             The default value is 2e6. 
%   DelaySamplingInterval   - Sampling interval (in seconds) to determine
%                             path delays. The default value is 5e-9.
%   ShadowingModelUsed      - Set to 'yes' to include shadow fading in the
%                             model. The default value is 'no'.
%   PathLossModelUsed       - Set to 'yes' to include path loss in the
%                             model. The default value is 'no'.
%   PathLossModel           - Path loss model function name. The default is 
%                             'pathloss'. 
%   PathLossOption          - Set to one of {'CR_light' | 'CR_heavy' |
%                             'RR_light' | 'RR_heavy'} to indicate the wall
%                             material for A1 scenario NLOS path loss
%                             calculation. The default value is 'CR_light'.
%   RandomSeed              - Seed for random number generators. Setting
%                             it to empty means using the global random
%                             stream. The default value is [].
%
%   See also comm.WINNER2Channel, winner2.wim, winner2.layoutparset.

% Copyright 2016 The MathWorks, Inc.

cfgWim = struct(...
    'NumTimeSamples',         100, ...         
    'FixedPdpUsed',           'no', ...     
    'FixedAnglesUsed',        'no', ...     
    'IntraClusterDsUsed',     'yes', ...    
    'PolarisedArrays',        'yes', ...    
    'UseManualPropCondition', 'yes', ...
    'CenterFrequency',        5.25e9, ...   
    'UniformTimeSampling',    'no', ... 
    'SampleDensity',          2e6, ...        
    'DelaySamplingInterval',  5e-9, ...        
    'ShadowingModelUsed',     'no', ...           
    'PathLossModelUsed',      'no', ...            
    'PathLossModel',          'pathloss', ...
    'PathLossOption',         'CR_light', ... 
    'RandomSeed',             []);

% [EOF]