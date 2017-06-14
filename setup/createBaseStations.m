function [Stations, h] = createBaseStations (Param)

%   CREATE BASE Stations is used to generate a struct with the base Stations
%
%   Function fingerprint
%   Param.numMacro      		->  number of macro eNodeBs
%   Param.numSubFramesMacro	->  number of LTE subframes for macro eNodeBs
%   Param.numMicro      		-> 	number of micro eNodeBs
%   Param.numSubFramesMacro ->  number of LTE subframes for micro eNodeBs
%   Param.buildings 				-> building position matrix
%
%   Stations  							-> struct with all Stations details and PDSCH

	% Create position vectors for the macro and micro BSs
	[macroPos, microPos, h] = positionBaseStations(Param.numMacro, Param.numMicro, ...
		Param.buildings, Param.draw);

	for iStation = 1: (Param.numMacro + Param.numMicro)
		% For now only 1 macro in the scenario and it's kept as first elem
		if (iStation <= Param.numMacro)
			Stations(iStation) = EvolvedNodeB(Param, 'macro', iStation);
			Stations(iStation).Position = [macroPos(iStation, :), Param.MacroHeight];
		else
			Stations(iStation) = EvolvedNodeB(Param, 'micro', iStation);
			Stations(iStation).Position = [microPos(iStation - Param.numMacro, :), Param.MicroHeight];
		end
	end

	% Add neighbours to each eNodeB
	% TODO see if it is possible to combine the 2 loops even though all positions
	% have to be set first
	for iStation = 1:length(Stations)
		Stations(iStation) = setNeighbours(Stations(iStation), Stations, Param);
	end

end
