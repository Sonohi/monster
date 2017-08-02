function Users = RxBulk_v1(Stations,Users)
  %% Bulk function for receiving signals for each user that is scheduled.
  % The function conducts basic recept with OFDM demodulation, channel estimation,
  % equalization and BLER count
  %
  % Input:
  %       * Stations (evolvedNodeB class)
  %       * Users (UserEquipment class)
  % Output:
  %        * Mutated Users (UserEquipment class)



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
    user.Rx.Waveform = user.Rx.Waveform(1+user.Offset(station.FrameNo):end,:);

    % Try demodulation
    [demodBool, user.Rx] = user.Rx.demod(station);
    % demodulate received waveform, if it returns 1 (true) then demodulated
    if demodBool
      % Conduct reference measurements
      user.Rx = user.Rx.referenceMeasurements(station);

      % TODO:
      % Estimate Channel

      % Equalize signal

      % Compute errors

    else
      sonohilog(sprintf('Not able to demodulate Station(%i) -> User(%i)...',station.NCellID,user.UeId),'WRN');
      continue;
    end
    %



  end


end
