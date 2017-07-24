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
% Description: Function to compute the general slope of terrain correction 
% of the extended Hata propagation model.    
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
% - Kgs     : correction factor for general slope (in decibels)
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
% - 2016/11/18: modified the code to stop extrapolating at -15 mr for
% d > 30 km case (Federated Wireless's comment)


function Kgs = ExtendedHata_GeneralSlopeCorr(elev)

% Distance range on the mobile station's end of the path
d_min_km = 5;
d_max_km = 10;

% Extract data from elevation profile 
numPoints = elev(1) + 1;             % number of points between Tx & Rx
pointRes_km = elev(2)/1e3;           % distance between points (km)
pointElev_m = elev(3:2+numPoints);   % elevation vector (m). Note, zeros 
                               % might be padded to the end of the vector.
d_Tx_Rx_km = (numPoints-1)*pointRes_km;% distance between Tx & Rx (km)
pointElev_m = pointElev_m(:)';       % Ensure row vector

% If all elevations = 0 or distance < d_min_km, set correction factor = 0
if ((isempty(find(pointElev_m,1))) || (d_Tx_Rx_km < d_min_km))
    Kgs = 0;
    return;
end

% Distance from each point to the Rx-er (km)
d_point_Rx_km = (numPoints-1:-1:0) * pointRes_km;

% Compute the average angle of general terrain slope
intervalVec_km = d_min_km : min(d_max_km, floor(d_Tx_Rx_km));
angle = zeros(1,length(intervalVec_km));

for ii = 1: length(intervalVec_km)
    
    % Get elevation within a certain distance of the mobile station
    elevTemp_m = pointElev_m(d_point_Rx_km <= intervalVec_km(ii));
        
    % Get the slope for this interval
    p = polyfit(0:length(elevTemp_m)-1, elevTemp_m, 1);
    slope = p(1);
    
    % Calculate the angle using the slope designated (compensating for 
    % difference in axis units (pointRes_m vs m))  
    angle(ii) = atan(slope/(pointRes_km*1e3));
      
end

% Subtract the computed angle from average angle of the overall path distance
pOverall = polyfit(0:numPoints-1, pointElev_m, 1);
slopeOverall = pOverall(1);
angleOverall = atan(slopeOverall/(pointRes_km*1e3)); 
angle = angle - angleOverall;                            

% Select which slope will be used, based on the criteria of [1] Pages 33-34
if (length(find(angle>0))==length(intervalVec_km)) % all six slopes > 0
    primary_angle = max(angle);    
elseif (length(find(angle<0))==length(intervalVec_km)) % all six slopes < 0
    primary_angle = min(angle); 
else % mix slopes have mixture of signs, use the slope at d_min_km = 5
    primary_angle = angle(1);
end
       
% Convert angle (radians) to angle (milliradians)
angle_mr = primary_angle * 1000;    

% Set min and max for angle_mr ([2] Figure 34)
if angle_mr < -20
    angle_mr = -20;
elseif angle_mr > 20
    angle_mr = 20;
end;
    
% Determine the correction factor using curves obtained from Figure 34 of
% [2]
thetaVec_Neg_LT10km = -20:5:0;   
kgs_Neg_LT10km = [-5 -3.5 -2 -1 0];
thetaVec_Neg_GT30km = -15:5:0;   
kgs_Neg_GT30km = [-12.5 -8 -3.5 0];
thetaVec_Pos = 0:5:20;
kgs_Pos_LT10km = [0 1 2 2.5 3];
kgs_Pos_ET30km = [0 2.5 4.5 6 7];
kgs_Pos_GT60km = [0 4 7 10 12];

% Check average angle of slope
if (angle_mr == 0)          % angle_mr is zero    
    
    Kgs = 0;
    
elseif (angle_mr < 0)       % angle_mr is negative
    
    if (d_Tx_Rx_km < 10)    % Resolve for distance < 10 km
        
        Kgs = piecelin(thetaVec_Neg_LT10km, kgs_Neg_LT10km, angle_mr);
        
    elseif (d_Tx_Rx_km >= 10 && d_Tx_Rx_km <= 30)   % Resolve for distance 
                                                    % [10, 30] km
        
        % Linear interpolation b/w kgs_Neg_LT10km and kgs_Neg_GT30km curves
        kgs_10 = piecelin(thetaVec_Neg_LT10km, kgs_Neg_LT10km, angle_mr);
        kgs_30 = piecelin(thetaVec_Neg_GT30km, kgs_Neg_GT30km, ...
            min(angle_mr, thetaVec_Neg_GT30km(1))); % Set saturation value 
                                                    % angle_mr = -15 (mr) 
        Kgs = interp1([10, 30], [kgs_10, kgs_30], d_Tx_Rx_km);
        
    elseif (d_Tx_Rx_km > 30)  % Resolve for distance > 30 km. 
                              % Set saturation value angle_mr = -15 (mr) 
        
        Kgs = piecelin(thetaVec_Neg_GT30km, kgs_Neg_GT30km, ...
            min(angle_mr, thetaVec_Neg_GT30km(1)));
        
    end
    
else                        % angle_mr is positive
    
    if (d_Tx_Rx_km < 10)    % Resolve for distance < 10 km
        Kgs = piecelin(thetaVec_Pos, kgs_Pos_LT10km, angle_mr);
        
    elseif (d_Tx_Rx_km >= 10 && d_Tx_Rx_km < 30)    % Resolve for distance 
                                                    % [10, 30) km
        
        % Linear interpolation b/w kgs_Pos_LT10km and kgs_Pos_ET30km curves
        kgs_10 = piecelin(thetaVec_Pos, kgs_Pos_LT10km, angle_mr);
        kgs_30 = piecelin(thetaVec_Pos, kgs_Pos_ET30km, angle_mr);
        Kgs = interp1([10, 30], [kgs_10, kgs_30], d_Tx_Rx_km);
        
    elseif (d_Tx_Rx_km == 30) % Resolve for distance = 30 km
        
        Kgs = piecelin(thetaVec_Pos, kgs_Pos_ET30km, angle_mr);
        
    elseif (d_Tx_Rx_km > 30 && d_Tx_Rx_km <= 60)    % Resolve for distance 
                                                    % (30, 60] km
        % Linear interpolation b/w kgs_Pos_ET30km and kgs_Pos_GT60km curves
        kgs_30 = piecelin(thetaVec_Pos, kgs_Pos_ET30km, angle_mr);
        kgs_60 = piecelin(thetaVec_Pos, kgs_Pos_GT60km, angle_mr);
        Kgs = interp1([30, 60], [kgs_30, kgs_60], d_Tx_Rx_km);
        
    elseif (d_Tx_Rx_km > 60)  % Resolve for distance > 60 km
        
        Kgs = piecelin(thetaVec_Pos, kgs_Pos_GT60km, angle_mr);
        
    end
end

% Display an error msg if correction factor is outside [-20, 20] (dB) range
if (Kgs < - 20 || Kgs > 20)
    disp(['Error: ExtendedHata_GeneralSlopeCorr.m: Correction '...
    'factor is outside of [-20, 20] dB range']);
    Kgs = 0;
    return;
end


