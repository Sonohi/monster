function fixpar = getScenarioParam(StreetWidth)
%GETSCENARIOPARAM Scenario specific parameters of WIM channel model
%   FIXPAR = GETSCENARIOPARAM(STREETWIDTH) sets scenario specific
%   parameters given in [1, Tables 4.5-4.9]. STREETWIDTH only applies to B1
%   and B2 scenarios.

% Copyright 2016 The MathWorks, Inc.

%% A1, LOS
% Fixed scenario specific parameters
fixpar.A1.LoS.NumClusters    = 12;      % Number of ZDSC    [1, Table 4.5]
fixpar.A1.LoS.r_DS           = 3;       % Delays spread proportionality factor
fixpar.A1.LoS.PerClusterAS_D = 5;       % Per cluster FS angle spread [deg] [1, Table 4.5]
fixpar.A1.LoS.PerClusterAS_A = 5;       % Per cluster MS angle spread [deg] [1, Table 4.5]
fixpar.A1.LoS.LNS_ksi        = 6;       % ZDSC LNS ksi [dB], per cluster shadowing [1, Table 4.5]

% Cross correlation coefficients [1, Table 4.5]
fixpar.A1.LoS.asD_ds  =  0.7;             % departure AS vs delay spread
fixpar.A1.LoS.asA_ds  =  0.8;             % arrival AS vs delay spread
fixpar.A1.LoS.asA_sf  = -0.5;            % arrival AS vs shadowing std
fixpar.A1.LoS.asD_sf  = -0.5;            % departure AS vs shadowing std
fixpar.A1.LoS.ds_sf   = -0.6;            % delay spread vs shadowing std
fixpar.A1.LoS.asD_asA =  0.6;             % departure AS vs arrival AS
fixpar.A1.LoS.asD_kf  = -0.6;            % departure AS vs k-factor
fixpar.A1.LoS.asA_kf  = -0.6;            % arrival AS vs k-factor
fixpar.A1.LoS.ds_kf   = -0.6;            % delay spread vs k-factor
fixpar.A1.LoS.sf_kf   =  0.4;             % shadowing std vs k-factor

% Polarisation parameters [1, Table 4.5]
fixpar.A1.LoS.xpr_mu    = 11;           % XPR mean [dB]
fixpar.A1.LoS.xpr_sigma = 4;            % XPR std  [dB]

% Dispersion parameters [1, Table 4.5]
% Log-normal distributions
fixpar.A1.LoS.DS_mu      = -7.42;       % delay spread, mean [log10(s)]
fixpar.A1.LoS.DS_sigma   = 0.27;        % delay spread, std [log10(s)]
fixpar.A1.LoS.AS_D_mu    = 1.64;        % arrival angle spread, mean [log10(deg)]
fixpar.A1.LoS.AS_D_sigma = 0.31;        % arrival angle spread, std [log10(deg)]
fixpar.A1.LoS.AS_A_mu    = 1.65;        % departure angle spread, mean [log10(deg)]
fixpar.A1.LoS.AS_A_sigma = 0.26;        % departure angle spread, std [log10(deg)]
fixpar.A1.LoS.SF_sigma   = 3;           % shadowing std [dB] (zero mean)
fixpar.A1.LoS.KF_mu      = 7;           % K-factor mean [dB]
fixpar.A1.LoS.KF_sigma   = 6;           % K-factor std [dB]

% "Decorrelation distances" [1, Table 4.5]
fixpar.A1.LoS.DS_lambda   = 7;          % [m], delay spread
fixpar.A1.LoS.AS_D_lambda = 6;          % [m], departure azimuth spread
fixpar.A1.LoS.AS_A_lambda = 2;          % [m], arrival azimuth spread
fixpar.A1.LoS.SF_lambda   = 6;          % [m], shadowing
fixpar.A1.LoS.KF_lambda   = 6;          % [m], k-factor 

% Path loss PL = Alog10(d) + B + Clog10(fc/5)  [1, Table 4.4]
fixpar.A1.LoS.PL_A     = 18.7;          % path loss exponent
fixpar.A1.LoS.PL_B     = 46.8;          % path loss intercept
fixpar.A1.LoS.PL_C     = 20;            % path loss frequency dependence factor
fixpar.A1.LoS.PL_range = [3 100];       % applicability range [m], (min max)

%% A1, NLOS
% Fixed scenario specific parameters
fixpar.A1.NLoS.NumClusters    = 16;     % Number of ZDSC    [1, Table 4.5]
fixpar.A1.NLoS.r_DS           = 2.4;    % Delays spread proportionality factor
fixpar.A1.NLoS.PerClusterAS_D = 5;      % Per cluster FS angle spread [deg] [1, Table 4.5]
fixpar.A1.NLoS.PerClusterAS_A = 5;      % Per cluster MS angle spread [deg] [1, Table 4.5]
fixpar.A1.NLoS.LNS_ksi        = 3;      % ZDSC LNS ksi [dB], per cluster shadowing [1, Table 4.5]

% Cross correlation coefficients [1, Table 4.5]
fixpar.A1.NLoS.asD_ds  = -0.1;          % departure AS vs delay spread
fixpar.A1.NLoS.asA_ds  =  0.3;          % arrival AS vs delay spread
fixpar.A1.NLoS.asA_sf  = -0.4;          % arrival AS vs shadowing std
fixpar.A1.NLoS.asD_sf  =  0;            % departure AS vs shadowing std
fixpar.A1.NLoS.ds_sf   = -0.5;          % delay spread vs shadowing std
fixpar.A1.NLoS.asD_asA = -0.3;          % departure AS vs arrival AS
fixpar.A1.NLoS.asD_kf  =  0;            % departure AS vs k-factor
fixpar.A1.NLoS.asA_kf  =  0;            % arrival AS vs k-factor
fixpar.A1.NLoS.ds_kf   =  0;            % delay spread vs k-factor
fixpar.A1.NLoS.sf_kf   =  0;            % shadowing std vs k-factor

% Polarisation parameters [1, Table 4.5]
fixpar.A1.NLoS.xpr_mu    = 10;          % XPR mean [dB]
fixpar.A1.NLoS.xpr_sigma = 4;           % XPR std  [dB]

% Dispersion parameters [1, Table 4.5]
% Log-normal distributions
fixpar.A1.NLoS.DS_mu      = -7.6;       % delay spread, mean [log10(s)]
fixpar.A1.NLoS.DS_sigma   = 0.19;       % delay spread, std [log10(s)]
fixpar.A1.NLoS.AS_D_mu    = 1.73;       % arrival angle spread, mean [log10(deg)]
fixpar.A1.NLoS.AS_D_sigma = 0.23;       % arrival angle spread, std [log10(deg)]
fixpar.A1.NLoS.AS_A_mu    = 1.69;       % departure angle spread, mean [log10(deg)]
fixpar.A1.NLoS.AS_A_sigma = 0.14;       % departure angle spread, std [log10(deg)]
fixpar.A1.NLoS.SF_sigma   = 4;          % shadowing std [dB] (zero mean)
fixpar.A1.NLoS.KF_mu      = 0;          % k-factor, dummy value
fixpar.A1.NLoS.KF_sigma   = 0;          % k-factor, dummy value

% "Decorrelation distances" [1, Table 4.5]
fixpar.A1.NLoS.DS_lambda   = 4;         % [m], delay spread
fixpar.A1.NLoS.AS_D_lambda = 5;         % [m], departure azimuth spread
fixpar.A1.NLoS.AS_A_lambda = 3;         % [m], arrival azimuth spread
fixpar.A1.NLoS.SF_lambda   = 4;         % [m], shadowing
fixpar.A1.NLoS.KF_lambda   = 0;         % [m], k-factor 

% Path loss PL = Alog10(d) + B + Clog10(fc/5)  [1, Table 4.4]
fixpar.A1.NLoS.PL_A = [36.8 20 20];     % path loss exponent [RC, RR_light, RR_heavy]
fixpar.A1.NLoS.PL_B = [43.8 46.4 46.4]; % path loss intercept [RC, RR_light, RR_heavy]
fixpar.A1.LoS.PL_C  = 20;               % path loss frequency dependence factor
fixpar.A1.NLoS.PL_X = [5 12];           % path loss wall factor [1, Table 4.4]
fixpar.A1.NLoS.PL_range = [3 100];      % applicability range [m], (min max)

%% A2, NLoS            
% Fixed scenario specific parameters
fixpar.A2.NLoS.NumClusters    = 12;     % Number of ZDSC    [1, Table 4.5]
fixpar.A2.NLoS.r_DS           = 2.2;    % delays spread proportionality factor
fixpar.A2.NLoS.PerClusterAS_D = 8;      % Per cluster FS angle spread [deg] [1, Table 4.5]
fixpar.A2.NLoS.PerClusterAS_A = 5;      % Per cluster MS angle spread [deg] [1, Table 4.5]
fixpar.A2.NLoS.LNS_ksi        = 4;      % ZDSC LNS ksi [dB], per cluster shadowing [1, Table 4.5]

