function Stations = enbTxBulk(Stations, symbols, Param)

	%   ENODEB TX Bulk performs bulk operations for eNodeB transmissions
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
