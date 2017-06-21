function [ constDiagram ] = constellationDiagram(txSig,sps)

	%   CONSTELLATION DIAGRAM  is used to generate a cool fig of a constellation
	%
	%   Function fingerprint
	%   txSig  			->  sampling rate
	%   sps   			->  waveform

	figure('Name', 'Constellation diagram');
	constDiagram = comm.ConstellationDiagram('SamplesPerSymbol',sps, ...
    'SymbolsToDisplaySource','Property','SymbolsToDisplay',length(txSig)/sps);

	constDiagram(txSig);


end
