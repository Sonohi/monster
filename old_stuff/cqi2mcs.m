function [mcs] = cqi2mcs(cqi)

%   CQI TO MCS is a network-defined mapping between CQI and MCS
%
%   Function fingerprint
%   cqi		-> Channel Quality Indicator
%
%   mcs		-> modulation and coding scheme

	mcsTable = [0,1,3,4,6,7,9,11,13,15,20,21,22,24,26,28]';
	mcs = mcsTable(cqi + 1,1);
end
