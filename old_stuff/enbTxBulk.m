function [Stations, Users] = enbTxBulk(Stations, Users, Param, timeNow)

	%   ENODEB TX Bulk performs bulk operations for eNodeB transmissions
	%
	%   Function fingerprint
	%   Stations	->  EvolvedNodeB array
	%   Users			->  UEs array
	% 	Param			-> 	Simulation parameters
	% 	timeNow		-> 	Current simulation time
	%
	%   Stations	-> EvolvedNodeB with updated Tx attributes
	%		Users			-> Updated UEs

	for iUser = 1:length(Users)
		% get the eNodeB this UE is connected to
		iServingStation = find([Stations.NCellID] == Users(iUser).ENodeBID);
		
		% Check if this UE is scheduled otherwise skip
		if checkUserSchedule(Users(iUser), Stations(iServingStation))
			% generate transport block for the user
			[Stations(iServingStation), Users(iUser)] = ... 
				createTransportBlock(Stations(iServingStation), Users(iUser), Param, timeNow);
			
			% generate codeword (RV defaulted to 0)
			Users(iUser) = Users(iUser).createCodeword();
			
			% finally, generate the arrays of complex symbols by setting the
			% correspondent values per each eNodeB-UE pair
			% setup current subframe for serving eNodeB
			if ~isempty(Users(iUser).Codeword)
				[Stations(iServingStation), Users(iUser)] = createSymbols(Stations(iServingStation), Users(iUser));
			end
		end
	end

	% Once all PDSCH symbols have been generated and pushed into the grid, we can modulate
	for iStation = 1:length(Stations)
		enb = Stations(iStation);
		enb.Tx = modulateTxWaveform(enb.Tx, enb);
		Stations(iStation) = enb;
	end
end
