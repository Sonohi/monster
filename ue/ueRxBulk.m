function Users = ueRxBulk(Stations, Users, cec)

	%   UE RX Bulk performs bulk operations on the recivers
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
    station = Stations([Stations.NCellID] == user.ENodeBID);
    scheduled = checkUserSchedule(user,station);
    
    % Compute offset based on synchronization signals.
    user.Rx = user.Rx.computeOffset(station);

    
    % Apply Offset
    if user.Rx.Offset > length(user.Rx.Waveform)
        sonohilog(sprintf('Offset for User %i out of bounds, not able to synchronize',user.NCellID),'WRN')
		else
        user.Rx.Waveform = user.Rx.Waveform(1+abs(user.Rx.Offset):end,:);
		end
		
				
		% Conduct reference measurements
    user.Rx = user.Rx.referenceMeasurements(station);


    if ~scheduled
      % user not scheduled, reset the metrics recorded for this round
      user.Rx = user.Rx.logNotScheduled();
      Users(iUser) = user;
      continue;
		end
		
    % Try demodulation
    [demodBool, user.Rx] = user.Rx.demodulateWaveform(station);
    % demodulate received waveform, if it returns 1 (true) then demodulated
    if demodBool
      % Estimate Channel
			user.Rx = user.Rx.estimateChannel(station, cec);
      % Equalize signal
			user.Rx = user.Rx.equaliseSubframe();
      % Estimate PDSCH (main data channel)
			user.Rx = user.Rx.estimatePdsch(user, station);
			% calculate EVM
			user.Rx = user.Rx.calculateEvm(station);
			% Calculate the CQI to use
			user.Rx = user.Rx.selectCqi(station);
			% Log block reception stats
			user.Rx = user.Rx.logBlockReception(user);
    else
      sonohilog(sprintf('Not able to demodulate Station(%i) -> User(%i)...',station.NCellID,user.NCellID),'WRN');
			user.Rx = user.Rx.logNotDemodulated();
			user.Rx.CQI = 3;
      Users(iUser) = user;
      continue;
    end
    % Update parent structure
		Users(iUser) = user;
  end
end
