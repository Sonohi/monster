classdef sonohi3GPP38901 < sonohiBase
methods

    function obj = sonohi3GPP38901(Channel, Chtype)
      % Inherits :class:`ch.SONOHImodels.sonohiBase`
      obj = obj@sonohiBase(Channel, Chtype);
    end


    function [lossdB] = computePathLoss(obj, TxNode, RxNode)
      % Computes path loss
      f = TxNode.DlFreq/10e2; % Frequency in GHz
      h_bs = TxNode.Position(3);
      h_ut = RxNode.Position(3);
			distance_2d =  obj.Channel.getDistance(TxNode.Position(1:2),RxNode.Position(1:2));
      distance_3d = obj.Channel.getDistance(TxNode.Position,RxNode.Position);
      areatype = obj.Channel.Region; % 'RMa', 'UMa', 'UMi'
			rng(obj.Channel.Seed)
			seed = randi([0 999999],1,1);
			LOS = obj.Channel.isLinkLOS(TxNode, RxNode, false);
			shadowing = 1;
			avg_building = mean(obj.Channel.BuildingFootprints(:,5));
			avg_street_width = obj.Channel.BuildingFootprints(2,2)-obj.Channel.BuildingFootprints(1,4);
      lossdB = loss3gpp38901(areatype, distance_2d, distance_3d, f, h_bs, h_ut, avg_building, avg_street_width, LOS, shadowing, seed);
    end

  end

end
