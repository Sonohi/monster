function [users] = checkAssociatedUsers(users,stations,param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   CHECK ASSOCIATED USERS links users to a BS (by distance???)                %
%                                                                              %
%   Function fingerprint                                                       %
%   users   ->  struct with all the suers in the network                       %
%   node    ->  base station struct                                            %
%                                                                              %
%   nodeUsers ->  users indexes associated with node                           %
%                                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

d0=1; % m
	for userIndex = 1:length(users)
		% get UE position
		uePos = users(userIndex).Position;
		minLossDb = 200;
		for stationIndex = 1:length(stations)
			bs = stations(stationIndex);
			bsPos = bs.Position;
			dist = sqrt((bsPos(1)-uePos(1))^2 + (bsPos(2)-uePos(2))^2 );
			% compute pathloss
			if (bs.NDLRB == param.numSubFramesMacro)
				% macro
				gamma = 4.5;
				lossDb = pathloss(param.dlFreq, gamma, d0, dist);
			elseif (bs.NDLRB == param.numSubFramesMicro)
				% micro
				gamma = 3;
				lossDb = pathloss(param.dlFreq, gamma, d0, dist);
			else
				error('Unrecognized eNB');
			end
			% check if this is the minimum so far
			if (lossDb < minLossDb)
				users(userIndex).eNodeB = stations(stationIndex).NCellID;
				minLossDb = lossDb;
			end

		end

	end

end