% Cross correlation coefficients [1, Table 4.5]
fixpar.A2.NLoS.asD_ds  = 0.4;           % departure AS vs delay spread
fixpar.A2.NLoS.asA_ds  = 0.4;           % arrival AS vs delay spread
fixpar.A2.NLoS.asA_sf  = 0.2;           % arrival AS vs shadowing std
fixpar.A2.NLoS.asD_sf  = 0;             % departure AS vs shadowing std
fixpar.A2.NLoS.ds_sf   = -0.5;          % delay spread vs shadowing std
fixpar.A2.NLoS.asD_asA = 0;             % departure AS vs arrival AS
fixpar.A2.NLoS.asD_kf  = 0;             % departure AS vs k-factor
fixpar.A2.NLoS.asA_kf  = 0;             % arrival AS vs k-factor
fixpar.A2.NLoS.ds_kf   = 0;             % delay spread vs k-factor
fixpar.A2.NLoS.sf_kf   = 0;             % shadowing std vs k-factor

% Polarisation parameters [1, Table 4.5]
fixpar.A2.NLoS.xpr_mu    = 9;           % XPR mean [dB]
fixpar.A2.NLoS.xpr_sigma = 11;          % XPR std  [dB]

% Dispersion parameters [1, Table 4.5]
% Log-normal distributions
fixpar.A2.NLoS.DS_mu      = -7.39;      % delay spread, mean [log10(s)]
fixpar.A2.NLoS.DS_sigma   = 0.36;       % delay spread, std [log10(s)]
fixpar.A2.NLoS.AS_D_mu    = 1.76;       % arrival angle spread, mean [log10(deg)]
fixpar.A2.NLoS.AS_D_sigma = 0.16;       % arrival angle spread, std [log10(deg)]
fixpar.A2.NLoS.AS_A_mu    = 1.25;       % departure angle spread, mean [log10(deg)]
fixpar.A2.NLoS.AS_A_sigma = 0.42;       % departure angle spread, std [log10(deg)]
fixpar.A2.NLoS.SF_sigma   = 7;          % shadowing std [dB] (zero mean)
fixpar.A2.NLoS.KF_mu      = 0;          % k-factor, dummy value
fixpar.A2.NLoS.KF_sigma   = 0;          % k-factor, dummy value

% "Decorrelation distances" [1, Table 4.5]
fixpar.A2.NLoS.DS_lambda   = 21;        % [m], delay spread
fixpar.A2.NLoS.AS_D_lambda = 15;        % [m], departure azimuth spread
fixpar.A2.NLoS.AS_A_lambda = 35;        % [m], arrival azimuth spread
fixpar.A2.NLoS.SF_lambda   = 14;        % [m], shadowing
fixpar.A2.NLoS.KF_lambda   = 0;         % dummy value

% Path loss, Note! see the path loss equation...
fixpar.A2.NLoS.PL_A     = NaN;          % path loss exponent 
fixpar.A2.NLoS.PL_B     = NaN;          % path loss intercept
fixpar.A2.LoS.PL_C      = 20;           % path loss frequency dependence factor
fixpar.A2.NLoS.PL_range = [3 1000];     % applicability range [m], (min max)

%% B1, LoS
% Fixed scenario specific parameters
fixpar.B1.LoS.NumClusters    = 8;       % Number of ZDSC    [1, Table 4.5]
fixpar.B1.LoS.r_DS           = 3.2;     % delays spread proportionality factor
fixpar.B1.LoS.PerClusterAS_D = 3;       % Per cluster FS angle spread [deg] [1, Table 4.5]
fixpar.B1.LoS.PerClusterAS_A = 18;      % Per cluster MS angle spread [deg] [1, Table 4.5]
fixpar.B1.LoS.LNS_ksi        = 3;       % ZDSC LNS ksi [dB], per cluster shadowing [1, Table 4.5]

% Cross correlation coefficients [1, Table 4.5]
fixpar.B1.LoS.asD_ds  =  0.5;           % departure AS vs delay spread
fixpar.B1.LoS.asA_ds  =  0.8;           % arrival AS vs delay spread
fixpar.B1.LoS.asA_sf  = -0.5;           % arrival AS vs shadowing std
fixpar.B1.LoS.asD_sf  = -0.5;           % departure AS vs shadowing std
fixpar.B1.LoS.ds_sf   = -0.4;           % delay spread vs shadowing std
fixpar.B1.LoS.asD_asA =  0.4;           % departure AS vs arrival AS
fixpar.B1.LoS.asD_kf  = -0.3;           % departure AS vs k-factor
fixpar.B1.LoS.asA_kf  = -0.3;           % arrival AS vs k-factor
fixpar.B1.LoS.ds_kf   = -0.7;           % delay spread vs k-factor
fixpar.B1.LoS.sf_kf   =  0.5;           % shadowing std vs k-factor

% Polarisation parameters [1, Table 4.5]
fixpar.B1.LoS.xpr_mu    = 9;            % XPR mean [dB]
fixpar.B1.LoS.xpr_sigma = 3;            % XPR std  [dB]

% Dispersion parameters [1, Table 4.5]
fixpar.B1.LoS.DS_mu      = -7.44;       % delay spread, mean [log10(s)]
fixpar.B1.LoS.DS_sigma   = 0.25;        % delay spread, std [log10(s)]
fixpar.B1.LoS.AS_D_mu    = 0.40;        % arrival angle spread, mean [log10(deg)]
fixpar.B1.LoS.AS_D_sigma = 0.37;        % arrival angle spread, std [log10(deg)]
fixpar.B1.LoS.AS_A_mu    = 1.40;        % departure angle spread, mean [log10(deg)]
fixpar.B1.LoS.AS_A_sigma = 0.20;        % departure angle spread, std [log10(deg)]
fixpar.B1.LoS.SF_sigma   = 3;           % shadowing std [dB] (zero mean)
fixpar.B1.LoS.KF_mu      = 9;           % K-factor mean [dB]
fixpar.B1.LoS.KF_sigma   = 6;           % K-factor std [dB]

% Decorrelation distances: lambda parameters [1, Table 4.5]
fixpar.B1.LoS.DS_lambda   = 9;          % [m], delay spread
fixpar.B1.LoS.AS_D_lambda = 13;         % [m], departure azimuth spread
fixpar.B1.LoS.AS_A_lambda = 12;         % [m], arrival azimuth spread
fixpar.B1.LoS.SF_lambda   = 14;         % [m], shadowing
fixpar.B1.LoS.KF_lambda   = 10;         % [m], k-factor 

% Path loss PL = Alog10(d) + B + Clog10(fc/5)  [1, Table 4.4]
fixpar.B1.LoS.PL_A = [22.7 40.0];       % path loss exponent, [d<d_bp d>d_bp]
fixpar.B1.LoS.PL_B = [41.0 9.45];       % path loss intercept, [d<d_bp d>d_bp]
fixpar.B1.LoS.PL_C = 20;                % path loss frequency dependence factor
fixpar.B1.LoS.PL_range = [StreetWidth 5000]; % applicability range [m], (min max)

%% B1, NLoS
% Fixed scenario specific parameters
fixpar.B1.NLoS.NumClusters = 16;        % Number of ZDSC    [1, Table 4.5]
fixpar.B1.NLoS.r_DS   = 1;              % delays spread proportionality factor
fixpar.B1.NLoS.PerClusterAS_D = 10;     % Per cluster FS angle spread [deg] [1, Table 4.5]
fixpar.B1.NLoS.PerClusterAS_A = 22;     % Per cluster MS angle spread [deg] [1, Table 4.5]
fixpar.B1.NLoS.LNS_ksi = 3;             % ZDSC LNS ksi [dB], per cluster shadowing [1, Table 4.5]

% Cross correlation coefficients [1, Table 4.5]
fixpar.B1.NLoS.asD_ds =  0.2;           % departure AS vs delay spread
fixpar.B1.NLoS.asA_ds =  0.4;           % arrival AS vs delay spread
fixpar.B1.NLoS.asA_sf = -0.4;           % arrival AS vs shadowing std
fixpar.B1.NLoS.asD_sf =  0;             % departure AS vs shadowing std
fixpar.B1.NLoS.ds_sf  = -0.7;           % delay spread vs shadowing std
fixpar.B1.NLoS.asD_asA = 0.1;           % departure AS vs arrival AS
fixpar.B1.NLoS.asD_kf = 0;              % departure AS vs k-factor
fixpar.B1.NLoS.asA_kf = 0;              % arrival AS vs k-factor
fixpar.B1.NLoS.ds_kf = 0;               % delay spread vs k-factor
fixpar.B1.NLoS.sf_kf = 0;               % shadowing std vs k-factor

% Polarisation parameters [1, Table 4.5]
fixpar.B1.NLoS.xpr_mu    = 8;           % XPR mean [dB]
fixpar.B1.NLoS.xpr_sigma = 3;           % XPR std  [dB]

% Dispersion parameters [1, Table 4.5]
% Log-normal distributions
fixpar.B1.NLoS.DS_mu      = -7.12;      % delay spread, mean [log10(s)]
fixpar.B1.NLoS.DS_sigma   = 0.12;       % delay spread, std [log10(s)]
fixpar.B1.NLoS.AS_D_mu    = 1.19;       % arrival angle spread, mean [log10(deg)]
fixpar.B1.NLoS.AS_D_sigma = 0.21;       % arrival angle spread, std [log10(deg)]
fixpar.B1.NLoS.AS_A_mu    = 1.55;       % departure angle spread, mean [log10(deg)]
fixpar.B1.NLoS.AS_A_sigma = 0.20;       % departure angle spread, std [log10(deg)]
fixpar.B1.NLoS.SF_sigma   = 4;          % shadowing std [dB] (zero mean)
fixpar.B1.NLoS.KF_mu      = 0;          % k-factor, dummy value
fixpar.B1.NLoS.KF_sigma   = 0;          % k-factor, dummy value

