function [Users, Stations] = refreshUsersAssociation(Users,Stations,Param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   REFRESH USERS ASSOCIATION links Users to a BS								               %
%                                                                              %
%   Function fingerprint                                                       %
%   Users   		->  struct with all the suers in the network                   %
%   Stations		->  base station struct                                        %
%                                                                              %
%   nodeUsers ->  Users indexes associated with node                           %
%                                                                              %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% reset stations
	for (iStation = 1:length(Stations))
		Stations(iStation).Users(1:Param.numUsers) = struct('velocity',Param.velocity,...
			'queue',  struct('size', 0, 'time', 0, 'pkt', 0), 'eNodeB', 0, 'scheduled', false,...
			'ueId', 0, 'position', [0 0], 'wCqi', 6);
	end

	d0=1; % m
	for (iUser = 1:length(Users))
		% get UE position
		uePos = Users(iUser).position;
		minLossDb = 200;
		for (iStation = 1:length(Stations))
			bs = Stations(iStation);
			bsPos = bs.Position;
			dist = sqrt((bsPos(1)-uePos(1))^2 + (bsPos(2)-uePos(2))^2 );
			% compute pathloss
			if (bs.NDLRB == Param.numSubFramesMacro)
				% macro
				gamma = 4.5;
				lossDb = pathloss(Param.dlFreq, gamma, d0, dist);
			elseif (bs.NDLRB == Param.numSubFramesMicro)
				% micro
				gamma = 3;
				lossDb = pathloss(Param.dlFreq, gamma, d0, dist);
			else
				error('Unrecognized eNB');
			end
			% check if this is the minimum so far
			if (lossDb < minLossDb)
				Users(iUser).eNodeB = Stations(iStation).NCellID;
				minLossDb = lossDb;
			end
		end
		% Now that the assignement is done, write also on the side of the station
		% TODO replace with matrix operation
		for (iStation = 1:length(Stations))
			if (Stations(iStation).NCellID == Users(iUser).eNodeB)
				for (iUser = 1:Param.numUsers)
					if (Stations(iStation).Users(iUser).ueId == 0)
						Stations(iStation).Users(iUser) = Users(iUser);
						break;
					end
				end
				break;
			end
	end
end
