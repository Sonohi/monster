%hRSMeasurements TS36.214 Reference Signal measurements.
%   MEAS = hRSMeasurements(ENB,GRID) performs the measurements defined in
%   TS36.214 Sections 5.1.1 and 5.1.3 (Reference Signal Received Power
%   (RSRP), Received Signal Strength Indicator (RSSI) and Reference Signal
%   Received Quality (RSRQ)) on the input resource array GRID given
%   cell-wide settings structure ENB which must include the fields:
%   NDLRB           - Number of downlink resource blocks 
%   NCellID         - Physical layer cell identity
%   CellRefP        - Number of cell-specific reference signal antenna 
%                     ports (1,2,4)
%   CyclicPrefix    - Optional. Cyclic prefix length 
%                     ('Normal'(default),'Extended')
%   DuplexMode      - Optional. Duplex mode ('FDD'(default),'TDD')
%   Only required for 'TDD' duplex mode:
%       TDDConfig       - Optional. Uplink/Downlink Configuration (0...6) 
%                         (default 0)
%       SSC             - Optional. Special Subframe Configuration (0...8) 
%                         (default 0)
%       NSubframe       - Subframe number   
%
%   GRID is a 3-dimensional array of the resource elements for one or more
%   subframes across all receive antennas. GRID is an M-by-N-by-R array
%   where M is the number of subcarriers, N is the number of OFDM symbols
%   and R is the number of receive antennas. Dimension M must be 12*NDLRB
%   where NDLRB must be (6...110). Dimension N must be a multiple of number
%   of symbols in a subframe L, where L=14 for normal cyclic prefix and
%   L=12 for extended cyclic prefix.
%
%   MEAS is a structure including the fields:
%   AntennaRSRP         - The linear Reference Signal Received Power (RSRP)
%                         for each receive antenna.
%   AntennaRSSI         - The linear Received Signal Strength Indicator
%                         (RSSI) for each receive antenna.
%   AntennaRSRQ         - The linear Reference Signal Received Quality 
%                         (RSRQ) for each receive antenna.
%   RSRP                - The reported RSRP value, the maximum of the 
%                         linear RSRPs for each receive antenna, i.e. the 
%                         maximum element of AntennaRSRP.
%   RSSI                - The reported RSSI value, the RSSI of the receive 
%                         antenna with the greatest RSRQ.
%   RSRQ                - The reported RSRQ value, the maximum of the 
%                         linear RSRQs for each receive antenna, i.e. the 
%                         maximum element of AntennaRSRQ. 
%   RSRPdBm             - The RSRP expressed in deciBels relative to 1mW in
%                         1ohm. 
%   RSSIdBm             - The RSSI expressed in deciBels relative to 1mW in
%                         1ohm. 
%   RSRQdB              - The RSRQ expressed in deciBels. 
%   
%   Example:
%   perform RS measurements on an RMC R.12 waveform.
%
%   rmc = lteRMCDL('R.12');
%   rmc.TotSubframes = 1;
%   txWaveform = lteRMCDLTool(rmc,[1;0;0;1]);
%   EsdBm = -90;
%   rxWaveform = txWaveform * sqrt(10^((EsdBm-30)/10));
%   rxGrid = lteOFDMDemodulate(rmc,rxWaveform);
%   meas = hRSMeasurements(rmc,rxGrid)

%   Copyright 2011-2019 The MathWorks, Inc. 

