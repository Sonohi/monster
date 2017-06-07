function [ constDiagram ] = constellationDiagram(txSig,sps)
constDiagram = comm.ConstellationDiagram('SamplesPerSymbol',sps, ...
    'SymbolsToDisplaySource','Property','SymbolsToDisplay',100);

constDiagram(txSig)


end

