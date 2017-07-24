% =========================================================================
%
% This software was developed by employees of the National Institute of 
% Standards and Technology (NIST), an agency of the Federal Government. 
% Pursuant to title 17 United States Code Section 105, works of NIST 
% employees are not subject to copyright protection in the United States 
% and are considered to be in the public domain. Permission to freely use, 
% copy, modify, and distribute this software and its documentation without 
% fee is hereby granted, provided that this notice and disclaimer of 
% warranty appears in all copies.
%
% THE SOFTWARE IS PROVIDED 'AS IS' WITHOUT ANY WARRANTY OF ANY KIND, 
% EITHER EXPRESSED, IMPLIED, OR STATUTORY, INCLUDING, BUT NOT LIMITED TO, 
% ANY WARRANTY THAT THE SOFTWARE WILL CONFORM TO SPECIFICATIONS, ANY 
% IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE, 
% AND FREEDOM FROM INFRINGEMENT, AND ANY WARRANTY THAT THE DOCUMENTATION 
% WILL CONFORM TO THE SOFTWARE, OR ANY WARRANTY THAT THE SOFTWARE WILL BE
% ERROR FREE. IN NO EVENT SHALL NIST BE LIABLE FOR ANY DAMAGES, INCLUDING, 
% BUT NOT LIMITED TO, DIRECT, INDIRECT, SPECIAL OR CONSEQUENTIAL DAMAGES, 
% ARISING OUT OF, RESULTING FROM, OR IN ANY WAY CONNECTED WITH THIS 
% SOFTWARE, WHETHER OR NOT BASED UPON WARRANTY, CONTRACT, TORT, OR 
% OTHERWISE, WHETHER OR NOT INJURY WAS SUSTAINED BY PERSONS OR PROPERTY 
% OR OTHERWISE, AND WHETHER OR NOT LOSS WAS SUSTAINED FROM, OR AROSE OUT 
% OF THE RESULTS OF, OR USE OF, THE SOFTWARE OR SERVICES PROVIDED 
% HEREUNDER.
%
% Distributions of NIST software should also include copyright and 
% licensing statements of any third-party software that are legally bundled
% with the code in compliance with the conditions of those licenses.
% 
% =========================================================================
%
% National Institute of Standards and Technology (NIST)
% Communications Technology Laboratory (CTL)
% Wireless Networks Division (673)
% By: Thao Nguyen
% Date: 09/01/2016
%
% Description: function to compute the extended Hata propagation loss. 
% The extended Hata propgation model was developed in [1] with the 
% following steps;
% - Revisit the Okumura et al. basic median attenuation curves [2],
% - Extend Hata's empirical formulae in both distance & frequency range[3],
% - Apply the "Urban Factor" approach suggested by Longley [4],
% - Implement site-specific corrections to the median attenuation
% including effective height corrections, median and fine corrections for
% rolling hilly terrain, general slope of terrain correction, isolated
% mountain, and mixed land-sea path correction [1,2].
%
% Inputs: 
% - freq_MHz    : frequency (in MHz), in the range of [1500, 3000] MHz
% - hb_ant_m    : antenna height (in meter) of the base station, 
%                 in the range of [30, 200] m. 
%                 Note, base station and Tx will be used interchangeably.
% - hm_ant_m    : antenna height (in meter) of the mobile station, 
%                 in the range of [1, 10] m.
%                 Note, mobile station and Rx will be used interchangeably.
% - region      : region of the area ('DenseUrban', 'Urban', 'Suburban')
% - elev        : an array containing elevation profile between Tx & Rx,
%                 where:
%                 elev(1) = numPoints - 1 
%                 (note, numPoints is the number of points between Tx & Rx)
%                 elev(2) = distance between points (in meters). 
%                 (thus, elev(1)-1)*elev(2)=distance between Tx & Rx)
%                 elev(3) = Tx elevation (in meters)
%                 elev(numPoints+2) = Rx elevation (in meters)
%
% Outputs:
% - LossEH      : total propagation loss (in dB)
% 
% References: 
% [1] U.S. Department of Commerce, National Telecommunications and 
%     Information Administration, 3.5 GHz Exclusion Zone Analyses and 
%     Methodology (Jun. 18, 2015), available at 
%     http://www.its.bldrdoc.gov/publications/2805.aspx.
% [2] Y. Okumura, E. Ohmori, T. Kawano, and K. Fukuda, Field strength and
%     its variability in VHF and UHF land-mobile radio service, Rev. Elec. 
%     Commun. Lab., 16, 9-10, pp. 825-873, (Sept.-Oct. 1968).
% [3] M. Hata, Empirical formula for propagation loss in land mobile radio
%     services, IEEE Transactions on Vehicular Technology, VT-29, 3,
%     pp. 317-325 (Aug. 1980).
% [4] Anita G. Longley, Radio Propagation in Urban Areas, United States 
%     Department of Commerce, Office of Telecommunications, OT Report 
%     78-144 (Apr.1978), available at 
%     http://www.its.bldrdoc.gov/publications/2674.aspx.
% 
% History:
% - 2016/09/01: released version 1.0
% - 2016/11/16: modified code to include a terrain irregularity check 
% (delta_h). Corrections are only applied to irregular terrains, i.e., 
% delta_h > 20 m.
% (Federated Wireless's comment)

function LossEH = ExtendedHata_PropLoss(freq_MHz, hb_ant_m, hm_ant_m, ...
    region, elev)

% Check region classification
if (~strcmp(region, 'DenseUrban') && ~strcmp(region, 'Urban') && ...
        ~strcmp(region, 'Suburban'))
    disp(['ExtendedHata_PropLoss.m: Unknown region type.',...
        'Valid types: DenseUrban, Urban, Suburban']);
    LossEH = NaN;
    return;
end

% Extract data from elevation profile 
numPoints = elev(1) + 1;                % number of points between Tx & Rx
pointRes_km = elev(2)/1e3;              % distance between points (km)
d_Tx_Rx_km = (numPoints-1)*pointRes_km; % distance between Tx & Rx (km)

% Compute terminals' "effective height" corrections (for both base station 
% and mobile)
[hb_eff_m, hm_eff_m] = ExtendedHata_EffHeightCorr(hb_ant_m, hm_ant_m, elev);
 
