function [ constDiagram ] = constellationDiagram(txSig,sps)
constDiagram = comm.ConstellationDiagram('SamplesPerSymbol',sps, ...
    'SymbolsToDisplaySource','Property','SymbolsToDisplay',length(txSig)/sps);

constDiagram(txSig)


end

