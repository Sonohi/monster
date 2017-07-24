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
% By: Thao Nguyen & Steven Smith (SURF Student, 2016)
% Date: 09/01/2016
%
% Description: Function to compute the isolated ridge correction factor 
% of the extended Hata propagation model.    
%
% Inputs: 
% - elev    : array containing elevation profile between Tx & Rx
%             where:
%             elev(1) = numPointss - 1 
%             (note, numPointss is the number of points between Tx & Rx)
%             elev(2) = distance between points (in meters). 
%             (thus, elev(1)-1)*elev(2)=distance between Tx & Rx)
%             elev(3) = Tx elevation (in meters)
%             elev(numPointss+2) = Rx elevation (in meters)
% Outputs:
% - Kir     : correction factor for isolated ridge (in decibels)
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
% - 2016/11/18: modified the code to:
%   + Set limitation for the mountain height above average ground to 
% [100, 1000] m. 
%   + Extended saturation points for Curves B and C in Figure 31 of [2].
% (Federated Wireless's comment)
% - 2016/12/16: modified input parameters going into the 'findpeaks' 
% function to make the code works with older versions (before 2016) of  
% Signal Processing Toolbox. (Key Bridge's comment)


function Kir = ExtendedHata_IsolatedRidgeCorr(elev)

% Extract data from elevation profile 
numPoints = elev(1) + 1;             % number of points between Tx & Rx
pointRes_km = elev(2)/1e3;           % distance between points (km)
pointElev_m = elev(3:2+numPoints);   % elevation vector (m)
d_Tx_Rx_km = (numPoints-1)*pointRes_km;% distance between Tx & Rx (km)
pointElev_m = pointElev_m(:)';       % Ensure row vector

% Distance from the Tx to each point along the path
d_Tx_point_km = (0:numPoints-1) * pointRes_km;
    
% Compute average ground level
h_ga_m = mean(pointElev_m);

% Find local maxima (peaks) of the horizon path that meet following
% conditions:
minPeakDist_km = 6;       % Use info in [2], Figure 31, upper left sub-plot
minPeakAboveGround_m = 100;% Use info in [2], Page 854, h=100~350 m
indHeightAboveThreshold = find(pointElev_m>minPeakAboveGround_m+h_ga_m,1);

if isempty(indHeightAboveThreshold) % no point above threshold found
    
    Kir = 0;
    return;
    
else % points found above threshold
    
    % Highest peak
    [peakHighest_m, indHighest] = max(pointElev_m);
    locHighest_km = d_Tx_point_km(indHighest);
    
    % Get peaks with desired minimum separation distance 
    [peaks_m, indlocs] = findpeaks(pointElev_m, ...
        'MinPeakDistance', minPeakDist_km);
    locs_km = d_Tx_point_km(indlocs);    

    % Find peak indices above threshold
    indPeakAboveThreshold = find(peaks_m > minPeakAboveGround_m + h_ga_m);
    
    if isempty(indPeakAboveThreshold) % can't find peak above threshold, 
        % assign the first point above threshold as peak. Note Matlab 
        % ignore peak without dropping data on the right side of the peak 
        
        peak_m = peakHighest_m;
        loc_km = locHighest_km;
        
    elseif ((length(indPeakAboveThreshold)==1) && ...
            (peaks_m(indPeakAboveThreshold) == peakHighest_m))
            % a single peak found
            
        peak_m = peaks_m(indPeakAboveThreshold);
        loc_km = locs_km(indPeakAboveThreshold);
        
    else % Return zero if a single mountain does not exist
        Kir = 0;
        return;        
    end;    
    
end;

% Return zero if the peak is lower than either Tx's elevation or Rx's
% elevation
if (peak_m < pointElev_m(1) || peak_m < pointElev_m(end))
    Kir = 0;
    return;
end

% Compute d1 (distance from Tx to mountain) and d2 (distance from mountain 
% to Rx)
d1_km = loc_km;        
d2_km = d_Tx_Rx_km - d1_km;

% Get the curves from Figure 31 of [2]
d2VecA_km = 0:0.5:8;   % distance from isolated ridge top to receiver
Kir_A = [20 6 -4 -6.5 -7 -6.5 -6 -5 -4.5 -4 -3.5 -3 -2.5 -2 -1.5 -1 -0.5];
d2VecB_km = 0:0.5:8.5;
Kir_B = [12 0 -8.5 -12 -13 -12.5 -12 -10.5 -10 -9 -8 -7 -6.5 -5.5 -4.5 ...
    -4 -3.5 -2.5];
d2VecC_km = [0:0.5:8.5 8.8];
Kir_C = [4 -4 -13 -16 -17.5 -18 -17.5 -16 -15 -14 -12.5 -11 -10 -9 -8 ...
    -7 -6 -5 -4];

% Apply piecewise linear interpolation to find the isolated ridge
% correction factor
if (d1_km >= 60)              % Distance >= 60 km, use A curve
   
    Kir = piecelin(d2VecA_km, Kir_A, min(d2_km, d2VecA_km(end)));
    
elseif (d1_km > 30 && d1_km < 60)   % 30 km < Distance < 60 km,
    % interpolate  A and B curves
    Kir_60 = piecelin(d2VecA_km, Kir_A, min(d2_km, d2VecA_km(end)));
    Kir_30 = piecelin(d2VecB_km, Kir_B, min(d2_km, d2VecB_km(end)));
    Kir = interp1([30, 60], [Kir_30, Kir_60], d1_km);
    
elseif (d1_km == 30)          % Distance = 30 km, use B curve
    
    Kir = piecelin(d2VecB_km, Kir_B, min(d2_km, d2VecB_km(end)));
    
elseif (d1_km > 15 && d1_km < 30)   % 15 km < Distance < 30 km,
    % interpolate  B and C curves
    Kir_30 = piecelin(d2VecB_km, Kir_B, min(d2_km, d2VecB_km(end)));
    Kir_15 = piecelin(d2VecC_km, Kir_C, min(d2_km, d2VecC_km(end)));
    Kir = interp1([15, 30], [Kir_15, Kir_30], d1_km);
    
elseif (d1_km <= 15)          % Distance <= 15 km, use C curve
    
    Kir = piecelin(d2VecC_km, Kir_C, min(d2_km, d2VecC_km(end)));
    
end

% Display an error msg if correction factor for normalized ridge height 
% (200 m) is outside of range [-20, 20] (dB)
if (Kir < - 20 || Kir > 20)
    disp(['Error: ExtendedHata_IsolatedRidgeCorr.m: Correction factor ' ...
        'is outside of [-20, 20] dB range']);
    Kir = 0;
    return;
end;

% Compute mountain height above average ground
h_m = peak_m - h_ga_m;

% Limit the range of mountain height above average ground to [100, 1000] m
if (h_m < 100)
    h_m = 100;
elseif (h_m > 1000);
    h_m = 1000;
end

% Find conversion factor ([2] Page 854, Eqn. (1) and Figure 32)
if h_m == 200
    alpha = 1;
else
    alpha = 0.07*(sqrt(h_m));
end

% Apply conversion factor to Kir
Kir = Kir * alpha;


