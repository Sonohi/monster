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
		for (iUser = 1:Param.numUsers)
            Stations(iStation).channel(iUser) = ChBulk_v1(Param);
			OfdmInfo = lteOFDMInfo(Stations(iStation));
			set(Stations(iStation).channel(iUser),...
                'Seed',Param.seed + iStation,...
                'SamplingRate',OfdmInfo.SamplingRate,...
                'User',iUser);

		end
	end

end
