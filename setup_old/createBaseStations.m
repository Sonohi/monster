function [Stations, Param] = createBaseStations (Param)

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

	% Check that we only have at most 1 macro cell, as only 1 is supported as of now
	if Param.numMacro >= 0 && Param.numMacro <= 19
		% Create position vectors for the macro and micro BSs
		[macroPos, microPos, picoPos] = positionBaseStations(Param.numMacro, Param.numMicro, Param.numPico, Param);

		% Create some indexes for ease of creation of the eNodeBs
		macroThr = Param.numMacro;
		microThr = macroThr + Param.numMicro;
		picoThr = microThr + Param.numPico;

		for iStation = 1:picoThr
			if iStation <= macroThr
				Stations(iStation) = EvolvedNodeB(Param, 'macro', iStation);
				Stations(iStation).Position = [macroPos(iStation, :), Param.macroHeight];
			elseif iStation > microThr
				Stations(iStation) = EvolvedNodeB(Param, 'pico', iStation);
				Stations(iStation).Position = [picoPos(iStation - microThr, :), Param.picoHeight];
			else
				Stations(iStation) = EvolvedNodeB(Param, 'micro', iStation);
				Stations(iStation).Position = [microPos(iStation - macroThr, :), Param.microHeight];
			end
		end

		% Add neighbours to each eNodeB
		for iStation = 1:length(Stations)
			Stations(iStation) = setNeighbours(Stations(iStation), Stations, Param);
		end
	else
		sonohilog('(CREATE BASE STATIONS) error, at most 1 macro eNodeB currently supported','ERR');
	end
	

end
