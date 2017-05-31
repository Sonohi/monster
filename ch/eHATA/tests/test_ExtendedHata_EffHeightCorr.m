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
% Description: script to test ExtendedHata_EffHeightCorr.m function. 
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

% Initialize parameters
hb_ant_m = 50;
hm_ant_m = 3;

% Compute propagation loss for each path
hb_eff_m = NaN(1, numPaths);
hm_eff_m = NaN(1, numPaths);
d_Tx_Rx_km = NaN(1, numPaths);
for pp = 1: numPaths
    
    disp(['Path: ' num2str(pp)]);
    
    % Get elevation profile
    elev = elevCell{pp};
    
    % Tx-Rx distance of each path
    numPoints = elev(1) + 1;                % number of points between Tx & Rx
    pointRes_km = elev(2)/1e3;              % distance between points (km)
    d_Tx_Rx_km(pp) = (numPoints-1)*pointRes_km; % distance between Tx & Rx (km)
    
    % Compute Tx/Rx effective heights
    [hb_eff_m(pp), hm_eff_m(pp)] = ExtendedHata_EffHeightCorr(hb_ant_m, ...
    hm_ant_m, elev);

end;

% Plot path loss versus distance
figure;
plot(d_Tx_Rx_km, hb_eff_m, 'bo', d_Tx_Rx_km, hm_eff_m, 'r*')
title('Effective Height Correction Factor');
xlabel('Distance (km)');
ylabel('Effective Height (m)');
legend('Base station', 'Mobile station', 'Location', 'best');
grid;





