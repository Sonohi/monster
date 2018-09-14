classdef sonohiITU < sonohiBase
% This is using an existing implementation of the ITU-R 1546 model as seen here: https://www.itu.int/en/ITU-R/study-groups/rsg3/Pages/iono-tropo-spheric.aspx
%
% The model is based on frequency, percentage time (defaults to 50%), distance and a propagation region. Currently only land is considered. The regions supported are:
%
% * 'Rural'
% * 'Suburban'
% * 'Urban' 
% * 'Dense Urban'

    methods

        function obj = sonohiITU(Channel, Chtype)
            % Inherits :class:`ch.SONOHImodels.sonohiBase`
            obj = obj@sonohiBase(Channel, Chtype)
        end


        function [lossdB, varargout] = computePathLoss(obj, TxNode, RxNode)
            % Computes ITU pathloss
            f = TxNode.DlFreq; % Frequency in MHz
            percentage_time = 50; % Percentage time 
            tx_heff = TxNode.Position(3); % Effective height of transmitter
            rx_heff = RxNode.Position(3); % Height of receiver

            areatype = obj.Channel.Region; % 'Rural', 'Urban', 'Dense Urban', 'Sea'


            % R2: Representative clutter height around receiver 
            % Typical values: 
            % R2=10 for area='Rural' or 'Suburban' or 'Sea'
            % R2=20 for area='Urban'
            % R2=30 for area='Dense Urban'
            if strcmp(areatype,'Rural') || strcmp(areatype,'Suburban') || strcmp(areatype,'Sea')
                R2 = 10;
            elseif strcmp(areatype,'Urban')
                R2 = 20;
            else
                R2 = 30;
            end
        
            distance = obj.Channel.getDistance(TxNode.Position,RxNode.Position)/1e3; % in Km.

            % Cell of strings defining the path        'Land', 'Sea',
            % zone for each given path length in d_v   'Warm', 'Cold'
            % starting from transmitter/base terminal
            path_c = 'Land'; 

            % TODO: add terrain profile info from building grid
            % 0 - no terrain profile information available, 
            % 1 - terrain information available
            pathinfo = 0; 
            debug = 0;
            [T,~,lossdB] = evalc('P1546FieldStrMixed(f,percentage_time,tx_heff,rx_heff,R2,areatype,distance,path_c, pathinfo, [], [], [], [], [], [], [], [], [], [], debug)');
            varargout{1} = RxNode;
        end


    end

end
