function Stations = createChannels (Stations, Param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   CREATE CHANNELS is used to generate a channel struct for the "Stations"    %
%                                                                              %
%   Function fingerprint                                                       %
%   Stations  ->  Stations where to install the channel                 		   %
%   Param     ->  Struct with simulation parameters									           %
%                                                                              %
%   Stations  ->  Channel objects added to stations at Stations(idx).channel(UserID)   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Channels = struct(zeros(length(Stations),Param.numUsers));

	for (iStation = 1:length(Stations))
         % TODO change class to be a dependency of station and user such
         % that each station user pair has a predefined channel
        Stations(iStation).Channel = ChBulk_v1(Param,Stations(iStation));
        Stations(iStation).Channel.Seed = Param.seed + iStation;
        OfdmInfo = lteOFDMInfo(Stations(iStation));
        Stations(iStation).Channel.SamplingRate = OfdmInfo.SamplingRate;
	end

end
