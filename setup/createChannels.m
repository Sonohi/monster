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


	% Model specific
	switch param.Channel.mode
		case 'fading'
			% Config for lteFadingChannel
			channels(1:length(nodes), 1:param.numUsers) = struct('NRxAnts',1,'NormalizeTxAnts', ...
				'On', 'DelayProfile', 'ETU', 'DopplerFreq', 70, 'MIMOCorrelation', 'Low', ...
				'NTerms', 16, 'ModelType', 'GMEDS', 'InitPhase', 'Random', 'NormalizePathGains', 'On');

		case 'mobility'
			% Config for lteMovingchannel
			channels(1:length(nodes), 1:param.numUsers) = struct('NRxAnts',1,'NormalizeTxAnts', ...
				'On', 'MovingScenario', 'Scenario1', 'InitTime', 0);
	end

	% TODO: Add generalized modes for channel settings
	% Generalized channel setting
	for (i = 1:length(nodes))
		for (j = 1:param.numUsers)
			ofdmInfo = lteOFDMInfo(nodes(i));
			channels(i,j).Seed = param.seed + i;
			channels(i,j).SamplingRate = ofdmInfo.SamplingRate;
		end
	end

end
