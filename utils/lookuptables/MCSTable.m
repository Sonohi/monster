function MCS = MCSTable(CQI)
	% Return the MCS values for a given CQI
	MCSvalues = [0,1,3,4,6,7,9,11,13,15,20,21,22,24,26,28];
	MCS = MCSvalues(CQI+1);
end