% Decorrelation distances: lambda parameters [1, Table 4.5]
fixpar.B1.NLoS.DS_lambda   = 8;         % [m], delay spread
fixpar.B1.NLoS.AS_D_lambda = 10;        % [m], departure azimuth spread
fixpar.B1.NLoS.AS_A_lambda = 9;         % [m], arrival azimuth spread
fixpar.B1.NLoS.SF_lambda   = 12;        % [m], shadowing
fixpar.B1.NLoS.KF_lambda   = 0;         % [m], k-factor 

% Path loss, Note! see the path loss equation...
fixpar.B1.NLoS.PL_A = [22.7 40.0];       % path loss exponent, [d<d_bp d>d_bp]
fixpar.B1.NLoS.PL_B = [41.0 9.45];       % path loss intercept, [d<d_bp d>d_bp]
fixpar.B1.NLoS.PL_range = [StreetWidth 5000];  % applicability range [m], (min max)

%% B2, NLoS, same as B1 NLoS
% Fixed scenario specific parameters
fixpar.B2.NLoS.NumClusters = 16;        % Number of ZDSC    [1, Table 4.5]
fixpar.B2.NLoS.r_DS   = 1;              % delays spread proportionality factor
fixpar.B2.NLoS.PerClusterAS_D = 10;     % Per cluster FS angle spread [deg] [1, Table 4.5]
fixpar.B2.NLoS.PerClusterAS_A = 22;     % Per cluster MS angle spread [deg] [1, Table 4.5]
fixpar.B2.NLoS.LNS_ksi = 3;             % ZDSC LNS ksi [dB], per cluster shadowing [1, Table 4.5]

% Cross correlation coefficients [1, Table 4.5]
fixpar.B2.NLoS.asD_ds =  0.2;           % departure AS vs delay spread
fixpar.B2.NLoS.asA_ds =  0.4;           % arrival AS vs delay spread
fixpar.B2.NLoS.asA_sf = -0.4;           % arrival AS vs shadowing std
fixpar.B2.NLoS.asD_sf =  0;             % departure AS vs shadowing std
fixpar.B2.NLoS.ds_sf  = -0.7;           % delay spread vs shadowing std
fixpar.B2.NLoS.asD_asA = 0.1;           % departure AS vs arrival AS
fixpar.B2.NLoS.asD_kf = 0;              % departure AS vs k-factor
fixpar.B2.NLoS.asA_kf = 0;              % arrival AS vs k-factor
fixpar.B2.NLoS.ds_kf = 0;               % delay spread vs k-factor
fixpar.B2.NLoS.sf_kf = 0;               % shadowing std vs k-factor

% Polarisation parameters [1, Table 4.5]
fixpar.B2.NLoS.xpr_mu    = 8;           % XPR mean [dB]
fixpar.B2.NLoS.xpr_sigma = 3;           % XPR std  [dB]

% Dispersion parameters [1, Table 4.5]
% Log-normal distributions
fixpar.B2.NLoS.DS_mu      = -7.12;      % delay spread, mean [log10(s)]
fixpar.B2.NLoS.DS_sigma   = 0.12;       % delay spread, std [log10(s)]
fixpar.B2.NLoS.AS_D_mu    = 1.19;       % arrival angle spread, mean [log10(deg)]
fixpar.B2.NLoS.AS_D_sigma = 0.21;       % arrival angle spread, std [log10(deg)]
fixpar.B2.NLoS.AS_A_mu    = 1.55;       % departure angle spread, mean [log10(deg)]
fixpar.B2.NLoS.AS_A_sigma = 0.20;       % departure angle spread, std [log10(deg)]
fixpar.B2.NLoS.SF_sigma   = 4;          % shadowing std [dB] (zero mean)
fixpar.B2.NLoS.KF_mu      = 0;          % k-factor, dummy value
fixpar.B2.NLoS.KF_sigma   = 0;          % k-factor, dummy value

% Decorrelation distances: lambda parameters [1, Table 4.5]
fixpar.B2.NLoS.DS_lambda   = 8;         % [m], delay spread
fixpar.B2.NLoS.AS_D_lambda = 10;        % [m], departure azimuth spread
fixpar.B2.NLoS.AS_A_lambda = 9;         % [m], arrival azimuth spread
fixpar.B2.NLoS.SF_lambda   = 12;        % [m], shadowing
fixpar.B2.NLoS.KF_lambda   = 0;         % [m], k-factor 

% Path loss, Note! see the path loss equation...
fixpar.B2.NLoS.PL_A = [22.7 40.0];       % path loss exponent, [d<d_bp d>d_bp]
fixpar.B2.NLoS.PL_B = [41.0 9.45];       % path loss intercept, [d<d_bp d>d_bp]
fixpar.B2.NLoS.PL_range = [StreetWidth 5000];  % applicability range [m], (min max)

%% B3, LoS
% Fixed scenario specific parameters
fixpar.B3.LoS.NumClusters = 10;         % Number of ZDSC    [1, Table 4.5]
fixpar.B3.LoS.r_DS   = 1.9;             % delays spread proportionality factor
fixpar.B3.LoS.PerClusterAS_D = 5;       % Per cluster FS angle spread [deg] [1, Table 4.5]
fixpar.B3.LoS.PerClusterAS_A = 5;       % Per cluster MS angle spread [deg] [1, Table 4.5]
fixpar.B3.LoS.LNS_ksi = 3;              % ZDSC LNS ksi [dB], per cluster shadowing [1, Table 4.5]

% Cross correlation coefficients [1, Table 4.5]
fixpar.B3.LoS.asD_ds = -0.3;            % departure AS vs delay spread
fixpar.B3.LoS.asA_ds = -0.4;            % arrival AS vs delay spread
fixpar.B3.LoS.asA_sf = -0.2;            % arrival AS vs shadowing std
fixpar.B3.LoS.asD_sf =  0.3;            % departure AS vs shadowing std
fixpar.B3.LoS.ds_sf  = -0.1;            % delay spread vs shadowing std
fixpar.B3.LoS.asD_asA = 0.3;            % departure AS vs arrival AS
fixpar.B3.LoS.asD_kf =  0.2;            % departure AS vs k-factor
fixpar.B3.LoS.asA_kf = -0.1;            % arrival AS vs k-factor
fixpar.B3.LoS.ds_kf =  -0.3;            % delay spread vs k-factor
fixpar.B3.LoS.sf_kf =   0.6;            % shadowing std vs k-factor

% Polarisation parameters [1, Table 4.5]
fixpar.B3.LoS.xpr_mu    = 9;            % XPR mean [dB]
fixpar.B3.LoS.xpr_sigma = 4;            % XPR std  [dB]

% Dispersion parameters [1, Table 4.5]
% Log-normal distributions
fixpar.B3.LoS.DS_mu      = -7.53;       % delay spread, mean [log10(s)]
fixpar.B3.LoS.DS_sigma   = 0.12;        % delay spread, std [log10(s)]
fixpar.B3.LoS.AS_D_mu    = 1.22;        % arrival angle spread, mean [log10(deg)]
fixpar.B3.LoS.AS_D_sigma = 0.18;        % arrival angle spread, std [log10(deg)]
fixpar.B3.LoS.AS_A_mu    = 1.58;        % departure angle spread, mean [log10(deg)]
fixpar.B3.LoS.AS_A_sigma = 0.23;        % departure angle spread, std [log10(deg)]
fixpar.B3.LoS.SF_sigma   = 3;           % shadowing std [dB] (zero mean)
fixpar.B3.LoS.KF_mu = 2;                % K-factor mean [dB]
fixpar.B3.LoS.KF_sigma = 3;             % K-factor std [dB]

% Decorrelation distances: lambda parameters [1, Table 4.5]
fixpar.B3.LoS.DS_lambda   = 3;          % [m], delay spread
fixpar.B3.LoS.AS_D_lambda = 1;          % [m], departure azimuth spread
fixpar.B3.LoS.AS_A_lambda = 2;          % [m], arrival azimuth spread
fixpar.B3.LoS.SF_lambda   = 3;          % [m], shadowing
fixpar.B3.LoS.KF_lambda   = 1;          % [m], k-factor 

% Path loss PL = Alog10(d) + B + Clog10(fc/5)  [1, Table 4.4]
fixpar.B3.LoS.PL_A = 13.9;              % path loss exponent
fixpar.B3.LoS.PL_B = 64.4;              % path loss intercept
fixpar.B3.LoS.PL_C = 20;                % path loss frequency dependence factor
fixpar.B3.LoS.PL_range = [5 100];       % applicability range [m], (min max)

