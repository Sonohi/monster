function Users = RxBulk(Stations,Users, cec)

	%   RX Bulk performs bulk operations on the recivers
	%
	%   Function fingerprint
	%   Stations	->  EvolvedNodeB array
	%   Users			->  UserEquipment array
	% 	cec				-> 	Channel Estimator
	%
	%   Users  		-> UserEquipment with updated Rx attributes

  for iUser = 1:length(Users)
    % Local copy for mutation
    user = Users(iUser);

    % Get serving station
    station = Stations([Stations.NCellID] == user.ENodeB);
    scheduled = checkUserSchedule(user,station);
    if ~scheduled
      % Pass user iteration the user is not scheduled.
      continue;
    end

    % Apply Offset
    user.Rx.Waveform = user.Rx.Waveform(1+user.Rx.Offset:end,:);

    % Try demodulation
    [demodBool, user.Rx] = user.Rx.demod(station);
    % demodulate received waveform, if it returns 1 (true) then demodulated
    if demodBool
			% Conduct reference measurements
      user.Rx = user.Rx.referenceMeasurements(station);
      % Estimate Channel
			user.Rx = user.Rx.estimateChannel(station, cec);
      % Equalize signal
			user.Rx = user.Rx.equalise();
      % Estimate PDSCH (main data channel)
			user.Rx = user.Rx.estimatePdsch(user, station);
			% calculate EVM
			user.Rx = user.Rx.calculateEvm(station);
			% Finally calculate the CQI to use
			user.Rx = user.Rx.selectCqi(station);
			Users(iUser) = user;
    else
      sonohilog(sprintf('Not able to demodulate Station(%i) -> User(%i)...',station.NCellID,user.UeId),'WRN');
      continue;
    end
  end
end
