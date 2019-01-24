function [mapSym] = mapSymbols(sym, thr)

%   MAP SYMBOLS is used to fit an array of symbols into a resource grid				 
%
%   Function fingerprint
%   sym       ->  original symbol sequence
%   thr       ->  threshold for the overall sym size
%
%   mapSym		->  symbols ready to be mapped

	sz = length(sym) - thr;
	if (sz > 0)
		mapSym(1:thr,1) = sym(1:thr,1);
	elseif (sz < 0)
		padding(1:abs(sz),1) = 0 + 0i;
		mapSym = cat(1, sym, padding);
	else
		mapSym = sym;

end
