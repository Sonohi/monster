classdef sonohieHATA < sonohiBase

  methods

    function obj = sonohieHATA(Channel, Chtype)
       obj = obj@sonohiBase(Channel, Chtype)
    end


    function [lossdB] = computePathLoss(obj, TxNode, RxNode)
      % Computes path loss for eHATA model
      f = TxNode.DlFreq; % Frequency in MHz
      hbPos = TxNode.Position;
      hmPos = RxNode.Position;
      distance = obj.Channel.getDistance(TxNode.Position,RxNode.Position)/1e3; % in Km.
      areatype = obj.Channel.Region; % 'Rural', 'Urban', 'Dense Urban', 'Sea'
      [lossdB, ~] = ExtendedHata_MedianBasicPropLoss(f, ...
              distance, hbPos(3), hmPos(3), areatype);
    end

  end

end
