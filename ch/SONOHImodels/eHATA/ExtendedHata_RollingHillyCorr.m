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
% Description: Function to compute "median" and "fine" rolling hilly
% terrain corrections for extended Hata propagation model. They are applied
% in the vicinity of the mobile station only). According to [2], this may
% apply to a mountainous area where there are several mountains which
% affect the receiving point by multiple diffraction, but not to a simple
% sloped terrain or where there is only one undulation.
% 
% Inputs: 
% - elev    : array containing elevation profile between Tx & Rx
%             where:
%             elev(1) = numPoints - 1 
%             (note, numPoints is the number of points between Tx & Rx)
%             elev(2) = distance between points (in meters). 
%             (thus, elev(1)-1)*elev(2)=distance between Tx & Rx)
%             elev(3) = Tx elevation (in meters)
%             elev(numPoints+2) = Rx elevation (in meters)
%
% Outputs: 
% - Krh     : total (both "median" and "fine") correction factor  for  
%             rolling hilly terrain (in decibels)
% - Kh      : "median" correction factor for rolling hilly terrain 
%             (in decibels)
% - Khf     : "fine" correction factor for rolling hilly terrain 
%             (in decibels)
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
% - 2016/09/01: released version 1.0
% - 2016/10/30: used 'prctile' function to compute terrain height which is 
% exceeded for 10%, 90%, and 50% of the terrain elevations (Google's comment)
% - 2016/11/28: set terrain undulation height = 10 m if < 10 m 
% (Federated Wireless's comment)
% - 2017/04/19: fixed equation to compute delta_h for path less than 10 km
% in distance (Eqn. (A-15) of [1]) (Federated Wireless's comment)

function [Krh, Kh, Khf] = ExtendedHata_RollingHillyCorr(elev)

% Extract data from elevation profile 
numPoints = elev(1) + 1;             % number of points between Tx & Rx
pointRes_km = elev(2)/1e3;           % distance between points (km)
pointElev_m = elev(3:2+numPoints);   % elevation vector (m)
d_Tx_Rx_km = (numPoints-1)*pointRes_km;% distance between Tx & Rx (km)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute terrain irregularity parameter deltah for the terrain within 10
% km of the mobile station. Note that Okumura refered to delta_h as the
% terrain undulation parameter. 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% If flat terrain,correction factor = 0
if (isempty(find(pointElev_m,1)))
    Krh = 0;
    Kh = 0;
    Khf = 0;
    return;
end

% Distance from each point along the path to the Rx-er
d_point_Rx_km = (numPoints-1:-1:0) * pointRes_km;

% Get terrain within 10 km of the mobile station
radius_km = 10;
elevInside_m = pointElev_m(d_point_Rx_km <= radius_km);

% Compute terrain height which is exceeded for 10%, 90%, and 50% of the 
% terrain elevations, respectively (see Figure 5 of [2])
hVec = prctile(elevInside_m, [90, 10, 50]);
h_10 = hVec(1);
h_90 = hVec(2);
h_50 = hVec(3);

% Compute terrain irregularity parameter(i.e.,terrain undulation parameter)
delta_h = h_10 - h_90;

% If the path is less than 10 km in distance, then the asymptotic value for
% the terrain irregularity is adjusted (Eqn. (A-15) of [1])
if (d_Tx_Rx_km < radius_km) 
    delta_h = delta_h * (1-0.8*exp(-0.2)) / ...
        (1-0.8*exp(-0.02*d_Tx_Rx_km));    
end

% Check terrain undulation height to ensure it is within [10, 500] m 
% ([2], Figures 28, 29)
if (delta_h < 10)   % set terrain undulation height = 10 m if < 10 m 
    delta_h = 10;
elseif (delta_h > 500) % set terrain undulation height = 500 m if > 500 m
    delta_h = 500;
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute "median" rolling hill terrain corrections ([1] Eqn. (A-16))
% Note that Kh (in [1] Eqn. (A-16)) = -Kh (in [2] Figure 28c) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

Kh = 1.507213 - 8.458676 * log10(delta_h) + ... 
    6.102538 * (log10(delta_h)).^2;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute "fine" rolling hill terrain corrections
% Note that KhfMax (in [1] Eqn. (A-16)) = KhfMax (in [2] Figure 29) 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Compute the maximum magnitude of the correction ([1] Eqn. (A-17))
KhfMax = -11.728795 + 15.544272 * log10(delta_h) - ...
    1.8154766 * (log10(delta_h)).^2;

% Get elevation at the receiver
elevRx_m = pointElev_m(end); 

% Determine the value of Khf based on receiver's terrain height 
% ([2], Figure 29)
if (elevRx_m<=h_90)           % at the bottom of the undulation
    Khf = -KhfMax;     
elseif (h_90<elevRx_m) && (elevRx_m<h_50) % rising up from bottom
    Khf = interp1([h_90 h_50], [-KhfMax 0], elevRx_m);
elseif (elevRx_m == h_50)     % at terrain median height
    Khf = 0;
elseif (h_50<elevRx_m) && (elevRx_m<h_10) % near top of undulation
    Khf = interp1([h_50 h_10], [0 KhfMax], elevRx_m);
elseif (elevRx_m>=h_10)       % at or above top of undulation
    Khf = KhfMax;    
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute the total rolling hill terrain correction
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% According to [1] Page 33, the "fine" rolling hilly terrain correction is 
% negative/positive in terms of its contribution to the median basic 
% transmission loss depending on whether the mobile station's terrain 
% height is greater/less-than the median terrain height exceedance level.
Krh = Kh - Khf;



