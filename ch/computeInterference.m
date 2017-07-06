function User = computeInterference(Channel, Stations, User, Param)

%   COMPUTE INTERFERENCE is used to calculate the interference a UE perceives
%
%   Function fingerprint
%   Stations		->  array of eNodeBs
%		User	   		->  the UE
%
%   User 				->  UE back wth computed interference

	if User.ENodeB ~= 0
		switch Param.icScheme
			case 'none'
				a = 0;
				for iStation= 1:length(Stations)
					if Stations(iStation).NCellID ~= User.ENodeB
						% this is not the serving eNodeB
						a = a + calculateReceivedPower(Channel, User, Stations(iStation));
					end
				end
				User.Interference = a;
		end
	end

end
