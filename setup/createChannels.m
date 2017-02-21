function [channels] = createChannels (nodes, seed)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   CREATE CHANNELS is used to generate a channel struct for the "nodes"       %
%                                                                              %
%   Function fingerprint                                                       %
%   nodes     ->  nodes where to install the channel                           %
%   seed      ->  base seed for the channels                                   %
%                                                                              %
%   channels  ->  channel struct                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

  channels(length(nodes)).NormalizeTxAnts = 'On';
  for i = 1:length(nodes)
    ofdmInfo                        = lteOFDMInfo(nodes(i));
    channels(i).Seed                = seed + i;
    channels(i).NRxAnts             = 1;
    channels(i).DelayProfile        ='ETU';
    channels(i).DopplerFreq         = 70;
    channels(i).MIMOCorrelation     = 'Low';
    channels(i).NTerms              = 16;
    channels(i).ModelType           = 'GMEDS';
    channels(i).InitPhase           = 'Random';
    channels(i).NormalizePathGains  = 'On';
    channels(i).NormalizeTxAnts     = 'On';
    channels(i).SamplingRate        = ofdmInfo.SamplingRate;
  end
end
