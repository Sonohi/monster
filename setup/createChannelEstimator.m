function [cec] = createChannelEstimator ()

%   CREATE CHANNEL ESTIMATOR creates a struct with the 2 channel estimators for DL and UL
%
%   Function fingerprint
%
%   cec  ->  channel estimators

  dl.PilotAverage = 'UserDefined';    % Type of pilot symbol averaging
  dl.FreqWindow = 31;                 % Frequency window size
  dl.TimeWindow = 23;                 % Time window size
  dl.InterpType = 'Cubic';            % 2D interpolation type
  dl.InterpWindow = 'Centered';       % Interpolation window type
  dl.InterpWinSize = 1;               % Interpolation window size

  ul.PilotAverage = 'UserDefined';    % Type of pilot averaging
  ul.FreqWindow = 13;                 % Frequency averaging windows in REs
  ul.TimeWindow = 1;                  % Time averaging windows in REs
  ul.InterpType = 'cubic';            % Interpolation type
  ul.Reference = 'Antennas';          % Reference for channel estimation

  cec.Downlink = dl;
  cec.Uplink = ul;
end