%% B3, NLoS
% Fixed scenario specific parameters
fixpar.B3.NLoS.NumClusters = 15;        % Number of ZDSC    [1, Table 4.5]
fixpar.B3.NLoS.r_DS   = 1.6;            % delays spread proportionality factor
fixpar.B3.NLoS.PerClusterAS_D = 6;      % Per cluster FS angle spread [deg] [1, Table 4.5]
fixpar.B3.NLoS.PerClusterAS_A = 13;     % Per cluster MS angle spread [deg] [1, Table 4.5]
fixpar.B3.NLoS.LNS_ksi = 3;             % ZDSC LNS ksi [dB], per cluster shadowing [1, Table 4.5]

% Cross correlation coefficients [1, Table 4.5]
fixpar.B3.NLoS.asD_ds = -0.1;           % departure AS vs delay spread
fixpar.B3.NLoS.asA_ds = 0;              % arrival AS vs delay spread
fixpar.B3.NLoS.asA_sf = 0.2;            % arrival AS vs shadowing std
fixpar.B3.NLoS.asD_sf = -0.3;           % departure AS vs shadowing std
fixpar.B3.NLoS.ds_sf  = -0.2;           % delay spread vs shadowing std
fixpar.B3.NLoS.asD_asA = -0.3;          % departure AS vs arrival AS
fixpar.B3.NLoS.asD_kf = 0;              % departure AS vs k-factor
fixpar.B3.NLoS.asA_kf = 0;              % arrival AS vs k-factor
fixpar.B3.NLoS.ds_kf = 0;               % delay spread vs k-factor
fixpar.B3.NLoS.sf_kf = 0;               % shadowing std vs k-factor

% Polarisation parameters [1, Table 4.5]
fixpar.B3.NLoS.xpr_mu    = 6;           % XPR mean [dB]
fixpar.B3.NLoS.xpr_sigma = 3;           % XPR std  [dB]

% Log-normal distributions
fixpar.B3.NLoS.DS_mu      = -7.41;      % delay spread, mean [log10(s)]
fixpar.B3.NLoS.DS_sigma   = 0.13;       % delay spread, std [log10(s)]
fixpar.B3.NLoS.AS_D_mu    = 1.05;       % arrival angle spread, mean [log10(deg)]
fixpar.B3.NLoS.AS_D_sigma = 0.22;       % arrival angle spread, std [log10(deg)]
fixpar.B3.NLoS.AS_A_mu    = 1.7;        % departure angle spread, mean [log10(deg)]
fixpar.B3.NLoS.AS_A_sigma = 0.1;        % departure angle spread, std [log10(deg)]
fixpar.B3.NLoS.SF_sigma   = 4;          % shadowing std [dB] (zero mean)
fixpar.B3.NLoS.KF_mu      = 0;          % k-factor, dummy value
fixpar.B3.NLoS.KF_sigma   = 0;          % k-factor, dummy value

% Decorrelation distances: lambda parameters [1, Table 4.5]
fixpar.B3.NLoS.DS_lambda   = 1;         % [m], delay spread
fixpar.B3.NLoS.AS_D_lambda = 0.5;       % [m], departure azimuth spread
fixpar.B3.NLoS.AS_A_lambda = 0.5;       % [m], arrival azimuth spread
fixpar.B3.NLoS.SF_lambda   = 3;         % [m], shadowing
fixpar.B3.NLoS.KF_lambda   = 0;         % [m], k-factor 

% Path loss PL = Alog10(d) + B + Clog10(fc/5)  [1, Table 4.4]
fixpar.B3.NLoS.PL_A = 37.8;             % path loss exponent
fixpar.B3.NLoS.PL_B = 36.5;             % path loss intercept
fixpar.B3.NLoS.PL_C = 23;               % path loss frequency dependence factor
fixpar.B3.NLoS.PL_range = [5 100];      % applicability range [m], (min max)

%% B4, NLoS
% Fixed scenario specific parameters
fixpar.B4.NLoS.NumClusters = 12;        % Number of ZDSC    [1, Table 4.5]
fixpar.B4.NLoS.r_DS   = 2.2;           % delays spread proportionality factor
fixpar.B4.NLoS.PerClusterAS_D = 8;      % Per cluster FS angle spread [deg] [1, Table 4.5]
fixpar.B4.NLoS.PerClusterAS_A = 5;      % Per cluster MS angle spread [deg] [1, Table 4.5]
fixpar.B4.NLoS.LNS_ksi = 4;             % ZDSC LNS ksi [dB], per cluster shadowing [1, Table 4.5]

% Cross correlation coefficients [1, Table 4.5]
fixpar.B4.NLoS.asD_ds = 0.4;            % departure AS vs delay spread
fixpar.B4.NLoS.asA_ds = 0.4;            % arrival AS vs delay spread
fixpar.B4.NLoS.asA_sf = 0.2;            % arrival AS vs shadowing std
fixpar.B4.NLoS.asD_sf = 0;              % departure AS vs shadowing std
fixpar.B4.NLoS.ds_sf  = -0.5;           % delay spread vs shadowing std
fixpar.B4.NLoS.asD_asA = 0;             % departure AS vs arrival AS
fixpar.B4.NLoS.asD_kf = 0;              % departure AS vs k-factor
fixpar.B4.NLoS.asA_kf = 0;              % arrival AS vs k-factor
fixpar.B4.NLoS.ds_kf = 0;               % delay spread vs k-factor
fixpar.B4.NLoS.sf_kf = 0;               % shadowing std vs k-factor

% Polarisation parameters [1, Table 4.5]
fixpar.B4.NLoS.xpr_mu    = 9;           % XPR mean [dB]
fixpar.B4.NLoS.xpr_sigma = 11;          % XPR std  [dB]

% Dispersion parameters [1, Table 4.5]
% Log-normal distributions
fixpar.B4.NLoS.DS_mu      = -7.39;      % delay spread, mean [log10(s)]
fixpar.B4.NLoS.DS_sigma   = 0.36;       % delay spread, std [log10(s)]
fixpar.B4.NLoS.AS_D_mu    = 1.76;       % arrival angle spread, mean [log10(deg)]
fixpar.B4.NLoS.AS_D_sigma = 0.16;       % arrival angle spread, std [log10(deg)]
fixpar.B4.NLoS.AS_A_mu    = 1.25;       % departure angle spread, mean [log10(deg)]
fixpar.B4.NLoS.AS_A_sigma = 0.42;       % departure angle spread, std [log10(deg)]
fixpar.B4.NLoS.SF_sigma   = 7;          % shadowing std [dB] (zero mean)
fixpar.B4.NLoS.KF_mu      = 0;          % k-factor, dummy value
fixpar.B4.NLoS.KF_sigma   = 0;          % k-factor, dummy value

% "Decorrelation distances" [1, Table 4.5]
fixpar.B4.NLoS.DS_lambda   = 11;        % [m], delay spread
fixpar.B4.NLoS.AS_D_lambda = 17;        % [m], departure azimuth spread
fixpar.B4.NLoS.AS_A_lambda = 7;         % [m], arrival azimuth spread
fixpar.B4.NLoS.SF_lambda   = 14;        % [m], shadowing
fixpar.B4.NLoS.KF_lambda   = 0;         % [m], k-factor 

% Path loss, Note! see the path loss equation...
fixpar.B4.NLoS.PL_A = NaN;     % path loss exponent 
fixpar.B4.NLoS.PL_B = NaN; % path loss intercept
fixpar.B4.LoS.PL_C = 20;                % path loss frequency dependence factor
fixpar.B4.NLoS.PL_range = [3 1000];     % applicability range [m], (min max)

%% B5 a,b,c,f 
% Stationary feeder. Dummy values, never used
% Fixed scenario specific parameters
fixpar.B5.NumClusters = 0;      % Number of ZDSC
fixpar.B5.LoS.r_DS   = 0;       % delays spread proportionality factor
fixpar.B5.PerClusterAS_D = 0;   % Per cluster FS angle spread [deg]
fixpar.B5.PerClusterAS_A = 0;   % Per cluster MS angle spread [deg] 
fixpar.B5.LNS_ksi = 0;          % ZDSC LNS ksi [dB], per cluster shadowing

% Cross correlation coefficients
fixpar.B5.asD_ds = 0;           % departure AS vs delay spread
fixpar.B5.asA_ds = 0;           % arrival AS vs delay spread
fixpar.B5.asA_sf = 0;           % arrival AS vs shadowing std
fixpar.B5.asD_sf = 0;           % departure AS vs shadowing std
fixpar.B5.ds_sf  = 0;           % delay spread vs shadowing std
fixpar.B5.asD_asA = 0;          % departure AS vs arrival AS
fixpar.B5.asD_kf = 0;              % departure AS vs k-factor
fixpar.B5.asA_kf = 0;              % arrival AS vs k-factor
fixpar.B5.ds_kf = 0;               % delay spread vs k-factor
fixpar.B5.sf_kf = 0;               % shadowing std vs k-factor

% Polarisation parameters
fixpar.B5.xpr_mu    = 0;        % XPR mean [dB]
fixpar.B5.xpr_sigma = 0;        % XPR std  [dB]

