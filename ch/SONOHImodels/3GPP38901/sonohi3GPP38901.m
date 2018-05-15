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
			% TODO: This mapping can be generalized and moved to a parent
			% stucture
			if strcmp(TxNode.BsClass, 'macro')
				areatype = obj.Channel.Region.macroScenario; % 'RMa', 'UMa', 'UMi'
			elseif strcmp(TxNode.BsClass,'micro')
				areatype = obj.Channel.Region.microScenario;
			elseif strcmp(TxNode.BsClass,'pico')
				areatype = obj.Channel.Region.picoScenario;
			end
			seed = obj.Channel.getLinkSeed(RxNode);
			LOS = obj.Channel.isLinkLOS(TxNode, RxNode, false);
			shadowing = obj.Channel.enableShadowing;
			avg_building = mean(obj.Channel.BuildingFootprints(:,5));
			avg_street_width = obj.Channel.BuildingFootprints(2,2)-obj.Channel.BuildingFootprints(1,4);
      lossdB = loss3gpp38901(areatype, distance_2d, distance_3d, f, h_bs, h_ut, avg_building, avg_street_width, LOS, shadowing, seed);
    end

  end

end
