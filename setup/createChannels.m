function Stations = createChannels (Stations, Param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   CREATE CHANNELS is used to generate a channel struct for the "Stations"    %
%                                                                              %
%   Function fingerprint                                                       %
%   Stations  ->  Stations where to install the channel                 		   %
%   Param     ->  Struct with simulation parameters									           %
%                                                                              %
%   Stations  ->  Channel objects added to stations at Stations(idx).Channel   %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %Channels = struct(zeros(length(Stations),Param.numUsers));

	for (iStation = 1:length(Stations))
        Stations(iStation).Channel = ChBulk_v1(Param);
        Stations(iStation).Channel.Seed = Param.seed + iStation;
        OfdmInfo = lteOFDMInfo(struct(Stations(iStation)));
        Stations(iStation).Channel.SamplingRate = OfdmInfo.SamplingRate;
	end

end
