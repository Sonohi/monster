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
% Description: script to test ExtendedHata_RollingHillyCorr.m function. 
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

% Initialize parameters
hb_ant_m = 50;
hm_ant_m = 3;

% Compute propagation loss for each path
Krh = NaN(1, numPaths);
Kh = NaN(1, numPaths);
Khf = NaN(1, numPaths);
d_Tx_Rx_km = NaN(1, numPaths);
for pp = 1:numPaths
    
    disp(['Path: ' num2str(pp)]);
    
    % Get elevation profile
    elev = elevCell{pp};
    
    % Tx-Rx distance of each path
    numPoints = elev(1) + 1;                % number of points between Tx & Rx
    pointRes_km = elev(2)/1e3;              % distance between points (km)
    d_Tx_Rx_km(pp) = (numPoints-1)*pointRes_km; % distance between Tx & Rx (km)
    
    % Compute Tx/Rx effective heights
    [Krh(pp), Kh(pp), Khf(pp)] = ExtendedHata_RollingHillyCorr(elev);
        
end;

% Plot correction factors versus distance.
figure;
plot(d_Tx_Rx_km, Krh, 'r*', d_Tx_Rx_km, Kh, 'bo', d_Tx_Rx_km, Khf, 'gs');
hold on;
dVec_km = floor(min(d_Tx_Rx_km)):ceil(max(d_Tx_Rx_km));
plot(dVec_km, 30*ones(1,length(dVec_km)), 'b--');
plot(dVec_km, -2*ones(1,length(dVec_km)), 'b-');
plot(dVec_km, 20*ones(1,length(dVec_km)), 'g--');
plot(dVec_km, -20*ones(1,length(dVec_km)), 'g-');
hold off;
title('Rolling Hilly Correction Factor');
xlabel('Distance (km)');
ylabel('Correction Factor (dB)');
legend('Total=Median-Fine', 'Median', 'Fine', 'Median (max)', 'Median (min)', ...
    'Fine (max)', 'Fine (min)');

% Plot median and fine correction factors (see Equations (A-16), (A-17) of 
% [1], and Figures 28-29 of [2])
deltahVec = 10:10:500;
Kh = 1.507213 - 8.458676 * log10(deltahVec) + ...
    6.102538 * (log10(deltahVec)).^2;

KhfMax = -11.728795 + 15.544272 * log10(deltahVec) - ...
   1.8154766 * (log10(deltahVec)).^2;

figure;
subplot(2,1,1)
semilogx(deltahVec, Kh);
title('Rolling Hilly Terrain Median Correction Factor K_h (dB)');
xlim([10 500]);
grid

subplot(2,1,2)
semilogx(deltahVec, KhfMax);
xlabel('Terrain Undulation Height \Deltah (m)');
title('Rolling Hilly Terrain Fine Correction Factor K_{hf} (+/-dB)');
xlim([10 500]);
grid




