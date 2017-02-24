function [channels] = createChannels (nodes, param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   CREATE CHANNELS is used to generate a channel struct for the "nodes"       %
%                                                                              %
%   Function fingerprint                                                       %
%   nodes     ->  nodes where to install the channel                           %
%   seed      ->  base seed for the channels                                   %
%   mode      ->  Channel mode given by mobility or standard fading            %
%                                                                              %
%   channels  ->  channel struct                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  channels(length(nodes)).NormalizeTxAnts = 'On';
  for i = 1:length(nodes)
    % TODO: Add generalized modes for channel settings
    % Generalized channel setting
    ofdmInfo                        = lteOFDMInfo(nodes(i));
    channels(i).Seed                = param.seed + i;
    channels(i).NRxAnts             = 1;
    channels(i).NormalizeTxAnts     = 'On';
    channels(i).SamplingRate        = ofdmInfo.SamplingRate;

    % Model specific
    switch param.Channel.mode

      case 'fading'
        % Config for lteFadingChannel
        channels(i).DelayProfile        ='ETU';
        channels(i).DopplerFreq         = 70;
        channels(i).MIMOCorrelation     = 'Low';
        channels(i).NTerms              = 16;
        channels(i).ModelType           = 'GMEDS';
        channels(i).InitPhase           = 'Random';
        channels(i).NormalizePathGains  = 'On';

      case 'mobility'
        % Config for lteMovingchannel
        channels(i).MovingScenario = 'Scenario1';
        channels(i).InitTime = 0;
    end
  end
