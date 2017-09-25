function Stations = UETxBulk(Stations,Users, Subframe, Frame)

	%   TX Bulk performs bulk operations on the transmitters for uplink
	%
	%   Function fingerprint
	%   Stations	->  EvolvedNodeB array
	%   Users			->  UserEquipment array
	%
	%   stations  		-> EvolvedNodeB with updated Rx attributes

  for iUser = 1:length(Users)
    % Local copy for mutation
    user = Users(iUser);

    % Create waveform
    % TODO: Make sure the root of the sequence is set correcttly
    user.Tx = user.Tx.modulateTxWaveform(Subframe,Frame);

    % Propagate channel
    channel_out = user.Tx.Waveform;
    % Assign to the association stations Rx module
    Stations([Stations.NCellID] == user.ENodeB).Rx.Waveform = channel_out;
    
    
    


  end
end
