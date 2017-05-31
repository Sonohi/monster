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
% Date: 11/17/2016
%
% Description: Function to compute terrain irregularity parameter delta_h 
% for the terrain within 10 km of the mobile station. 
% Note that Okumura refered to delta_h as the terrain undulation parameter. 
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
% - delta_h : terrain undulation parameter (in meters)
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
% - 2016/11/17: an additional function to be added to released version 1.0 
% - 2017/04/19: fixed equation to compute delta_h for path less than 10 km
% in distance (Eqn. (A-15) of [1]) (Federated Wireless's comment)

function delta_h = ExtendedHata_UndulationHeight(elev)

% Extract data from elevation profile 
numPoints = elev(1) + 1;             % number of points between Tx & Rx
pointRes_km = elev(2)/1e3;           % distance between points (km)
pointElev_m = elev(3:2+numPoints);   % elevation vector (m)
d_Tx_Rx_km = (numPoints-1)*pointRes_km;% distance between Tx & Rx (km)

% Distance from each point along the path to the Rx-er
d_point_Rx_km = (numPoints-1:-1:0) * pointRes_km;

% Get terrain within 10 km of the mobile station
radius_km = 10;
elevInside_m = pointElev_m(d_point_Rx_km <= radius_km);

% Compute terrain height which is exceeded for 10%, 90%, and 50% of the 
% terrain elevations, respectively (see Figure 5 of [2])
hVec = prctile(elevInside_m, [90, 10]);
h_10 = hVec(1);
h_90 = hVec(2);

% Compute terrain irregularity parameter(terrain undulation parameter)
delta_h = h_10 - h_90;

% If the path is less than 10 km in distance, then the asymptotic value for
% the terrain irregularity is adjusted (Eqn. (A-15) of [1])
if (d_Tx_Rx_km < radius_km) 
    delta_h = delta_h * (1-0.8*exp(-0.2)) / ...
        (1-0.8*exp(-0.02*d_Tx_Rx_km));    
end

