function ModOrd = ModOrdTable(CQI)
	% Modulation order given CQI
	modOrdTable = [2,2,2,2,2,2,4,4,4,6,6,6,6,6,6];
	ModOrd = modOrdTable(CQI);
end