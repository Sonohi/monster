classdef sonohiQuadriga < sonohiBase

    methods

        function obj = sonohiQuadriga(Channel, Chtype)
            % Inherits :class:`ch.SONOHImodels.sonohiBase`
            obj = obj@sonohiBase(Channel, Chtype)
        end


        function [lossdB] = computePathLoss(obj, TxNode, RxNode)
           
        end


    end

end
