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
		%[macroPos, microPos, picoPos, networkLayout] = positionBaseStations(Param.numMacro, Param.numMicro, Param.numPico, Param);
		xc = (Param.area(3)-Param.area(1))/2;
		yc = (Param.area(4)-Param.area(2))/2;
		networkLayout = NetworkLayout(xc,yc,Param);

		%TODO: Replace with new config class
		Param = networkLayout.Param; %To update parameters to match a chosen scenario

		%Draw the base stations
		networkLayout.draweNBs(Param);	
		for iStation = 1:networkLayout.NumMacro
			Stations(iStation) = EvolvedNodeB(Param, 'macro', networkLayout.MacroCells{iStation}.CellID);
			Stations(iStation).Position = [networkLayout.MacroCoordinates(iStation, :), Param.macroHeight];
		end
		for iStation = 1:networkLayout.NumMicro
			Stations(iStation) = EvolvedNodeB(Param, 'micro', networkLayout.MicroCells{iStation}.CellID);
			Stations(iStation).Position = [networkLayout.MicroCoordinates(iStation, :), Param.microHeight];
		end
		for iStation = 1:networkLayout.NumPico
			Stations(iStation) = EvolvedNodeB(Param, 'pico', networkLayout.PicoCells{iStation}.CellID);
			Stations(iStation).Position = [networkLayout.PicoCoordinates(iStation, :), Param.picoHeight];
		end


		% Add neighbours to each eNodeB
		for iStation = 1:length(Stations)
			Stations(iStation) = setNeighbours(Stations(iStation), Stations, Param);
		end
	else
		sonohilog('(CREATE BASE STATIONS) error, at most 1 macro eNodeB currently supported','ERR');
	end
	

end
