function [Stations, Users] = ueTxBulk(Stations,Users, Subframe, Frame)

	%   TX Bulk performs bulk operations on the transmitters for uplink
	%
	%   Function fingerprint
	%   Stations	->  EvolvedNodeB array
	%   Users			->  UserEquipment array
	%
	%   stations  		-> EvolvedNodeB with updated Rx attributes

  for iUser = 1:length(Users)
    % Create waveform
    % TODO: Make sure the root of the sequence is set correcttly
    Users(iUser).Tx = Users(iUser).Tx.mapGridAndModulate(Users(iUser), Subframe, Frame);

    % Propagate channel
    channel_out = user.Tx.Waveform;
    % Assign to the association stations Rx module
    Stations([Stations.NCellID] == user.NCellID).Rx.Waveform = channel_out;
  end
end
