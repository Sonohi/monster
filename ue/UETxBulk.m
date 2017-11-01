function [Stations, Users] = ueTxBulk(Stations,Users, NSubframe, NFrame)

	%   TX Bulk performs bulk operations on the transmitters for uplink
	%
	%   Function fingerprint
	%   Stations	->  EvolvedNodeB array
	%   Users			->  UserEquipment array
	%
	%   stations  		-> EvolvedNodeB with updated Rx attributes

  for iUser = 1:length(Users)
    % FInd the serving eNodeB
    iServingStation = [Stations.NCellID] == Users(iUser).NCellID;
    ue = Users(iUser);
    enb = Stations(iServingStation);

    % Set the scheduling slots for this UE
    ue = ue.setSchedulingSlots(enb);

    % set subframe and frame number 
    ue.NSubframe = NSubframe;
    ue.NFrame = Nframe;
    
    % Create local resource grid and modulate
    ue.Tx = ue.Tx.mapGridAndModulate(ue);
    
    Users(iUser) = ue;
  end
end
