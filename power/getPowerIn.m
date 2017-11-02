function [ Pin ] = getPowerIn(enb, util)

	%   GET POWER IN is used to calculate the power in based on the BS class
	%
	%   Function fingerprint
	%   enb			->	eNodeB object
	%		util		-> 	current utilisation in fraction of RBs used
	%
	%		Pin			->	power in (aka taken by the BS from the grid, source DOI 10.1109/MWC.2011.6056691)

	Pout = enb.Pmax * util; % check this assumption
	if Pout == 0
	  Pin = enb.Psleep;
	else
	  Pin = enb.CellRefP*enb.P0 + enb.DeltaP*Pout;
	end

end
