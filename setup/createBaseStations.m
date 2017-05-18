function [Stations] = createBaseStations (Param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   CREATE BASE Stations is used to generate a struct with the base Stations   %
%                                                                              %
%   Function fingerprint                                                       %
%   Param.numMacro      		->  number of macro eNodeBs                        %
%   Param.numSubFramesMacro	->  number of LTE subframes for macro eNodeBs      %
%   Param.numMicro      		-> 	number of micro eNodeBs                        %
%   Param.numSubFramesMacro ->  number of LTE subframes for micro eNodeBs	     %
%   Param.buildings 				-> building position matrix                        %
%                                                                              %
%   Stations  							-> struct with all Stations details and PDSCH      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Create position vectors for the macro and micro BSs
	[macroPos, microPos] = positionBaseStations(Param.numMacro, Param.numMicro, ...
		Param.buildings);

	for (iStation = 1: (Param.numMacro + Param.numMicro))
		% For now only 1 macro in the scenario and it's kept as first elem
		if (iStation <= Param.numMacro)
			Stations(iStation) = BaseStation(Param, 'macro', iStation);
			Stations(iStation).Position = macroPos(iStation, :);
		else
			Stations(iStation) = BaseStation(Param, 'micro', iStation);
			Stations(iStation).Position = microPos(iStation - Param.numMacro, :);
		end

end