% Dispersion parameters
% Log-normal distributions
fixpar.B5.DS_mu      = 0;       % delay spread, mean [log10(s)]
fixpar.B5.DS_sigma   = 0;       % delay spread, std [log10(s)]
fixpar.B5.AS_D_mu    = 0;       % arrival angle spread, mean [log10(deg)]
fixpar.B5.AS_D_sigma = 0;       % arrival angle spread, std [log10(deg)]
fixpar.B5.AS_A_mu    = 0;       % departure angle spread, mean [log10(deg)]
fixpar.B5.AS_A_sigma = 0;       % departure angle spread, std [log10(deg)]
fixpar.B5.SF_sigma   = 6;       % shadowing std [dB] (zero mean)
fixpar.B5.KF_mu      = 0;          % k-factor, dummy value
fixpar.B5.KF_sigma   = 0;          % k-factor, dummy value

% Decorrelation distances: lambda parameters [1, Table 3.4]
fixpar.B5.DS_lambda   = 0;      % [m], delay spread
fixpar.B5.AS_D_lambda = 0;      % [m], departure azimuth spread
fixpar.B5.AS_A_lambda = 0;      % [m], arrival azimuth spread
fixpar.B5.SF_lambda   = 0;      % [m], shadowing
fixpar.B5.KF_lambda   = 0;      % [m], k-factor 

fixpar.B5a = fixpar.B5;
fixpar.B5c = fixpar.B5;
fixpar.B5f = fixpar.B5;

% Path loss PL = Alog10(d) + B + Clog10(fc/5)  [1, Table 4.4]
fixpar.B5a.PL_A = 23.5;             % path loss exponent [dB], [d<d_bp d>d_bp]
fixpar.B5a.PL_B = 42.5;             % path loss intercept [dB], [d<d_bp d>d_bp] 
fixpar.B5a.PL_C = 20;               % path loss frequency dependence factor
fixpar.B5a.PL_range = [30 8000];    % applicability range [m]

fixpar.B5c.PL_A = [22.7 40.0];      % path loss exponent [dB], [d<d_bp d>d_bp]
fixpar.B5c.PL_B = [41.0 9.45];      % path loss intercept [dB], [d<d_bp d>d_bp]
fixpar.B5c.PL_C = 20;               % path loss frequency dependence factor
fixpar.B5c.PL_range = [10 2000];    % applicability range [m]

fixpar.B5f.PL_A = 23.5;             % path loss exponent [dB], [d<d_bp d>d_bp]
fixpar.B5f.PL_B = 57.5;             % path loss intercept [dB], [d<d_bp d>d_bp]
fixpar.B5f.PL_C = 23;               % path loss frequency dependence factor
fixpar.B5f.PL_range = [30 1500];    % applicability range [m]

%% C1, LoS
% Fixed scenario specific parameters [1, Table 4.5]
fixpar.C1.LoS.NumClusters = 15;     % Number of ZDSC
fixpar.C1.LoS.r_DS   = 2.4;         % delays spread proportionality factor
fixpar.C1.LoS.PerClusterAS_D = 5;   % Per cluster FS angle spread [deg]
fixpar.C1.LoS.PerClusterAS_A = 5;   % Per cluster MS angle spread [deg]
fixpar.C1.LoS.LNS_ksi = 3;          % ZDSC LNS ksi [dB], per cluster shadowing

% Cross correlation coefficients
fixpar.C1.LoS.asD_ds = 0.2;         % departure AS vs delay spread
fixpar.C1.LoS.asA_ds = 0.8;         % arrival AS vs delay spread
fixpar.C1.LoS.asA_sf = -0.5;        % arrival AS vs shadowing std
fixpar.C1.LoS.asD_sf = -0.5;        % departure AS vs shadowing std
fixpar.C1.LoS.ds_sf  = -0.6;        % delay spread vs shadowing std
fixpar.C1.LoS.asD_asA = 0.1;        % departure AS vs arrival AS
fixpar.C1.LoS.asD_kf = 0.2;         % departure AS vs k-factor
fixpar.C1.LoS.asA_kf = -0.2;        % arrival AS vs k-factor
fixpar.C1.LoS.ds_kf = -0.2;         % delay spread vs k-factor
fixpar.C1.LoS.sf_kf = 0;            % shadowing std vs k-factor

% Polarisation parameters [1, Table 4.5]
fixpar.C1.LoS.xpr_mu    = 8;        % XPR mean [dB]
fixpar.C1.LoS.xpr_sigma = 4;        % XPR std  [dB]

% Dispersion parameters [1, Table 4.5]
% Log-normal distributions
fixpar.C1.LoS.DS_mu      = -7.23;    % delay spread, mean [s-dB]
fixpar.C1.LoS.DS_sigma   = 0.49;     % delay spread, std [s-dB]
fixpar.C1.LoS.AS_D_mu    = 0.78;     % arrival angle spread, mean [deg-dB]
fixpar.C1.LoS.AS_D_sigma = 0.12;     % arrival angle spread, std [deg-dB]
fixpar.C1.LoS.AS_A_mu    = 1.48;     % departure angle spread, mean [deg-dB]
fixpar.C1.LoS.AS_A_sigma = 0.20;     % departure angle spread, std [deg-dB]
fixpar.C1.LoS.SF_sigma   = 4;        % shadowing std [dB] (zero mean)
fixpar.C1.LoS.KF_mu = 9;             % K-factor mean [dB]
fixpar.C1.LoS.KF_sigma = 7;          % K-factor std [dB]

% Decorrelation distances: lambda parameters [1, Table 4.5]
fixpar.C1.LoS.DS_lambda   = 6;      % [m], delay spread
fixpar.C1.LoS.AS_D_lambda = 15;     % [m], departure azimuth spread
fixpar.C1.LoS.AS_A_lambda = 20;     % [m], arrival azimuth spread
fixpar.C1.LoS.SF_lambda   = 40;     % [m], shadowing
fixpar.C1.LoS.KF_lambda = 10;       % [m], k-factor

% Path loss PL = Alog10(d) + B + Clog10(fc/5) (30m<d<dBP) [1, Table 4.4]
fixpar.C1.LoS.PL_A = [23.8 40.0];     % path loss exponent [dB], [d<d_bp d>d_bp]
fixpar.C1.LoS.PL_B = [41.2 11.65];    % path loss intercept [dB], [d<d_bp d>d_bp]
fixpar.C1.LoS.PL_C = [20 3.8];        % path loss frequency dependence factor [dB], [d<d_bp d>d_bp]
fixpar.C1.LoS.PL_range = [30 5000];   % applicability range [m]

%% C1, NLoS
% Fixed scenario specific parameters
fixpar.C1.NLoS.NumClusters = 14;       % Number of ZDSC    [1, Table 4.5]
fixpar.C1.NLoS.r_DS   = 1.5;           % delays spread proportionality factor [1, Table 4.5]
fixpar.C1.NLoS.PerClusterAS_D = 2;     % Per cluster FS angle spread [deg] [1, Table 4.5]
fixpar.C1.NLoS.PerClusterAS_A = 10;    % Per cluster MS angle spread [deg] [1, Table 4.5]
fixpar.C1.NLoS.LNS_ksi = 3;            % ZDSC LNS ksi [dB], per cluster shadowing [1, Table 4.5]

% Cross correlation coefficients [1, Table 4.5]
fixpar.C1.NLoS.asD_ds = 0.3;           % departure AS vs delay spread
fixpar.C1.NLoS.asA_ds = 0.7;           % arrival AS vs delay spread
fixpar.C1.NLoS.asA_sf = -0.3;          % arrival AS vs shadowing std
fixpar.C1.NLoS.asD_sf = -0.4;          % departure AS vs shadowing std
fixpar.C1.NLoS.ds_sf  = -0.4;          % delay spread vs shadowing std
fixpar.C1.NLoS.asD_asA = 0.3;          % departure AS vs arrival AS
fixpar.C1.NLoS.asD_kf = 0;              % departure AS vs k-factor
fixpar.C1.NLoS.asA_kf = 0;              % arrival AS vs k-factor
fixpar.C1.NLoS.ds_kf = 0;               % delay spread vs k-factor
fixpar.C1.NLoS.sf_kf = 0;               % shadowing std vs k-factor

% Polarisation parameters [1, Table 4.5]
fixpar.C1.NLoS.xpr_mu    = 4;          % XPR mean [dB]
fixpar.C1.NLoS.xpr_sigma = 3;          % XPR std  [dB]

% Dispersion parameters [1, Table 4.5]
% Log-normal distributions
fixpar.C1.NLoS.DS_mu      = -7.12;      % delay spread, mean [log10(s)]
fixpar.C1.NLoS.DS_sigma   = 0.33;       % delay spread, std [log10(s)]
fixpar.C1.NLoS.AS_D_mu    = 0.90;       % arrival angle spread, mean [log10(deg)]
fixpar.C1.NLoS.AS_D_sigma = 0.36;       % arrival angle spread, std [log10(deg)]
fixpar.C1.NLoS.AS_A_mu    = 1.65;       % departure angle spread, mean [log10(deg)]
fixpar.C1.NLoS.AS_A_sigma = 0.30;       % departure angle spread, std [log10(deg)]
fixpar.C1.NLoS.SF_sigma   = 8;          % shadowing std [dB] (zero mean)
fixpar.C1.NLoS.KF_mu      = 0;          % k-factor, dummy value
fixpar.C1.NLoS.KF_sigma   = 0;          % k-factor, dummy value