% Compute median basic transmission loss
[LossEHMedian, ~] = ExtendedHata_MedianBasicPropLoss(freq_MHz, ...
    d_Tx_Rx_km, hb_eff_m, hm_eff_m, region);

% Compute undulation height terrain (delta_h) in order to check whether it 
% is a "quasi-smooth terrain" (delta_h <= 20m) or an "irregular 
% terrain" (delta_h > 20m). Only apply corrections for irregular terrain.
delta_h = ExtendedHata_UndulationHeight(elev);

if (delta_h <= 20)  % quasi-smooth terrain, corrections are not applied
    
    LossEH = LossEHMedian;
    
else                % irregular terrain, corrections are applied 
       
    % Compute the isolated mountain (or isolated ridge) correction
    % (applied only to single horizon paths)
    Kir = ExtendedHata_IsolatedRidgeCorr(elev);
        
    % Adjust the median basic transmission loss with the site-specific
    % correction factors
    if (Kir == 0)   % No isolated ridge. Apply "median" and "fine" 
                    % rolling hilly correction and general slope correction. 
        
        % Compute "median" and "fine" correction for rolling hilly terrain
        % (applied in the vicinity of the mobile station only).
        [Krh, ~, ~] = ExtendedHata_RollingHillyCorr(elev);
        
        % Compute the general slope of terrain correction (applied in the
        % vicinity of the mobile station only)        
        Kgs = ExtendedHata_GeneralSlopeCorr(elev);
        
        % The median basic transmission loss is:
        % - increased as the rolling hilly terrain correction Krh increases
        % - decreased as terrain rises from Tx to Rx (theta_m>0, Kgs>0), 
        %   and increased otherwise.
        LossEH = LossEHMedian + Krh - Kgs;        
        
    else            % Path contains a single isolated ridge. Do NOT apply 
                    % "median" and "fine" rolling hilly correction and 
                    % general slope correction. 
        
        % The median basic transmission loss is:
        % - increased as the isolated rigde correction factor Kir increases
        LossEH = LossEHMedian + Kir;
        
    end
        
    % Compute the mixed land-sea path correction
    Kmp = ExtendedHata_MixedPathCorr(elev);
    
    % Incorporate mixed land-sea path correction into the transmission loss    
    % - decreased by the mixed land-sea path correction
    LossEH = LossEH - Kmp;
    
end

% Adjust the propagation loss based on location variability
sigma = ExtendedHata_LocationVariability(freq_MHz, region);
LossEH = LossEH + sigma*randn;

