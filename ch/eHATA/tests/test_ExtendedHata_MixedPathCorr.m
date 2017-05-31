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
% ERROR FREE. IN NO EVENT SHALL NASA BE LIABLE FOR ANY DAMAGES, INCLUDING, 
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
% Description: script to test ExtendedHata_MixedPathCorr.m function. 
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

clear; close all; clc;

% Add the parent path which contains the function
parentpath = cd(cd('..'));
addpath(parentpath);

% Load a set of elevation profiles 
load('ElevProfile_MultiplePaths.mat');
numPaths = length(elevCell);

% Compute correction for each path
Kmp = NaN(1, numPaths);
d_Tx_Rx_km = NaN(1, numPaths);
for pp = 1:numPaths
    
    disp(['Path: ' num2str(pp)]);
    
    % Get elevation profile
    elev = elevCell{pp};
    
    % Tx-Rx distance of each path
    numPoints = elev(1) + 1;                % number of points between Tx & Rx
    pointRes_km = elev(2)/1e3;              % distance between points (km)
    d_Tx_Rx_km(pp) = (numPoints-1)*pointRes_km; % distance between Tx & Rx (km)
    
    % Compute correction factor
    Kmp(pp) = ExtendedHata_MixedPathCorr(elev);
        
end;

% Plot correction factors versus distance.
figure;
plot(d_Tx_Rx_km, Kmp, 'r*');
hold on;
dVec_km = floor(min(d_Tx_Rx_km)):ceil(max(d_Tx_Rx_km));
plot(dVec_km, 15*ones(1,length(dVec_km)), 'r--');
plot(dVec_km, zeros(1,length(dVec_km)), 'r-');
hold off;
title('Mixed Path Correction Factor');
xlabel('Distance (km)');
ylabel('Correction Factor (dB)');
legend('Correction (computed)', 'Correction (max)', 'Correction (min)', ...
    'Location', 'best');
grid

% Plot the curves similart to Figure 35 of [2]
beta = 0:10:100;   % distance ratio (percentage)
Kmp_dGreater60km_A = [0 3 5.3 7.5 9.2 10.5 11.8 12.7 13.5 14.2 14.8];
Kmp_dGreater60km_B = [0 1.5 2.5 4 5.5 7 9 10.8 12.5 14.2 14.8];

Kmp_dLessThan30km_A = [0 2 3.8 5 6.3 7.5 8.5 9.3 10 10.5 11];
Kmp_dLessThan30km_B = [0 0.5 1.5 2.5 3.5 4.8 6 7.8 9.5 10.5 11];

% Plot
figure;
hold on;
plot(beta, Kmp_dGreater60km_A, 'b-')
plot(beta, Kmp_dGreater60km_B, 'b--');
plot(beta, Kmp_dLessThan30km_A, 'r-');
plot(beta, Kmp_dLessThan30km_B, 'r--');
hold off;

xlabel('Distance Ratio \beta (d_s/d) (%)');
ylabel('Mixed Path Correction Factor K_{mp} (dB)');
axis([0 100 0 20]);
grid;
legend('A (d>60km)', 'B (d>60km)', 'A (d<30km)', 'B (d<30km)');


