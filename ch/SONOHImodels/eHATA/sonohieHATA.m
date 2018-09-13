classdef sonohieHATA < sonohiBase
% This is using an existing implementation of the Extended HATA model as seen here: https://github.com/usnistgov/eHATA
% The Extended Hata (eHATA) propagation model code was implemented by employees of the National Institute of Standards and Technology (NIST), Communications Technology Laboratory (CTL).
%
% This model uses frequency, distance and a region determined by a string. The regions are given as:
% 
% * 'Urban'
% * 'Suburban'
methods

    function obj = sonohieHATA(Channel, Chtype)
      % Inherits :class:`ch.SONOHImodels.sonohiBase`
      obj = obj@sonohiBase(Channel, Chtype);
    end


    function [lossdB, varargout] = computePathLoss(obj, TxNode, RxNode)
      % Computes path loss
      f = TxNode.DlFreq; % Frequency in MHz
      hbPos = TxNode.Position;
      hmPos = RxNode.Position;
      distance = obj.Channel.getDistance(TxNode.Position,RxNode.Position)/1e3; % in Km.
      areatype = obj.Channel.Region; % 'Rural', 'Urban', 'Dense Urban', 'Sea'
      [lossdB, ~] = ExtendedHata_MedianBasicPropLoss(f, distance, hbPos(3), hmPos(3), areatype);
      
    end

  end

end