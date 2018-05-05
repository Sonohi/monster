function coverage = computeCoverage(station,channel, param)

% Setup sample user that is to be moved in order to find distance.
sampleUser = UserEquipment(param, 1);
station.Users = struct('UeId', sampleUser.NCellID, 'CQI', -1, 'RSSI', -1);
station.ScheduleDL(1,1).UeId = sampleUser.NCellID;
sampleUser.ENodeBID = station.NCellID;

% Copy full LTE frame
station.Tx.Waveform = station.Tx.Frame;
station.Tx.WaveformInfo = station.Tx.FrameInfo;
station.Tx.ReGrid = station.Tx.FrameGrid;

% Configure channel to not consider interference and fading
channel.enableFading = 0;
channel.enableInterference = 0;

% Use steps of 20 meters to compute approximated coverage distance
stepMeters = 50;
avgCoverageDistance = 0;
coverage = struct('distance',[],'SNRdB',[],'ChannelModel',channel.DLMode,'ChannelRegion',channel.Region);
idx = 1;
%figure
while true
    % Set distance of user
    avgCoverageDistance = avgCoverageDistance + stepMeters;
    sampleUser.Position = [avgCoverageDistance+station.Position(1), station.Position(2), sampleUser.Position(3)];
    
    % Compute impairments
    channel = channel.setupChannelDL(station,sampleUser);
    [~, sampleUser] = channel.traverse(station,sampleUser,'downlink');
    
    % Get offset
    sampleUser.Rx.Offset = lteDLFrameOffset(station, sampleUser.Rx.Waveform);

    % Apply offset
    sampleUser.Rx.Waveform = sampleUser.Rx.Waveform(1+sampleUser.Rx.Offset:end);

    % Demod waveform
    [~, sampleUser.Rx] = sampleUser.Rx.demodulateWaveform(station);
    %plot(sampleUser.Rx.Subframe,'.')
    % UE reference measurements
    sampleUser.Rx = sampleUser.Rx.referenceMeasurements(station);
    
    coverage.distance(idx) = avgCoverageDistance;
    coverage.SNRdB(idx) = sampleUser.Rx.SNRdB;
    % Check if SNR is below 0, likely means no transmission possible.
    % TODO: count errors on subframe
    if sampleUser.Rx.SNRdB < 3
        break 
    end
    idx = idx +1;

    
end



end