% Decorrelation distances: lambda parameters [1, Table 4.5]
fixpar.C1.NLoS.DS_lambda   = 40;      % [m], delay spread
fixpar.C1.NLoS.AS_D_lambda = 30;      % [m], departure azimuth spread
fixpar.C1.NLoS.AS_A_lambda = 30;      % [m], arrival azimuth spread
fixpar.C1.NLoS.SF_lambda   = 50;      % [m], shadowing
fixpar.C1.NLoS.KF_lambda   = 0;       % [m], k-factor 

% Path loss, Note! see the path loss equation...
fixpar.C1.NLoS.PL_A = NaN;       % path loss exponent, [d<d_bp d>d_bp]
fixpar.C1.NLoS.PL_B = NaN;       % path loss intercept, [d<d_bp d>d_bp]
fixpar.C1.NLoS.PL_C = 23;        % path loss frequency dependence factor [dB]
fixpar.C1.NLoS.PL_range = [50 5000];  % applicability range [m], (min max)

%% C2, LoS    
% Fixed scenario specific parameters [1, Table 4.5]
fixpar.C2.LoS.NumClusters = 8;       % Number of ZDSC
fixpar.C2.LoS.r_DS   = 2.5;           % delays spread proportionality factor
fixpar.C2.LoS.PerClusterAS_D = 6;     % Per cluster FS angle spread [deg]
fixpar.C2.LoS.PerClusterAS_A = 12;    % Per cluster MS angle spread [deg]
fixpar.C2.LoS.LNS_ksi = 3;            % ZDSC LNS ksi [dB], per cluster shadowing

% Cross correlation coefficients [1, Table 4.5]
fixpar.C2.LoS.asD_ds = 0.4;           % departure AS vs delay spread
fixpar.C2.LoS.asA_ds = 0.8;           % arrival AS vs delay spread
fixpar.C2.LoS.asA_sf = -0.5;          % arrival AS vs shadowing std
fixpar.C2.LoS.asD_sf = -0.5;          % departure AS vs shadowing std
fixpar.C2.LoS.ds_sf  = -0.4;          % delay spread vs shadowing std
fixpar.C2.LoS.asD_asA = 0.3;          % departure AS vs arrival AS
fixpar.C2.LoS.asD_kf = 0.1;           % departure AS vs k-factor
fixpar.C2.LoS.asA_kf = -0.2;          % arrival AS vs k-factor
fixpar.C2.LoS.ds_kf = -0.4;           % delay spread vs k-factor
fixpar.C2.LoS.sf_kf = 0.3;            % shadowing std vs k-factor

% Polarisation parameters [1, Table 4.5]
fixpar.C2.LoS.xpr_mu    = 8;          % XPR mean [dB]
fixpar.C2.LoS.xpr_sigma = 4;          % XPR std  [dB]

% Dispersion parameters [1, Table 4.5]
% Log-normal distributions
fixpar.C2.LoS.DS_mu      = -7.39;     % delay spread, mean [s-dB]
fixpar.C2.LoS.DS_sigma   = 0.63;      % delay spread, std [s-dB]
fixpar.C2.LoS.AS_D_mu    = 1;         % arrival angle spread, mean [deg-dB]
fixpar.C2.LoS.AS_D_sigma = 0.25;      % arrival angle spread, std [deg-dB]
fixpar.C2.LoS.AS_A_mu    = 1.70;      % departure angle spread, mean [deg-dB]
fixpar.C2.LoS.AS_A_sigma = 0.19;      % departure angle spread, std [deg-dB]
fixpar.C2.LoS.SF_sigma   = 4;         % shadowing std [dB] (zero mean)
fixpar.C2.LoS.KF_mu      = 7;          % k-factor, dummy value
fixpar.C2.LoS.KF_sigma   = 3;          % k-factor, dummy value

% Decorrelation distances: lambda parameters [1, Table 4.5]
fixpar.C2.LoS.DS_lambda   = 40;      % [m], delay spread
fixpar.C2.LoS.AS_D_lambda = 15;      % [m], departure azimuth spread
fixpar.C2.LoS.AS_A_lambda = 15;      % [m], arrival azimuth spread
fixpar.C2.LoS.SF_lambda   = 45;      % [m], shadowing
fixpar.C2.LoS.KF_lambda   = 12;       % [m], k-factor 

% Path loss, Note! see the path loss equation...
fixpar.C2.LoS.PL_A = [26 40];        % path loss exponent [dB]
fixpar.C2.LoS.PL_B = [39 13.47];     % path loss intercept [dB]
fixpar.C2.LoS.PL_C = [20 6];         % path loss frequency dependence factor
fixpar.C2.LoS.PL_range = [10 5000];  % applicability range [m]

%% C2, NLoS    
% Fixed scenario specific parameters [1, Table 4.5]
fixpar.C2.NLoS.NumClusters = 20;       % Number of ZDSC
fixpar.C2.NLoS.r_DS   = 2.3;           % delays spread proportionality factor
fixpar.C2.NLoS.PerClusterAS_D = 2;     % Per cluster FS angle spread [deg]
fixpar.C2.NLoS.PerClusterAS_A = 15;    % Per cluster MS angle spread [deg]
fixpar.C2.NLoS.LNS_ksi = 3;            % ZDSC LNS ksi [dB], per cluster shadowing

% Cross correlation coefficients [1, Table 4.5]
fixpar.C2.NLoS.asD_ds = 0.4;           % departure AS vs delay spread
fixpar.C2.NLoS.asA_ds = 0.6;           % arrival AS vs delay spread
fixpar.C2.NLoS.asA_sf = -0.3;          % arrival AS vs shadowing std
fixpar.C2.NLoS.asD_sf = -0.6;          % departure AS vs shadowing std
fixpar.C2.NLoS.ds_sf  = -0.4;          % delay spread vs shadowing std
fixpar.C2.NLoS.asD_asA = 0.4;          % departure AS vs arrival AS
fixpar.C2.NLoS.asD_kf = 0;              % departure AS vs k-factor
fixpar.C2.NLoS.asA_kf = 0;              % arrival AS vs k-factor
fixpar.C2.NLoS.ds_kf = 0;               % delay spread vs k-factor
fixpar.C2.NLoS.sf_kf = 0;               % shadowing std vs k-factor

% Polarisation parameters [1, Table 4.5]
fixpar.C2.NLoS.xpr_mu    = 7;          % XPR mean [dB]
fixpar.C2.NLoS.xpr_sigma = 3;          % XPR std  [dB]

% Dispersion parameters [1, Table 4.5]
% Log-normal distributions
fixpar.C2.NLoS.DS_mu      = -6.63;     % delay spread, mean [s-dB]
fixpar.C2.NLoS.DS_sigma   = 0.32;      % delay spread, std [s-dB]
fixpar.C2.NLoS.AS_D_mu    = 0.93;      % arrival angle spread, mean [deg-dB]
fixpar.C2.NLoS.AS_D_sigma = 0.22;      % arrival angle spread, std [deg-dB]
fixpar.C2.NLoS.AS_A_mu    = 1.72;      % departure angle spread, mean [deg-dB]
fixpar.C2.NLoS.AS_A_sigma = 0.14;      % departure angle spread, std [deg-dB]
fixpar.C2.NLoS.SF_sigma   = 8;         % shadowing std [dB] (zero mean)
fixpar.C2.NLoS.KF_mu      = 0;          % k-factor, dummy value
fixpar.C2.NLoS.KF_sigma   = 0;          % k-factor, dummy value

% Decorrelation distances: lambda parameters [1, Table 4.5]
fixpar.C2.NLoS.DS_lambda   = 40;      % [m], delay spread
fixpar.C2.NLoS.AS_D_lambda = 50;      % [m], departure azimuth spread
fixpar.C2.NLoS.AS_A_lambda = 50;      % [m], arrival azimuth spread
fixpar.C2.NLoS.SF_lambda   = 50;      % [m], shadowing
fixpar.C2.NLoS.KF_lambda   = 0;       % [m], k-factor 

% Path loss, Note! see the path loss equation...
fixpar.C2.NLoS.PL_A = NaN;            % path loss exponent [dB]
fixpar.C2.NLoS.PL_B = NaN;            % path loss intercept [dB]
fixpar.C2.NLoS.PL_C = 23;             % path loss frequency dependence factor
fixpar.C2.NLoS.PL_range = [50 5000];  % applicability range [m]

%% C3, NLoS, same as C2 NLoS    
% Fixed scenario specific parameters [1, Table 4.5]
fixpar.C3.NLoS.NumClusters = 20;       % Number of ZDSC
fixpar.C3.NLoS.r_DS   = 2.3;           % delays spread proportionality factor
fixpar.C3.NLoS.PerClusterAS_D = 2;     % Per cluster FS angle spread [deg]
fixpar.C3.NLoS.PerClusterAS_A = 15;    % Per cluster MS angle spread [deg]
fixpar.C3.NLoS.LNS_ksi = 3;            % ZDSC LNS ksi [dB], per cluster shadowing

