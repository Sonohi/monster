function Stations = TxBulk(Stations, symbols, Param)

	%   TX Bulk performs bulk operations on the recivers
	%
	%   Function fingerprint
	%   Stations	->  EvolvedNodeB array
	%   symbols		->  All the PDSCH symbols to be transmitted
	% 	Param			-> 	Simulation parameters
	%
	%   Stations	-> EvolvedNodeB with updated Tx attributes

  for iStation = 1:length(Stations)
		enb = Stations(iStation);
		enb.Tx = mapGridAndModulate(enb.Tx, enb, iStation, symbols, Param);
		Stations(iStation) = enb;
	end
end
