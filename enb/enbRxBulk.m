function Stations = enbRxBulk(Stations, Users, timeNow, cec)

	%   ENODEB RX BULK performs bulk operations for eNodeB reception
	%
	%   Function fingerprint
	%   Stations	->  EvolvedNodeB array
	%   Users			->  UE objects
	% 	timeNow		-> 	current simulation time
	%		cec				-> channel estimator
	%
	%   Stations	-> updated eNodeB objects

  for iStation = 1:length(Stations)
		enb = Stations(iStation);
		% First off, find all UEs that are linked to this station in this round
		ueGroup = find([Users.NCellID] == enb.NCellID);

		enbUsers = Users(ueGroup);

		% Parse received waveform
    enb.Rx = enb.Rx.parseWaveform(enb);

		% Demodulate received waveforms
    enb.Rx = enb.Rx.demodulate(enbUsers);
		
		% Estimate Channel 
		enb.Rx = enb.Rx.estimateChannel(enb, cec);

		% Equalise
		enb.Rx = enb.Rx.equalise(enb);

		% Estimate PUCCH (Main UL control channel) for UEs
		enb.Rx = enb.Rx.estimatePucch(enb, timeNow)

		Stations(iStation) = enb;
	end
end
