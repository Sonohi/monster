function [ Pin ] = getPowerIn(enb, enbCurrentUtil, otaPowerScale, utilLoThr, utilHiThr )

	%   GET POWER IN is used to calculate the power in based on the BS class
	%
	%   Function fingerprint
	%   enb								->	eNodeB object
	%		enbCurrentUtil		-> 	current utilisation in fraction of RBs used
	% 	otaPowerScale			-> 	scaling for OTA power scale
	% 	utilLothr					-> 	low utilisation threshold for this experiment
	%		utilHiThr					-> 	high utilisation threshold for this experiment
	%
	%		Pin			->	power in (aka taken by the BS from the grid, source DOI 10.1109/MWC.2011.6056691)

	% The output power over the air depends on the utilisation, if energy saving is enabled
	if utilLoThr > 1
		Pout = enb.Pmax*enbCurrentUtil*otaPowerScale;
	else
		Pout = enb.Pmax;
	end

	% Now check power state of the eNodeB
	if enb.PowerState == 1 || enb.PowerState == 2 || enb.PowerState == 3
		% active, overload and underload state
		Pin = enb.CellRefP*enb.P0 + enb.DeltaP*Pout;
	else 
		% shutodwn, inactive and boot
		Pin = enb.Psleep;
	end
end
