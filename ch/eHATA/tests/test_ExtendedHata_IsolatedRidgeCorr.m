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
% Description: script to test ExtendedHata_IsolatedRidgeCorr.m function. 
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

% Load a set of elevation profiles in San Diego, CA
load('ElevProfile_MultiplePaths.mat');
numPaths = length(elevCell);

% Compute propagation loss for each path
Kir = NaN(1, numPaths);
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
    Kir(pp) = ExtendedHata_IsolatedRidgeCorr(elev);
        
end;

% Plot correction factors versus distance. Note that min/max boundaries of
% the correction will not be plotted because they do not account for the
% conversion factor when h~=200m.
figure;
hold on;
plot(d_Tx_Rx_km, Kir, 'r*');
hold off;
title('Isolated Ridge Correction Factor');
xlabel('Distance (km)');
ylabel('Correction Factor (dB)');
grid on;

% Plot correction factor curves (see Figure 31 of [2]
d2Vec_km = 0:0.5:8;   % distance from isolated ridge top to receiver
Kir_A = [20 6 -4 -6.5 -7 -6.5 -6 -5 -4.5 -4 -3.5 -3 -2.5 -2 -1.5 -1 -0.5];
Kir_B = [12 0 -8.5 -12 -13 -12.5 -12 -10.5 -10 -9 -8 -7 -6.5 -5.5 -4.5 ...
    -4 -3.5];
Kir_C = [4 -4 -13 -16 -17.5 -18 -17.5 -16 -15 -14 -12.5 -11 -10 -9 -8 ...
    -7 -6];

figure;
hold on;
plot(d2Vec_km, Kir_A, 'b-')
plot(d2Vec_km, Kir_B, 'r+-');
plot(d2Vec_km, Kir_C, 'g--');
hold off;

xlabel('Distance from Isolated Ridge Top d_2 (km)');
ylabel('Isolated Ridge Correction Factor K_{ir} (dB)');
axis([0 10 -30 20]);
grid;
legend('A curve:d_1>=60km', 'B curve:d_1=30km', 'C curve:d_1<=15km');

% Plot conversion factor alpha to be multiplied to the value of Fig. 31 of
% [1] when ridge height h~=200m.
hVec_m = 100:1000;
alphaVec = 0.07*(sqrt(hVec_m));
figure;
semilogx(hVec_m, alphaVec);
title('\alpha = 0.07(h)^{1/2}');
xlabel('Isolated Ridge Height h(m)')
ylabel('Correction Factor \alpha');
grid on;