% Cross correlation coefficients [1, Table 4.5]
fixpar.C3.NLoS.asD_ds = 0.4;           % departure AS vs delay spread
fixpar.C3.NLoS.asA_ds = 0.6;           % arrival AS vs delay spread
fixpar.C3.NLoS.asA_sf = -0.3;          % arrival AS vs shadowing std
fixpar.C3.NLoS.asD_sf = -0.6;          % departure AS vs shadowing std
fixpar.C3.NLoS.ds_sf  = -0.4;          % delay spread vs shadowing std
fixpar.C3.NLoS.asD_asA = 0.4;          % departure AS vs arrival AS
fixpar.C3.NLoS.asD_kf = 0;              % departure AS vs k-factor
fixpar.C3.NLoS.asA_kf = 0;              % arrival AS vs k-factor
fixpar.C3.NLoS.ds_kf = 0;               % delay spread vs k-factor
fixpar.C3.NLoS.sf_kf = 0;               % shadowing std vs k-factor

% Polarisation parameters [1, Table 4.5]
fixpar.C3.NLoS.xpr_mu    = 7;          % XPR mean [dB]
fixpar.C3.NLoS.xpr_sigma = 3;          % XPR std  [dB]

% Dispersion parameters [1, Table 4.5]
% Log-normal distributions
fixpar.C3.NLoS.DS_mu      = -6.63;     % delay spread, mean [s-dB]
fixpar.C3.NLoS.DS_sigma   = 0.32;      % delay spread, std [s-dB]
fixpar.C3.NLoS.AS_D_mu    = 0.93;      % arrival angle spread, mean [deg-dB]
fixpar.C3.NLoS.AS_D_sigma = 0.22;      % arrival angle spread, std [deg-dB]
fixpar.C3.NLoS.AS_A_mu    = 1.72;      % departure angle spread, mean [deg-dB]
fixpar.C3.NLoS.AS_A_sigma = 0.14;      % departure angle spread, std [deg-dB]
fixpar.C3.NLoS.SF_sigma   = 8;         % shadowing std [dB] (zero mean)
fixpar.C3.NLoS.KF_mu      = 0;          % k-factor, dummy value
fixpar.C3.NLoS.KF_sigma   = 0;          % k-factor, dummy value

% Decorrelation distances: lambda parameters [1, Table 4.5]
fixpar.C3.NLoS.DS_lambda   = 40;      % [m], delay spread
fixpar.C3.NLoS.AS_D_lambda = 50;      % [m], departure azimuth spread
fixpar.C3.NLoS.AS_A_lambda = 50;      % [m], arrival azimuth spread
fixpar.C3.NLoS.SF_lambda   = 50;      % [m], shadowing
fixpar.C3.NLoS.KF_lambda   = 0;       % [m], k-factor 

% Path loss, Note! see the path loss equation...
fixpar.C3.NLoS.PL_A = NaN;            % path loss exponent [dB]
fixpar.C3.NLoS.PL_B = NaN;            % path loss intercept [dB]
fixpar.C3.NLoS.PL_C = 23;             % path loss frequency dependence factor
fixpar.C3.NLoS.PL_range = [50 5000];  % applicability range [m]

%% C4, NLoS
% Fixed scenario specific parameters
fixpar.C4.NLoS.NumClusters = 12;        % Number of ZDSC    [1, Table 4.5]
fixpar.C4.NLoS.r_DS   = 2.2;           % delays spread proportionality factor
fixpar.C4.NLoS.PerClusterAS_D = 8;      % Per cluster FS angle spread [deg] [1, Table 4.5]
fixpar.C4.NLoS.PerClusterAS_A = 5;      % Per cluster MS angle spread [deg] [1, Table 4.5]
fixpar.C4.NLoS.LNS_ksi = 4;             % ZDSC LNS ksi [dB], per cluster shadowing [1, Table 4.5]

% Cross correlation coefficients [1, Table 4.5]
fixpar.C4.NLoS.asD_ds = 0.4;            % departure AS vs delay spread
fixpar.C4.NLoS.asA_ds = 0.4;            % arrival AS vs delay spread
fixpar.C4.NLoS.asA_sf = 0.2;            % arrival AS vs shadowing std
fixpar.C4.NLoS.asD_sf = 0;              % departure AS vs shadowing std
fixpar.C4.NLoS.ds_sf  = -0.5;           % delay spread vs shadowing std
fixpar.C4.NLoS.asD_asA = 0;             % departure AS vs arrival AS
fixpar.C4.NLoS.asD_kf = 0;              % departure AS vs k-factor
fixpar.C4.NLoS.asA_kf = 0;              % arrival AS vs k-factor
fixpar.C4.NLoS.ds_kf = 0;               % delay spread vs k-factor
fixpar.C4.NLoS.sf_kf = 0;               % shadowing std vs k-factor

% Polarisation parameters [1, Table 4.5]
fixpar.C4.NLoS.xpr_mu    = 9;           % XPR mean [dB]
fixpar.C4.NLoS.xpr_sigma = 11;          % XPR std  [dB]

% Dispersion parameters [1, Table 4.5]
% Log-normal distributions
fixpar.C4.NLoS.DS_mu      = -6.62;      % delay spread, mean [log10(s)]
fixpar.C4.NLoS.DS_sigma   = 0.32;       % delay spread, std [log10(s)]
fixpar.C4.NLoS.AS_D_mu    = 1.76;       % arrival angle spread, mean [log10(deg)]
fixpar.C4.NLoS.AS_D_sigma = 0.16;       % arrival angle spread, std [log10(deg)]
fixpar.C4.NLoS.AS_A_mu    = 1.25;       % departure angle spread, mean [log10(deg)]
fixpar.C4.NLoS.AS_A_sigma = 0.42;       % departure angle spread, std [log10(deg)]
fixpar.C4.NLoS.SF_sigma   = 7;          % shadowing std [dB] (zero mean)
fixpar.C4.NLoS.KF_mu      = 0;          % k-factor, dummy value
fixpar.C4.NLoS.KF_sigma   = 0;          % k-factor, dummy value

% "Decorrelation distances" [1, Table 4.5]
fixpar.C4.NLoS.DS_lambda   = 11;        % [m], delay spread
fixpar.C4.NLoS.AS_D_lambda = 17;        % [m], departure azimuth spread
fixpar.C4.NLoS.AS_A_lambda = 7;         % [m], arrival azimuth spread
fixpar.C4.NLoS.SF_lambda   = 14;        % [m], shadowing
fixpar.C4.NLoS.KF_lambda   = 0;         % [m], k-factor 

% Path loss, Note! see the path loss equation...
fixpar.C4.NLoS.PL_A = NaN;     % path loss exponent 
fixpar.C4.NLoS.PL_B = NaN;     % path loss intercept
fixpar.C4.NLoS.PL_C = 23;               % path loss frequency dependence factor
fixpar.C4.NLoS.PL_range = [50 5000];    % applicability range [m], (min max)

%% D1, LoS
% Fixed scenario specific parameters [1, Table 4.5]
fixpar.D1.LoS.NumClusters = 11;       % Number of ZDSC
fixpar.D1.LoS.r_DS   = 3.8;           % delays spread proportionality factor
fixpar.D1.LoS.PerClusterAS_D = 2;     % Per cluster FS angle spread [deg]
fixpar.D1.LoS.PerClusterAS_A = 3;     % Per cluster MS angle spread [deg]
fixpar.D1.LoS.LNS_ksi = 3;            % ZDSC LNS ksi [dB], per cluster shadowing

% Cross correlation coefficients [1, Table 4.5]
fixpar.D1.LoS.asD_ds = -0.1;          % departure AS vs delay spread
fixpar.D1.LoS.asA_ds = 0.2;           % arrival AS vs delay spread
fixpar.D1.LoS.asA_sf = -0.2;          % arrival AS vs shadowing std
fixpar.D1.LoS.asD_sf = 0.2;           % departure AS vs shadowing std
fixpar.D1.LoS.ds_sf  = -0.5;          % delay spread vs shadowing std
fixpar.D1.LoS.asD_asA = -0.3;         % departure AS vs arrival AS
fixpar.D1.LoS.asD_kf = 0;             % departure AS vs k-factor
fixpar.D1.LoS.asA_kf = 0.1;           % arrival AS vs k-factor
fixpar.D1.LoS.ds_kf = 0;              % delay spread vs k-factor
fixpar.D1.LoS.sf_kf = 0;              % shadowing std vs k-factor

% Polarisation parameters [1, Table 4.5]
fixpar.D1.LoS.xpr_mu    = 12;        % XPR mean [dB]
fixpar.D1.LoS.xpr_sigma = 8;         % XPR std  [dB]

% Dispersion parameters [1, Table 4.5]
% Log-normal distributions
fixpar.D1.LoS.DS_mu      = -7.80;     % delay spread, mean [s-dB]
fixpar.D1.LoS.DS_sigma   = 0.57;      % delay spread, std [s-dB]
fixpar.D1.LoS.AS_D_mu    = 0.78;      % arrival angle spread, mean [deg-dB]
fixpar.D1.LoS.AS_D_sigma = 0.21;      % arrival angle spread, std [deg-dB]
fixpar.D1.LoS.AS_A_mu    = 1.20;      % departure angle spread, mean [deg-dB]
fixpar.D1.LoS.AS_A_sigma = 0.18;      % departure angle spread, std [deg-dB]
fixpar.D1.LoS.SF_sigma   = 4;         % shadowing std [dB] (zero mean)
fixpar.D1.LoS.KF_mu = 7;              % k-factor mean [dB]
fixpar.D1.LoS.KF_sigma = 6;           % k-factor std [dB]

