classdef sonohi3GPP38901 < sonohiBase
% This is implemented using the 3GPP TR 38901 v14 document
% 5G; Study on channel model for frequencies from .5 to 100 GHZ
%
% .. todo:: Add fast fading as specified by the specification. E.g. CDL and TDL
%
% V1 contains only the implementation of pathloss with shadowing added as log-normal distributions based on a standard deviation.
% 
% Current scenarios are implemented and usable:
% 
% * 'RMa' - Rural Macro
% * 'UMa' - Urban Macro
% * 'UMi' - Urban Micro
methods

    function obj = sonohi3GPP38901(Channel, Chtype)
      % Inherits :class:`ch.SONOHImodels.sonohiBase`
      obj = obj@sonohiBase(Channel, Chtype);
    end


    function [lossdB] = computePathLoss(obj, TxNode, RxNode)
			% Computes path loss. uses the following parameters
			% 
			% * `f` - Frequency in GHz
			% * `hBs` - Height of Tx
			% * `hUt` - height of Rx
			% * `d2d` - Distance in 2D
			% * `d3d` - Distance in 3D
			% * `LOS` - Link LOS boolean, determined by :meth:`ch.SonohiChannel.isLinkLOS`
			% * `shadowing` - Boolean for enabling/disabling shadowing using log-normal distribution
			% * `avgBuilding` - Average height of buildings
			% * `avgStreetWidth` - Average width of the streets
      f = TxNode.DlFreq/10e2; % Frequency in GHz
      hBs = TxNode.Position(3);
      hUt = RxNode.Position(3);
			distance2d =  obj.Channel.getDistance(TxNode.Position(1:2),RxNode.Position(1:2));
      distance3d = obj.Channel.getDistance(TxNode.Position,RxNode.Position);
			
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
			avgBuilding = mean(obj.Channel.BuildingFootprints(:,5));
			avgStreetWidth = obj.Channel.BuildingFootprints(2,2)-obj.Channel.BuildingFootprints(1,4);
      lossdB = loss3gpp38901(areatype, distance2d, distance3d, f, hBs, hUt, avgBuilding, avgStreetWidth, LOS, shadowing, seed);
    end

  end

end
