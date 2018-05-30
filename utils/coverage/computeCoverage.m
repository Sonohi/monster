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

% Set station position to bottom left hand corner to ensure NLOS scenarios
% when moving diagonal
station.Position(1:2) = [0, 0];

% Use steps of 10 meters in x and y to compute approximated coverage distance
stepMeters = 10;
avgCoverageDistance = 20;
coverage = struct('distance',[],'SNRdB',[],'ChannelModel',channel.DLMode,'ChannelRegion',channel.Region);
idx = 1;
if param.draw
	cdObj = comm.ConstellationDiagram('SamplesPerSymbol', 1, ...
                                  'ShowReferenceConstellation', true, ...
                                  'ReferenceConstellation', qammod(0:3, 4, 'UnitAveragePower', 1));
end
while true
    % Set distance of user
    avgCoverageDistance = avgCoverageDistance + sqrt(stepMeters^2+stepMeters^2);
    
    % This is considered the base case (LOS) for the macro, if positioned
    % in the middle.
    % We want worst case coverage, thus we move in a x and y direction
    %sampleUser.Position = [avgCoverageDistance+station.Position(1), station.Position(2), sampleUser.Position(3)];
    sampleUser.Position = [avgCoverageDistance+station.Position(1), avgCoverageDistance+station.Position(2), sampleUser.Position(3)];
  
		% Set random seed
		channel.Seed = randi([0,9999]);
		
    % Compute impairments
    try
				[~, sampleUser] = channel.traverse(station,sampleUser,'downlink');
    catch ME
        sonohilog(sprintf('Channel error, %s',ME.message),'WRN')
        break
    end
    % Get offset
    sampleUser.Rx.Offset = lteDLFrameOffset(station, sampleUser.Rx.Waveform);

    % Apply offset
    sampleUser.Rx.Waveform = sampleUser.Rx.Waveform(1+sampleUser.Rx.Offset:end);

    % Demod waveform
		[~, sampleUser.Rx] = sampleUser.Rx.demodulateWaveform(station);
		if param.draw
			cdObj(reshape(sampleUser.Rx.Subframe,size(sampleUser.Rx.Subframe,1)* size(sampleUser.Rx.Subframe,2),1))
		end
    %plot(sampleUser.Rx.Subframe,'.')
    % UE reference measurements
    sampleUser.Rx = sampleUser.Rx.referenceMeasurements(station);
    
    coverage.distance(idx) = avgCoverageDistance;
    coverage.SNRdB(idx) = sampleUser.Rx.SNRdB;
    %sonohilog(sprintf('Distance %s', num2str(avgCoverageDistance)));
    % Check if SNR is below 3, likely means no transmission possible.
    % TODO: count errors on subframe
    if sampleUser.Rx.SNRdB <= 3
        break
		elseif idx > 5000
				error('Something went wrong in SNR convergence.')
    end
    idx = idx +1;
    drawnow
    
end



end