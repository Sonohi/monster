classdef ChBulk_v2
    %CHBULK_V2 Summary of this class goes here
    %   Detailed explanation goes here
    
    properties
        Area;
        Mode;
        Buildings;
    end
    
    methods(Static)
        function distance = getDistance(tx_pos,rx_pos)
             distance = norm(rx_pos-tx_pos);
        end 
    end
    
    methods
         function obj = ChBulk_v2(Param)
             obj.Area = Param.area;
             obj.Mode = Param.channel.mode;
             obj.Buildings = Param.buildings;
         end
         
  
         
         function obj = traverse(obj,Stations,Users,iRound)
             eNBpos = cell2mat({Stations(:).Position}');
             userpos = cell2mat({Users(:).Position}');
             
             switch obj.Mode
                 case 'winner2'


                     % Construct anteanna array, eNB and users
                     AA(1) = winner2.AntennaArray('UCA', 1,  0.3);
                     AA(2) = winner2.AntennaArray('UCA', 1,  0.05);

                     % Use antenna config 1, and establish three sectors pr basestation
                     %eNBidx = {[1 1 1]; [1 1 1]; [1 1 1]; [1 1 1]; [1 1 1]; [1 1 1]};
                     eNBidx = num2cell(ones(length(Stations),1));
                     %eNBidx = {repmat([ones(1,3)],length(Stations),1)};
                     % For users use antenna configuration 2
                     useridx = repmat(2,1,length(Users));

                     range = max(obj.Area);

                     % Assuming one antenna port, number of links are equal to
                     % number of base stations
                     numLinks = length(Stations);


                     cfgLayout = winner2.layoutparset(useridx, eNBidx, numLinks, AA, range);
    
                     % Stations are given as 1:6 and users are given as
                     % 7:21 as seen in cfgLayout.Stations. Pairs are given
                     % by association determined at the scheduling round,
                     % thus paring should be [i;
                     % Station(i).Schedule(iRound).ueId+length(Stations)]
                     
                     for i = 1:length(Stations)
                        cfgLayout.Stations(i).Pos(1:2) = Stations(i).Position(1:2);
                     end
                     
                     for ii = 1:length(Users)
                        cfgLayout.Stations(ii+length(Stations)).Pos(1:2) = Users(ii).Position(1:2); 
                     end
                     
                     % Each link is assigned with one propagation scenario, 
                     % chosen from B4 (outdoor to indoor), C2 (Urban macro-cell) 
                     % and C4 (Urban macro outdoor to indoor). Non-line-of-sight 
                     % (NLOS) is modelled for each link.
                     
                     for i = 1:numLinks
                         cfgLayout.Pairing(:,i) = [i; Stations(i).Schedule(iRound).UeId+length(Stations)];
                     end
                     
                     cfgLayout.ScenarioVector = [11*ones(1,numLinks)]; % 6 for B4, 11 for C2 and 13 for C4
                     cfgLayout.PropagConditionVector = [zeros(1,numLinks)];  % 0 for NLOS
                        
                    numBSSect = sum(cfgLayout.NofSect);
                    numMS = length(useridx);
                    
                    % Get all BS sector and MS positions
                    BSPos = cell2mat({cfgLayout.Stations(1:numBSSect).Pos});
                    MSPos = cell2mat({cfgLayout.Stations(numBSSect+1:end).Pos});


                    for linkIdx = 1:numLinks  % Plot links
                        pairStn = cfgLayout.Pairing(:,linkIdx);
                        pairPos = cell2mat({cfgLayout.Stations(pairStn).Pos});
                        plot(pairPos(1,:), pairPos(2,:), '-.b');
                    end
                     
                    frameLen = 1600;   % Number of samples generated

                    cfgWim = winner2.wimparset;
                    cfgWim.NumTimeSamples      = frameLen;
                    cfgWim.IntraClusterDsUsed  = 'yes';
                    cfgWim.CenterFrequency     = 1.9e9;
                    cfgWim.UniformTimeSampling = 'no';
                    cfgWim.ShadowingModelUsed  = 'yes';
                    cfgWim.PathLossModelUsed   = 'yes';
                    cfgWim.RandomSeed          = 31415926;  % For repeatability
                    WINNERChan = comm.WINNER2Channel(cfgWim, cfgLayout);
                    chanInfo = info(WINNERChan)                    
                    txSig = cellfun(@(x) [ones(1,x);zeros(frameLen-1,x)], ...
                            num2cell(chanInfo.NumBSElements)', 'UniformOutput', false);

                 case 'eHATA'

                     
                    % Assume a single link per stations
                    numLinks = length(Stations);

                    freq_MHz = 1900;
                    region =  'DenseUrban'; 
                    
                    % Compute pathloss for each pair
                    for ii = 1:numLinks
                        User = Stations(ii).Schedule(iRound).UeId;
                        
                        hb_pos = eNBpos(ii,:);
                        hm_pos = userpos(ii,:);
                        % Compute elavation profile from manhattan grid
                        buildings = obj.Buildings;
                        avg_building_x = floor(sqrt((buildings(1,1)^2+buildings(1,3)^2)));
                        avg_road_x = floor(sqrt(10^2+10^2));
                        avg_sum = avg_building_x + avg_road_x;
                        % Determine estimated elavation profile
                        total_distance = obj.getDistance(hb_pos,hm_pos);
                        distance_v = 1:1:total_distance; % 1 meter resolution
                        no_buildings = floor(total_distance/(avg_building_x+avg_road_x));
                        elavation_v = zeros(1,length(distance_v));
                        randheights = randsample(buildings(:,5),no_buildings);
                        
                        
                        for i = 1:no_buildings
                            elavation_v(i*avg_sum-avg_sum+1:(avg_sum)*i) = ...
                                [zeros(1,avg_road_x) randheights(i)*ones(1,avg_building_x)]          
                        end

                        
                        figure
                        plot(distance_v,elavation_v)
                        
 
                        for pp = 1:numPaths
                            
                            
                            numPoints = elev(1)+1;
                            elev(2) = obj.getDistance(Stations(ii).Position,Users(User).Position);
                            pointRes_km = elev(2)/1e3;
                            pointElev_m = elev(3:2+numPoints);
                            d_Tx_Rx_km(pp) = (numPoints-1)*pointRes_km;
                            [LossEHMedian(pp), ~] = ExtendedHata_MedianBasicPropLoss(freq_MHz, ...
                                    d_Tx_Rx_km(pp), hb_ant_m, hm_ant_m, region);
                        end
                        
                        
                        % Mark user
                        %plot(hm_pos(1),hm_pos(2),'s','MarkerFaceColor',[0.5 0.9 0.1],'MarkerEdgeColor',[0.1 0.1 0.1],'MarkerSize',4)
                        
                        
                        % If x-coordinate of basestation is higher than
                        % that of the UE, consider all buildings with
                        % greater x-coordinates than the UE, but less than
                        % that of the BS.
%                         if hb_pos(1) > hm_pos(1)
%                            bidx = find((buildings(:,1) > hm_pos(1) | buildings(:,3) > hm_pos(1)) ...
%                                & (buildings(:,1) < hb_pos(1) | buildings(:,3) < hb_pos(1)));
%                         else
%                            bidx = find((buildings(:,1) < hm_pos(1) | buildings(:,3) < hm_pos(1)) & ...
%                                (buildings(:,1) > hb_pos(1) | buildings(:,3) > hb_pos(1))); 
%                         end
%                         
%                         % Update buildings to consider
%                         buildings = buildings(bidx,:);
%                         
%                         
%                         % Following same logic for x-coordinates as for
%                         % y-coordinates
%                         if hb_pos(2) > hm_pos(2)
%                            bidx = find((buildings(:,2) > hm_pos(2) | buildings(:,4) > hm_pos(2))...
%                                & (buildings(:,2) < hb_pos(2) | buildings(:,4) > hm_pos(2)));
%                         else
%                            bidx = find((buildings(:,2) < hm_pos(2) | buildings(:,4) < hm_pos(2))...
%                                & (buildings(:,2) > hb_pos(2) | buildings(:,4) > hb_pos(2))); 
%                         end
%                         
%                         buildings = buildings(bidx,:);
%                         
                        
                        % Mark them on plot
%                         for pp = 1:length(buildings(:,1))
%                             x0 = buildings(pp,1);
%                             y0 = buildings(pp,2);
%                             x = buildings(pp,3)-x0;
%                             y = buildings(pp,4)-y0;
%                             rectangle('Position',[x0 y0 x y],'FaceColor',[0.5 .9 .9])
%                         end
                        
%                          plot(hm_pos(1),hm_pos(2),'s','MarkerFaceColor',[0.5 0.9 0.1],'MarkerEdgeColor',[0.1 0.1 0.1],'MarkerSize',4)
%                        
                      
                        
                        
                        % Number of points between Tx & Rx
                        % TODO: compute estimate of buildings between tx
                        % and rx

                    end
                    
                    
                    % Inputs: 
% - freq_MHz    : frequency (in MHz), in the range of [1500, 3000] MHz
% - hb_ant_m    : antenna height (in meter) of the base station, 
%                 in the range of [30, 200] m. 
%                 Note, base station and Tx will be used interchangeably.
% - hm_ant_m    : antenna height (in meter) of the mobile station, 
%                 in the range of [1, 10] m.
%                 Note, mobile station and Rx will be used interchangeably.
% - region      : region of the area ('DenseUrban', 'Urban', 'Suburban')
% - elev        : an array containing elevation profile between Tx & Rx,
%                 where:
%                 elev(1) = numPoints - 1 
%                 (note, numPoints is the number of points between Tx & Rx)
%                 elev(2) = distance between points (in meters). 
%                 (thus, elev(1)-1)*elev(2)=distance between Tx & Rx)
%                 elev(3) = Tx elevation (in meters)
%                 elev(numPoints+2) = Rx elevation (in meters)
%
% Outputs:
% - LossEH      : total propagation loss (in dB)

            
                     
             end
             
         
             
             
            
             
         end
    end
    
end

