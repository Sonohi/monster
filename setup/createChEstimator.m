function [cec] = createChEstimator ()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   CREATE CHANNELS is used to generate a channel struct for the "nodes"       %
%                                                                              %
%   Function fingerprint                                                       %
%                                                                              %
%   channels  ->  channel struct                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  cec = struct;                        % Channel estimation config structure
  cec.PilotAverage = 'UserDefined';    % Type of pilot symbol averaging
  cec.FreqWindow = 31;                 % Frequency window size
  cec.TimeWindow = 23;                 % Time window size
  cec.InterpType = 'Cubic';            % 2D interpolation type
  cec.InterpWindow = 'Centered';       % Interpolation window type
  cec.InterpWinSize = 1;               % Interpolation window size
end