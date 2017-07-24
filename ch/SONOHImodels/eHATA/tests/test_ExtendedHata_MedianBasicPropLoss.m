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
% Description: script to test ExtendedHata_MedianBasicPropLoss.m function.
% and compare the results with Paul McKenna (NTIA, ITS)'s results presented
% at ISART 2015:
% http://www.its.bldrdoc.gov/media/66168/mckenna_presentation_20150513.pdf

% History:
% - 2016/09/01: released version 1.0

clear; close all; clc;

% Add the parent path which contains the ExtendedHata_PropLoss.m function
parentpath = cd(cd('..'));
addpath(parentpath);

% Frequency (MHz)
f = 1900;

% Distance (km)
dVec = linspace(0.01,2);

% Antenna heights of base station and mobile
hb = 50;
hmVec = [1.5 3 4.5 6];

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute and plot median basic extended Hata for Urban and Suburban
% regions
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% region
regionCell = {'Urban'; 'Suburban'};
for rr = 1:length(regionCell)
    region = regionCell{rr};
    
    % Compute propagation loss
    LossEHMatrix = NaN(length(hmVec), length(dVec));
    AbmEHMatrix = NaN(length(hmVec), length(dVec));
    
    % Loop over all mobile antenna heights
    for hh_=1:length(hmVec)
        
        % Current mobile antenna height
        hm = hmVec(hh_);
        
        % Loop over all distances
        for dd_=1:length(dVec)
            
            % Current distance
            d = dVec(dd_);
            
            % Compute propagation loss
            [MedianLossEH, MedianAbmEH] = ExtendedHata_MedianBasicPropLoss(f, d, hb, hm, region);
            
            % Store the results into matrices
            LossEHMatrix(hh_,dd_) = MedianLossEH;
            AbmEHMatrix(hh_,dd_) = MedianAbmEH;
        end
    end;
    
    % Plot basic median attenuation of extended Hata
    map = [0, 1, 0
        0, 0.8, 0
        0, 0.6, 0
        0, 0.4, 0];
    figure(rr)
    hold on;
    for ii=1:length(hmVec)
        plot(dVec, LossEHMatrix(ii,:), 'Color', map(ii,:), 'Linewidth', 2);
    end
    hold off;
    
    % Add labels
    if strcmp(region, 'Urban')
        axis([0 dVec(end) 100 240]);
    elseif strcmp(region, 'Suburban')
        axis([0 dVec(end) 100 220]);
    end
    grid on;
    strLegend1 = 'EH hm=';
    strLegend2 = num2str(hmVec');
    strLegend3 = 'm';
    strLegend = strcat(strLegend1, strLegend2, strLegend3);
    legend(strLegend, 'Location', 'best');
    xlabel('Distance (km)');
    ylabel('Median Basic Transmission Loss (dB)');
    title({['Extended Hata, hb=' num2str(hb) 'm, f=' num2str(f) 'MHz,'];region});
    
end

