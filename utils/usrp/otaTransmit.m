% Simple utility to pilot a USRP B210 to send out a waveform

% Load enb and generate LTE signal
load('utils/usrp/macroEnb.mat', 'enb');
[frameWaveform, waveformInfo] = lteOFDMModulate(enb, enb.Frame);

% Connect to Radio

radioFound = false;
radiolist = findsdru;
for i = 1:length(radiolist)
  if strcmp(radiolist(i).Status, 'Success')
    if strcmp(radiolist(i).Platform, 'B210')
        radio = comm.SDRuTransmitter('Platform','B210', ...
                 'SerialNum', radiolist(i).SerialNum);
        radio.MasterClockRate = waveformInfo.SamplingRate * 4; % Need to exceed 5 MHz minimum
				radio.InterpolationFactor = 4;      % Sampling rate is 1.92 MHz
        radioFound = true;
        break;
    end
   end
end

if ~radioFound
    error(message('SONOHI: no radio found'));
end

radio.ChannelMapping = 1;     % Use both TX channels
radio.CenterFrequency = 2.6e9;
radio.Gain = 100;
radio.UnderrunOutputPort = true;

% Scale signal to make maximum magnitude equal to 1
frameWaveform = frameWaveform/max(abs(frameWaveform(:)));

% Reshape signal as a 3D array to simplify the for loop below
% Each call to step method of the object will use a 1-column matrix
samplesPerFrame = 10e-3*waveformInfo.SamplingRate;      
numFrames = length(frameWaveform)/samplesPerFrame;
% TODO revise reshaping
% txFrame = permute(reshape(permute(frameWaveform,[1 3 2]), ...
%                   samplesPerFrame,numFrames,enb.CellRefP),[1 3 2]);
txFrame = frameWaveform;

disp('Starting transmission');
disp('Please run otaTransmit.m in a new MATLAB session');

currentTime = 0;
while currentTime < 300                        
    for n = 1:numFrames
        % Call step method to send a two-column matrix
        % First column for TX channel 1. Second column for TX channel 2
        bufferUnderflow = step(radio,txFrame(:,:,n));
        if bufferUnderflow~=0
            warning('SONHOI:otaTransmit','Dropped samples')
        end
    end
    currentTime = currentTime+numFrames*10e-3; % One frame is 10 ms
end
release(radio);
disp('Transmission finished')

