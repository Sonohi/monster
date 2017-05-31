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
% Description: script to test ExtendedHata_GeneralSlopeCorr.m function. 
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
Kgs = NaN(1, numPaths);
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
    Kgs(pp) = ExtendedHata_GeneralSlopeCorr(elev);
        
end;

% Plot correction factors versus distance.
figure;
plot(d_Tx_Rx_km, Kgs, 'r*');
hold on;
dVec_km = floor(min(d_Tx_Rx_km)):ceil(max(d_Tx_Rx_km));
plot(dVec_km, 15*ones(1,length(dVec_km)), 'r--');
plot(dVec_km, -20*ones(1,length(dVec_km)), 'r-');
hold off;
grid on;
title('General Slope Correction Factor');
xlabel('Distance (km)');
ylabel('Correction Factor (dB)');
legend('Correction (computed)', 'Correction (max)', 'Correction (min)');

% Plot general slope correction factor (Figure 34 of [2])
thetaVec_Neg = -20:5:0;   
kgs_Neg_LT10km = [-5 -3.5 -2 -1 0];
kgs_Neg_GT30km = [-18 -12.5 -8 -3.5 0];
thetaVec_Pos = 0:5:20;
kgs_Pos_LT10km = [0 1 2 2.5 3];
kgs_Pos_ET30km = [0 2.5 4.5 6 7];
kgs_Pos_GT60km = [0 4 7 10 12];

figure;
hold on;
plot(thetaVec_Neg, kgs_Neg_LT10km, thetaVec_Neg, kgs_Neg_GT30km);
plot(thetaVec_Pos, kgs_Pos_LT10km, thetaVec_Pos, kgs_Pos_ET30km, thetaVec_Pos, kgs_Pos_GT60km);
hold off;
grid on;
legend('d<10km', 'd>30km', 'd<10km', 'd=30km', 'd>60km', 'Location', 'best');
xlabel('Average Angle of Slope \theta_m (mr)');
ylabel('Slope Terrain Correction Factor K_{gs} (dB)');

