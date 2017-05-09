function [Channels] = createChannels (Stations, Param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   CREATE CHANNELS is used to generate a channel struct for the "Stations"    %
%                                                                              %
%   Function fingerprint                                                       %
%   Stations  ->  Stations where to install the channel                 		   %
%   Param     ->  Struct with simulation parameters									           %
%                                                                              %
%   Channels  ->  channel struct                                               %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Model specific
	switch Param.channel.mode
		case 'fading'
			% Config for lteFadingChannel
			Channels(1:length(Stations), 1:Param.numUsers) = struct('NRxAnts',1,'NormalizeTxAnts', ...
				'On', 'DelayProfile', 'ETU', 'DopplerFreq', 70, 'MIMOCorrelation', 'Low', ...
				'NTerms', 16, 'ModelType', 'GMEDS', 'InitPhase', 'Random', 'NormalizePathGains', 'On');

		case 'mobility'
			% Config for lteMovingchannel
			Channels(1:length(Stations), 1:Param.numUsers) = struct('NRxAnts',1,'NormalizeTxAnts', ...
				'On', 'MovingScenario', 'Scenario1', 'InitTime', 0);
	end

	% TODO: Add generalized modes for channel settings
	% Generalized channel setting
	for (iStation = 1:length(Stations))
		for (iUser = 1:Param.numUsers)
			OfdmInfo = lteOFDMInfo(Stations(iStation));
			Channels(iStation,iUser).Seed = Param.seed + iStation;
			Channels(iStation,iUser).SamplingRate = OfdmInfo.SamplingRate;
		end
	end

end