function meas = hRSMeasurements(enb,grid)

    if (enb.CellRefP>=2)
        ports = [0 1];
    else
        ports = 0;
    end

    dims = lteResourceGridSize(enb);
    K = dims(1);
    L = dims(2);
    R = size(grid,3);
    nsf = floor(size(grid,2)/L);
    cellRSIndices = [];
    for p = 1:length(ports)
        cellRSIndices = [cellRSIndices; lteCellRSIndices(enb,ports(p))-(p-1)*K*L]; %#ok<AGROW>
    end                
    [ksubs,lsubs] = ind2sub([K L],reshape(double(cellRSIndices),[],length(ports)));
    ksubs(ksubs>K/2) = ksubs(ksubs>K/2) + 1;
    cellRSSyms = unique(lsubs(:,1));
    rssiIndices = repmat((cellRSSyms-1)*K,1,K)+repmat(1:K,length(cellRSSyms),1);
    rssiIndices = reshape(rssiIndices,numel(rssiIndices),1);
    meas.AntennaRSRP = NaN(nsf,R);    
    meas.AntennaRSSI = NaN(nsf,R);    
    meas.AntennaRSRQ = NaN(nsf,R);  
    startSubframe = enb.NSubframe;
    for n = 1:nsf
        enb.NSubframe = mod(startSubframe+n-1,10);
        duplexingInfo = lteDuplexingInfo(enb);
        if (strcmpi(duplexingInfo.SubframeType,'Downlink'))
            subframe = grid(:,((n-1)*L)+(1:L),:);
            cellRS = [];
            for p = 1:length(ports)
                cellRS = [cellRS; lteCellRS(enb,ports(p))]; %#ok<AGROW>
            end
            for r=1:R        
                subframe(:,:,r) = linearPhaseEqualize(subframe(:,:,r),cellRSIndices,cellRS,K,ksubs,lsubs);
                meas.AntennaRSRP(n,r) = abs(mean(subframe(cellRSIndices+(r-1)*K*L).*conj(cellRS))*length(ports)).^2;
                meas.AntennaRSSI(n,r) = sum(abs(subframe(rssiIndices+(r-1)*K*L).^2))/(length(cellRSSyms));   
                meas.AntennaRSRQ(n,r) = meas.AntennaRSRP(n,r)*double(enb.NDLRB)./meas.AntennaRSSI(n,r);
            end
        end
    end
    meas.AntennaRSRP = perAntennaMeanFn(meas.AntennaRSRP);
    meas.AntennaRSSI = perAntennaMeanFn(meas.AntennaRSSI);
    meas.AntennaRSRQ = perAntennaMeanFn(meas.AntennaRSRQ);
    idxRSRP = find(meas.AntennaRSRP==max(meas.AntennaRSRP),1);
    idxRSRQ = find(meas.AntennaRSRQ==max(meas.AntennaRSRQ),1);
    meas.RSRP = mean(meas.AntennaRSRP(idxRSRP));
    meas.RSSI = mean(meas.AntennaRSSI(idxRSRQ));    
    meas.RSRQ = mean(meas.AntennaRSRQ(idxRSRQ));    
    meas.RSRPdBm = 10*log10(meas.RSRP)+30;
    meas.RSSIdBm = 10*log10(meas.RSSI)+30; 
    meas.RSRQdB = 10*log10(meas.RSRQ);
    
end

function out = linearPhaseEqualize(in,cellRSIndices,cellRS,K,ksubs,lsubs)
    
    nports = size(ksubs,2);
    cellRSIndices = reshape(cellRSIndices,[],nports);
    cellRS = reshape(cellRS,[],nports);
    cellRSSyms = unique(lsubs);
    nsyms = length(cellRSSyms);
    thetapoly = zeros(nsyms*nports,2);
    rms = zeros(nsyms*nports,1);
    for p = 1:nports
        lsubsp = lsubs(:,p);
        for li = 1:nsyms
            l = cellRSSyms(li);
            theta = unwrap(angle(in(cellRSIndices(lsubsp==l,p)).*conj(cellRS(lsubsp==l,p))));
            [thetapoly(li + (p-1)*nsyms,:),s] = polyfit(ksubs(lsubsp==l,p),theta,1);
            rms(li + (p-1)*nsyms) = s.normr/sqrt(numel(theta)-1);
        end
    end
    threshold = 0.9;
    if (sum(rms<threshold)>0)
        thetapoly = mean(thetapoly(rms<threshold,:),1);
        k = [1:K/2 ((K/2)+2):(K+1)].';
        theta = polyval(thetapoly,k);
    else
        theta = 0;
    end
    out = in .* exp(-1i*theta);
    
end

function x = perAntennaMeanFn(r)

    x = arrayfun(@(p)mean(r(~isnan(r(:,p)),p)),1:size(r,2));
    x(isnan(x)) = 0;
    
end
