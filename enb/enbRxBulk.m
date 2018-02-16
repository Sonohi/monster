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
	
	% First off, check whether this station has received anything in UL.
	% If not, it simply means that there are no UEs connected to it
	if isempty(enb.Rx.Waveform)
		sonohilog(sprintf('eNodeB %i has an empty received waveform',enb.NCellID), 'NFO');
		continue;
	end
	% In the other cases find all UEs that are linked to this station in this round
	scheduledUEsIndexes = find([enb.ScheduleUL] ~= -1);
  scheduledUEsIds = unique(enb.ScheduleUL(scheduledUEsIndexes));
  % IDs of users and their position in the Users struct correspond

	enbUsers = Users(scheduledUEsIds);
	
	% Parse received waveform
	enb.Rx = enb.Rx.parseWaveform(enb);
	
	% Demodulate received waveforms
	enb.Rx = enb.Rx.demodulateWaveforms(enbUsers);
	
	% Estimate Channel
	enb.Rx = enb.Rx.estimateChannels(enbUsers, cec);
	
	% Equalise
	enb.Rx = enb.Rx.equaliseSubframes(enbUsers);
	
	% Estimate PUCCH (Main UL control channel) for UEs
	enb.Rx = enb.Rx.estimatePucch(enb, enbUsers, timeNow);
	
	% Estimate PUSCH (Main UL control channel) for UEs
	enb.Rx = enb.Rx.estimatePusch(enb, enbUsers, timeNow);
	
	Stations(iStation) = enb;
end
end
