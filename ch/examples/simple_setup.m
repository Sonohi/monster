clear all
close all
load('SimulationParameters.mat');
Param.numMacro = 1;
Param.numMicro = 0;
Param.numUsers = 1;
Param.channel.region = 'Suburban';
Param.channel.modeDL = 'ITU1546';

% Create Stations and Users
[Station, Param.AreaPlot, Param] = createBaseStations(Param);
User = createUsers(Param);

% Create Channel scenario
Channel = ChBulk_v2(Param);


Station.Users = struct('UeId', User.NCellID, 'CQI', -1, 'RSSI', -1);
Station.ScheduleDL(1,1).UeId = User.NCellID;
User.ENodeBID = Station.NCellID;

% A full LTE frame is stored in Tx.Frame which can be used to debug and
% test.
Station.Tx.Waveform = Station.Tx.Frame;
Station.Tx.WaveformInfo =Station.Tx.FrameInfo;
Station.Tx.ReGrid = Station.Tx.FrameGrid;

% Traverse channel
Channel = Channel.setupChannelDL(Station,User);
[~, User] = Channel.traverse(Station,User,'downlink');

% Get offset
User.Rx.Offset = lteDLFrameOffset(Station, User.Rx.Waveform);

% Apply offset
User.Rx.Waveform = User.Rx.Waveform(1+User.Rx.Offset:end);

% UE reference measurements
User.Rx = User.Rx.referenceMeasurements(Station);
