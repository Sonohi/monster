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
% Description: Function to compute terminals' "effective height" 
% corrections (for both base station and mobile) (see [1,2]).
% The terminals’ “effective height” corrections are defined as the 
% difference between the height of the terminal above mean sea level 
% (the sum of the terminal’s structural height above ground and the height 
% of the terrain below the terminal above mean sea level) and the average 
% height of terrain above mean sea level from 3 to 15 km distance from the
% terminal in question. These quantities are to be used in the height gain 
% terms in the extended Hata formulas. For paths less than 3 km, the 
% terminal’s structural height is used. For path distances between 3 and 
% 15 km length, the average ground height is weighted by fraction of the 
% path distance relative to 15 km.
% Note that if the effective height is negative, it will be set equal to 
% the average height of terrain above mean sea level.
%
% Inputs:
% - hb_ant_m    : antenna height (in meters) of the base station. 
% - hm_ant_m    : antenna height (in meters) of the mobile station. 
% - elev        : array containing elevation profile between Tx & Rx.
%
% Outputs:
% - hb_eff_m    : effective transmitting antenna height (in meters) of the 
%                base station. 
% - hm_eff_m    : effective receiving antenna height (in meters) of the 
%                mobile station. 
% 
% References: 
% [1] U.S. Department of Commerce, National Telecommunications and 
%     Information Administration, 3.5 GHz Exclusion Zone Analyses and 
%     Methodology (Jun. 18, 2015), available at 
%     http://www.its.bldrdoc.gov/publications/2805.aspx.
% [2] Y. Okumura, E. Ohmori, T. Kawano, and K. Fukuda, Field strength and
%     its variability in VHF and UHF land-mobile radio service, Rev. Elec. 
%     Commun. Lab., 16, 9-10, pp. 825-873, (Sept.-Oct. 1968).
% 
% History:
% 2016/09/01: released version 1.0
% 2016/11/16: 
% - Updated effective height calculation for 3 <= d < 15 km case.
% - Set limitation, [30, 200] m, for effective height of the base station.
% (Key Bridge and Federated Wireless's comments)
% 2016/12/16:
% - Set limitation, [1, 10] m, for effective height of the mobile station.
% (Key Bridge and Federated Wireless's comments)

function [hb_eff_m, hm_eff_m] = ExtendedHata_EffHeightCorr(hb_ant_m, ...
    hm_ant_m, elev)

% Distance range from the terminal
d_min_km = 3;
d_max_km = 15;

% Extract data from elevation profile 
numPoints = elev(1) + 1;            % number of points between Tx & Rx
pointRes_km = elev(2)/1e3;          % distance between points (km)
pointElev_m = elev(3:2+numPoints);  % elevation vector (m)
d_Tx_Rx_km = (numPoints-1)*pointRes_km;% distance between Tx & Rx (km)

% For path less than d_min_km, the terminal’s structural height is used.
if (d_Tx_Rx_km < d_min_km)    
    hb_eff_m = hb_ant_m;            % base station effective height
    hm_eff_m = hm_ant_m;            % mobile effection height
    return;
end

%%%%%%%%%%%%%%%% Compute effective height for base station %%%%%%%%%%%%%%%%
% Distance from the Tx to each point along the path
d_Tx_point_km = (0:numPoints-1) * pointRes_km;

% Compute the average height of terrain above mean sea level:
% - from d_min_km to d_max_km distance from the base station, if d_Tx_Rx_km > d_max_km
% - from d_min_km to d_Tx_Rx_km, if d_Tx_Rx_km < d_max_km
pointElevInRange_m = pointElev_m(d_Tx_point_km >= d_min_km & ...
        d_Tx_point_km <= min(d_max_km, d_Tx_Rx_km));
hb_ga_m = mean(pointElevInRange_m);

% Compute terminal's "effective height" correction
hb_eff_m = (hb_ant_m + pointElev_m(1)) - hb_ga_m;

% Limit the effective height to [30, 200] m
if hb_eff_m < 30
    hb_eff_m = 30;
elseif hb_eff_m > 200
    hb_eff_m = 200;
end

%%%%%%%%%%%%%%%% Compute effective height for mobile station %%%%%%%%%%
% Distance from each point to the Rx-er
d_point_Rx_km = (numPoints-1:-1:0) * pointRes_km;

% Compute the average height of terrain above mean sea level:
% - from d_min_km to d_max_km distance from the mobile station, if d_Tx_Rx_km > d_max_km
% - from d_min_km to d_Tx_Rx_km, if d_Tx_Rx_km < d_max_km
pointElevInRange_m = pointElev_m(d_point_Rx_km >= d_min_km & ...
    d_point_Rx_km <= min(d_max_km, d_Tx_Rx_km));
hm_ga_m = mean(pointElevInRange_m);

% Compute terminal's "effective height" correction
hm_eff_m = (hm_ant_m + pointElev_m(end)) - hm_ga_m;

% Limit the effective height to [1, 10] m
if hm_eff_m < 1
    hm_eff_m = 1;
elseif hm_eff_m > 10
    hm_eff_m = 10;
end


    
 
