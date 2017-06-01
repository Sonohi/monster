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
                        distance = obj.getDistance(hb_pos,hm_pos)/1e3;
                        [LossEHMedian(ii), ~] = ExtendedHata_MedianBasicPropLoss(freq_MHz, ...
                                    distance, hb_pos(3), hm_pos(3), region);
                                
                                
                        % Compute power from transmitted waveform and apply
                        % noise corresponding to the pathloss
                        
                        a = 1;
                    end
                    
                    
                    
                    
            
                     
             end
             
         
             
             
            
             
         end
    end
    
end

