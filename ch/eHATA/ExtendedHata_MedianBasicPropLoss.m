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
% Description: Function to compute the extended Hata median basic
% transmission loss.
%
% Inputs: 
% - f   : frequency (in MHz), 
%         in the range of [1500, 3000] MHz
% - d   : distance (in km) between transmitter and receiver, 
%         in the range of [1, 100] km
% - hb  : antenna height (in meter) of the base station, 
%         in the range of [30, 200] m     
% - hm  : antenna height (in meter) of the mobile station, 
%         in the range of [1, 10] m     
% - region: region of the area ('DenseUrban', 'Urban', 'Suburban')
%
% Outputs:
% - MedianLossEH  : median basic transmission loss (in dB)
% - MedianAbmEH   : basic median attenuation relative to free space (in dB)
%
% Note: the variable names are similar to thoese the NTIA Report [1]

% References: 
% [1] U.S. Department of Commerce, National Telecommunications and 
%     Information Administration, 3.5 GHz Exclusion Zone Analyses and 
%     Methodology (Jun. 18, 2015), available at 
%     http://www.its.bldrdoc.gov/publications/2805.aspx.
% [2] Y. Okumura, E. Ohmori, T. Kawano, and K. Fukuda, Field strength and
%     its variability in VHF and UHF land-mobile radio service, Rev. Elec. 
%     Commun. Lab., 16, 9-10, pp. 825-873, (Sept.-Oct. 1968).
% [3] M. Hata, Empirical formula for propagation loss in land mobile radio
%     services, IEEE Transactions on Vehicular Technology, VT-29, 3,
%     pp. 317-325 (Aug. 1980).
% [4] Anita G. Longley, Radio Propagation in Urban Areas, United States 
%     Department of Commerce, Office of Telecommunications, OT Report 
%     78-144 (Apr.1978), available at 
%     http://www.its.bldrdoc.gov/publications/2674.aspx.
%
% History:
% - 2016/09/01: released version 1.0
% - 2016/11/30: set limitation, [30, 200] m, for base station's antenna
% height.
% - 2016/12/16: 
%   + set limitation, [1, 10] m, for mobile station's antenna height.
%   + print a warning message if the distance, d, is outside of range 
% [1, 100] km. 
% (Key Bridge and Federated Wireless's comments)

function [MedianLossEH, MedianAbmEH] = ExtendedHata_MedianBasicPropLoss(...
    f, d, hb, hm, region)


%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Adjust input parameters so that they are within the range of those
% supported by the propagation model., i.e. if out of range, set to lower 
% and upper limits
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% % Frequency 
% if (f<1500)
%     f = 1500;   
% elseif (f>3000)
%     f = 3000;   
% end
% Check distance 
if (d<1 || d>100)
    warning(['ExtendedHata_MedianBasicPropLoss.m: Invalid result. ' ...
        'Distance is outside of range [1, 100] km.']);      
end
% Set limitation for base station's antenna height
if (hb < 30)
    hb = 30;
elseif (hb > 200)
    hb = 200;   
end
% Set limitation for mobile station's antenna height
if (hm < 1)
    hm = 1;   
elseif (hm > 10)
    hm = 10;   
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Compute median basic transmission loss for urban region
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Obtain the base station effective height dependence of the lower
% distance range power law component of the median attenuation relative to
% free space (Page 30 of [1])
nl = 0.1*(24.9 - 6.55*log10(hb));

% Obtain the base station effective height dependence of the higher
% distance range power law component of the median attenuation relative to
% free space (Page 30 of [1])
nh = 2*(-1.75 + 3.27*log10(hb) - 0.67*(log10(hb))^2);

% Compute basic median attenuation relative to free space at the reference
% base and mobile stations effective heights
% @ reference distance of 1 km (Eqn. (A-6) of [1] with d = 1)
Abmf1 = 30.52 - 16.81*log10(f) + 4.45*(log10(f))^2; 
abmf1 = 10^(Abmf1/10);  % Note A(f,d) = 10*log10(a(f,d))
% @ reference distance of 100 km (alpha_100=120.78, beta_100=-52.71, 
% gamma_100=10.92 on Page 30 of [1])
Abmf100 = 120.78 - 52.71*log10(f) + 10.92*(log10(f))^2;
abmf100 = 10^(Abmf100/10); 

% Compute "break-point" distance (in km) (Eqn. (A-9b) of [1])
dbp = (10^(2*nh) * abmf1 / abmf100)^(1/(nh-nl)); 

% Compute direct LOS distance (in meters) between base station and mobile 
% station (Eqn. (A-12) of [1])
R = sqrt((d*1e3)^2 + (hb-hm)^2);

% Compute free space loss 
Lfs = 20*log10(f) + 20*log10(R) - 27.56;

% Compute power law exponent (Eqn (A-13) of [1]) (Note: the conditions have 
% been relaxed to account for distances < 1 km or > 100 km)
if (d<=dbp)
    n = nl;
elseif (d>dbp)
    n = nh;
end

% Compute basic median attenuation relative to free space at break point
% distance (Eqn. (A-11) of [1])
Abmfdbp = 30.52 - 16.81*log10(f) + 4.45*(log10(f))^2 ...
                 + (24.9 - 6.55*log10(hb)) * log10(dbp);   
             
% Compute correction factor for hm (Eqn. (A-2a) of [1])
ahm = 3.2*(log10(11.75*hm))^2 - 4.97; 
a3 = 3.2*(log10(11.75*3))^2 - 4.97;

% Compute median basic transmission loss (Eqn. (A-10) of [1])
MedianLossEH = Abmfdbp + 10*n*log10(d/dbp) + 13.82*log10(200/hb) + a3 ...
    - ahm + Lfs;

% Get basic median attenuation relative to free space for validation
% purpose
MedianAbmEH = MedianLossEH - Lfs;

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Adjust the loss for suburban region by subtracting suburban correction 
% factor
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
if strcmp(region, 'Suburban')   % adjust for suburban area 
    MedianLossEH = MedianLossEH - (54.19 - 33.30*log10(f) + 6.25*(log10(f))^2);
                                    % (Eqn. (A-14) of [1])
    MedianAbmEH = MedianLossEH - Lfs; 
end   

    