% Decorrelation distances: lambda parameters [1, Table 4.5]
fixpar.D1.LoS.DS_lambda   = 64;      % [m], delay spread
fixpar.D1.LoS.AS_D_lambda = 25;      % [m], departure azimuth spread
fixpar.D1.LoS.AS_A_lambda = 40;      % [m], arrival azimuth spread
fixpar.D1.LoS.SF_lambda   = 40;      % [m], shadowing
fixpar.D1.LoS.KF_lambda  = 40;       % [m], k-factor 

% Path loss PL = Alog10(d) + B + Clog10(fc/5) (30m<d<dBP) [1, Table 4.4]
fixpar.D1.LoS.PL_A = [21.5 40.0];     % path loss exponent [dB], [d<d_bp d>d_bp]
fixpar.D1.LoS.PL_B = [44.2 10.5];     % path loss intercept [dB], [d<d_bp d>d_bp]
fixpar.D1.LoS.PL_C = [20 1.5];        % path loss frequency dependence factor [dB], [d<d_bp d>d_bp]
fixpar.D1.LoS.PL_range = [30 10000];    % applicability range [m]

%% D1, NLoS
% Fixed scenario specific parameters [1, Table 4.5]
fixpar.D1.NLoS.NumClusters = 10;       % Number of ZDSC
fixpar.D1.NLoS.r_DS   = 1.7;           % delays spread proportionality factor
fixpar.D1.NLoS.PerClusterAS_D = 2;     % Per cluster FS angle spread [deg]
fixpar.D1.NLoS.PerClusterAS_A = 3;     % Per cluster MS angle spread [deg]
fixpar.D1.NLoS.LNS_ksi = 3;            % ZDSC LNS ksi [dB], per cluster shadowing

% Cross correlation coefficients [1, Table 4.5]
fixpar.D1.NLoS.asD_ds = -0.4;          % departure AS vs delay spread
fixpar.D1.NLoS.asA_ds = 0.1;           % arrival AS vs delay spread
fixpar.D1.NLoS.asA_sf = 0.1;           % arrival AS vs shadowing std
fixpar.D1.NLoS.asD_sf = 0.6;           % departure AS vs shadowing std
fixpar.D1.NLoS.ds_sf  = -0.5;          % delay spread vs shadowing std
fixpar.D1.NLoS.asD_asA = -0.2;         % departure AS vs arrival AS
fixpar.D1.NLoS.asD_kf = 0;              % departure AS vs k-factor
fixpar.D1.NLoS.asA_kf = 0;              % arrival AS vs k-factor
fixpar.D1.NLoS.ds_kf = 0;               % delay spread vs k-factor
fixpar.D1.NLoS.sf_kf = 0;               % shadowing std vs k-factor

% Polarisation parameters [1, Table 4.5]
fixpar.D1.NLoS.xpr_mu    = 7;          % XPR mean [dB]
fixpar.D1.NLoS.xpr_sigma = 4;          % XPR std  [dB]

% Dispersion parameters [1, Table 4.5]
% Log-normal distributions
fixpar.D1.NLoS.DS_mu      = -7.60;     % delay spread, mean [s-dB]
fixpar.D1.NLoS.DS_sigma   = 0.48;      % delay spread, std [s-dB]
fixpar.D1.NLoS.AS_D_mu    = 0.96;      % arrival angle spread, mean [deg-dB]
fixpar.D1.NLoS.AS_D_sigma = 0.45;      % arrival angle spread, std [deg-dB]
fixpar.D1.NLoS.AS_A_mu    = 1.52;      % departure angle spread, mean [deg-dB]
fixpar.D1.NLoS.AS_A_sigma = 0.27;      % departure angle spread, std [deg-dB]
fixpar.D1.NLoS.SF_sigma   = 8;         % shadowing std [dB] (zero mean)
fixpar.D1.NLoS.KF_mu      = 0;          % k-factor, dummy value
fixpar.D1.NLoS.KF_sigma   = 0;          % k-factor, dummy value

% Decorrelation distances: lambda parameters [1, Table 4.5]
fixpar.D1.NLoS.DS_lambda   = 36;      % [m], delay spread
fixpar.D1.NLoS.AS_D_lambda = 30;      % [m], departure azimuth spread
fixpar.D1.NLoS.AS_A_lambda = 40;      % [m], arrival azimuth spread
fixpar.D1.NLoS.SF_lambda   = 120;     % [m], shadowing
fixpar.D1.NLoS.KF_lambda   = 0;       % [m], k-factor 

% Paths loss PL = A*log10(d) + B   [1, Table 4.4]
fixpar.D1.NLoS.PL_A = 25.1;            % path loss exponent [dB], [d<d_bp d>d_bp]
fixpar.D1.NLoS.PL_B = 55.4;            % path loss intercept [dB], [d<d_bp d>d_bp]
fixpar.D1.NLoS.PL_C = 21.3;            % path loss frequency dependence factor [dB]
fixpar.D1.NLoS.PL_range = [50 10000];  % applicability range [m]

%% D2a, LoS
% Fixed scenario specific parameters [1, Table 4.5]
fixpar.D2a.LoS.NumClusters = 8;       % Number of ZDSC
fixpar.D2a.LoS.r_DS  = 3.8;           % delays spread proportionality factor
fixpar.D2a.LoS.PerClusterAS_D = 2;     % Per cluster FS angle spread [deg]
fixpar.D2a.LoS.PerClusterAS_A = 3;     % Per cluster MS angle spread [deg]
fixpar.D2a.LoS.LNS_ksi = 3;            % ZDSC LNS ksi [dB], per cluster shadowing

% Cross correlation coefficients [1, Table 4.5]
fixpar.D2a.LoS.asD_ds = -0.1;          % departure AS vs delay spread
fixpar.D2a.LoS.asA_ds = 0.2;           % arrival AS vs delay spread
fixpar.D2a.LoS.asA_sf = -0.2;          % arrival AS vs shadowing std
fixpar.D2a.LoS.asD_sf = 0.2;           % departure AS vs shadowing std
fixpar.D2a.LoS.ds_sf  = -0.5;          % delay spread vs shadowing std
fixpar.D2a.LoS.asD_asA = -0.3;         % departure AS vs arrival AS
fixpar.D2a.LoS.asD_kf = 0;             % departure AS vs k-factor
fixpar.D2a.LoS.asA_kf = 0.1;           % arrival AS vs k-factor
fixpar.D2a.LoS.ds_kf = 0;              % delay spread vs k-factor
fixpar.D2a.LoS.sf_kf = 0;              % shadowing std vs k-factor

% Polarisation parameters [1, Table 4.5]
fixpar.D2a.LoS.xpr_mu    = 12;        % XPR mean [dB]
fixpar.D2a.LoS.xpr_sigma = 8;         % XPR std  [dB]

% Dispersion parameters [1, Table 4.5]
% Log-normal distributions
fixpar.D2a.LoS.DS_mu      = -7.4;     % delay spread, mean [s-dB]
fixpar.D2a.LoS.DS_sigma   = 0.2;      % delay spread, std [s-dB]
fixpar.D2a.LoS.AS_D_mu    = 0.7;      % arrival angle spread, mean [deg-dB]
fixpar.D2a.LoS.AS_D_sigma = 0.31;     % arrival angle spread, std [deg-dB]
fixpar.D2a.LoS.AS_A_mu    = 1.5;      % departure angle spread, mean [deg-dB]
fixpar.D2a.LoS.AS_A_sigma = 0.2;      % departure angle spread, std [deg-dB]
fixpar.D2a.LoS.SF_sigma   = 4;        % shadowing std [dB] (zero mean)
fixpar.D2a.LoS.KF_mu = 7;             % k-factor mean [dB]
fixpar.D2a.LoS.KF_sigma = 6;          % k-factor std [dB]

% Decorrelation distances: lambda parameters [1, Table 4.5]
fixpar.D2a.LoS.DS_lambda   = 64;      % [m], delay spread
fixpar.D2a.LoS.AS_D_lambda = 25;      % [m], departure azimuth spread
fixpar.D2a.LoS.AS_A_lambda = 40;      % [m], arrival azimuth spread
fixpar.D2a.LoS.SF_lambda   = 40;      % [m], shadowing
fixpar.D2a.LoS.KF_lambda  = 40;       % [m], k-factor 

% Path loss PL = Alog10(d) + B + Clog10(fc/5) (30m<d<dBP) [1, Table 4.4]
fixpar.D2a.LoS.PL_A = [21.5 40.0];     % path loss exponent [dB], [d<d_bp d>d_bp]
fixpar.D2a.LoS.PL_B = [44.2 10.5];     % path loss intercept [dB], [d<d_bp d>d_bp]
fixpar.D2a.LoS.PL_C = [20 1.5];        % path loss frequency dependence factor [dB], [d<d_bp d>d_bp]
fixpar.D2a.LoS.PL_range = [30 10000];    % applicability range [m]

% [EOF]