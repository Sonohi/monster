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
                    
                     disp('Setting up WINNER II channel model...')
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
                     % number of users scheuled in the given round
                     
                     users  = [Stations.Users];
                     numLinks = nnz(users);


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
                     
                     % For each station create pairing based on associated
                     % users.
                     nlink=1;
                     for i = 1:length(Stations)
                         for ii = 1:nnz(users(:,i))
                            cfgLayout.Pairing(:,nlink) = [i; users(ii,i)+length(Stations)];
                            nlink = nlink+1;
                         end
                     end
 
                    
                    % Loop through pairings and set Scenarios based on
                    % station type
                    
                    for i = 1:numLinks
                        
                        c_bs = Stations(cfgLayout.Pairing(1,i));
                        c_ms = Users(cfgLayout.Pairing(2,i)-length(Stations));
                        if c_bs.bsClass == 'micro'
                            cfgLayout.ScenarioVector(i) = 6; % B4 Typical urban micro-cell
                            cfgLayout.PropagConditionVector(i) = 0; %0 for NLOS
                        else
                            if obj.getDistance(c_bs.Position,c_ms.Position) < 50
                                cfgLayout.ScenarioVector(i) = 6; % B5d NLOS hotspot metropol
                                cfgLayout.PropagConditionVector(i) = 1; %1 for LOS
                            else    
                                cfgLayout.ScenarioVector(i) = 11; % C2 Typical urban macro-cell
                                cfgLayout.PropagConditionVector(i) = 0; %0 for NLOS
                            end
                        end
                        
                        
                    end
             
                     
                    %cfgLayout.ScenarioVector = [11*ones(1,numLinks)]; % 6 for B4, 11 for C2 and 13 for C4
                    %cfgLayout.PropagConditionVector = [zeros(1,numLinks)];  % 0 for NLOS
                        
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
                    
                    % Number of samples must be identical for all waveforms
                    
                    t = [Stations.WaveformInfo];
                    SamplingRates = [t.SamplingRate];
                    Nfftsize = [t.Nfft];
                    frameLen = SamplingRates./double(Nfftsize);
                    
                    if numel(unique(frameLen)) ~= 1
                        msgID = 'CH:SamplingRateNfft';
                        msg = 'Number of time samples are not identical';
                        baseException = MException(msgID,msg);
                        throw(baseException)
                    end
                    
                    
                   
                    cfgWim = winner2.wimparset;
                    cfgWim.NumTimeSamples      = frameLen(1);
                    cfgWim.IntraClusterDsUsed  = 'yes';
                    cfgWim.CenterFrequency     = 1.9e9; % 1.9 GHz
                    cfgWim.UniformTimeSampling = 'no';
                    cfgWim.ShadowingModelUsed  = 'yes';
                    cfgWim.PathLossModelUsed   = 'yes';
                    cfgWim.RandomSeed          = 31415926;  % For repeatability
                    WINNERChan = comm.WINNER2Channel(cfgWim, cfgLayout);
                    chanInfo = info(WINNERChan);                    
                    %txSig = cellfun(@(x) [ones(1,x);zeros(frameLen-1,x)], ...
                    %        num2cell(chanInfo.NumBSElements)', 'UniformOutput', false);
                    
                        
                    % Each BS transmit same waveform toward all pairings.
                    % Thus, waveform per basestation is repeated given the
                    % association
                     for i = 1:numLinks
                        txSig{i,1} = Stations(cfgLayout.Pairing(1,i)).TxWaveform;
                     end
                     
                    %txSig = 
                    
                    disp('Processing signal...')
                    rxSig = WINNERChan(txSig);
                    
                    figure
                    hold on;
                    for linkIdx = 1:numLinks
                        delay = chanInfo.ChannelFilterDelay(linkIdx);
                        stem(((0:(frameLen(1)-1))-delay)/chanInfo.SampleRate(linkIdx), ...
                            abs(rxSig{linkIdx}(:,1)));
                    end
                    maxX = max((cell2mat(cellfun(@(x) find(abs(x) < 1e-8, 1, 'first'), ...
                        rxSig.', 'UniformOutput', false)) - chanInfo.ChannelFilterDelay)./ ...
                        chanInfo.SampleRate);
                    minX = -max(chanInfo.ChannelFilterDelay./chanInfo.SampleRate);
                    xlim([minX, maxX]);
                    xlabel('Time (s)'); ylabel('Magnitude');
                    legend('Link 1', 'Link 2', 'Link 3', 'Link 4', 'Link 5', 'Link 6');
                    title('Impulse Response at First Receive Antenna');
                    

                    SA = dsp.SpectrumAnalyzer( ...
                        'Name',         'Frequency response', ...
                        'SpectrumType', 'Power density', ...
                        'SampleRate',   chanInfo.SampleRate(3), ...
                        'Title',        'Frequency Response', ...
                        'ShowLegend',   true, ...
                        'ChannelNames', {'Link 3','Link 4'});

                    SA(cell2mat(cellfun(@(x) x(:,1), rxSig(3:4,1)', 'UniformOutput', false)));

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

