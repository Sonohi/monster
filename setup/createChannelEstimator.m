function [ChannelEstimator] = createChannelEstimator ()
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   CREATE CHANNELS is used to generate a channel struct for the "nodes"       %
%                                                                              %
%   Function fingerprint                                                       %
%                                                                              %
%   channels  ->  channel struct                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  ChannelEstimator = struct;                        % Channel estimation config structure
  ChannelEstimator.PilotAverage = 'UserDefined';    % Type of pilot symbol averaging
  ChannelEstimator.FreqWindow = 31;                 % Frequency window size
  ChannelEstimator.TimeWindow = 23;                 % Time window size
  ChannelEstimator.InterpType = 'Cubic';            % 2D interpolation type
  ChannelEstimator.InterpWindow = 'Centered';       % Interpolation window type
  ChannelEstimator.InterpWinSize = 1;               % Interpolation window size
end
