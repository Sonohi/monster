function validateStations(Stations)

	%   VALIDATE STATIONS is a simple utility to validate the stations variable
	%
	%   Function fingerprint
	%   Stations		->  test

	validateattributes(Stations,{'EvolvedNodeB'},{'vector'});
end
