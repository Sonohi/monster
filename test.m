
%% Simulate Propagation Channels
% This example shows how to simulate propagation channels. It demonstrates
% how to generate cell-specific reference signals, map them onto a resource
% grid, perform OFDM modulation, and pass the result through a fading
% channel.

%%
% Set up the cell-wide settings. Create a structure and specify the
% cell-wide settings as its fields.
enb.NDLRB = 9;
enb.CyclicPrefix = 'Normal';
enb.PHICHDuration = 'Normal';
enb.CFI = 3;
enb.Ng = 'Sixth';
enb.CellRefP = 1;
enb.NCellID = 10;
enb.NSubframe = 0;
enb.DuplexMode = 'FDD';
antennaPort = 0;

%%
% Many of the functions used in this example require a subset of the
% preceding settings specified.

%% Resource Grid and Transmission Waveform
% Generate a subframe resource grid. To create the resource grid, call the
% function |<docid:lte_ref.bt2aje2 lteDLResourceGrid>|. This function
% creates an empty resource grid for one subframe.
subframe = lteDLResourceGrid(enb);

%%
% Generate cell-specific reference symbols (CellRS). Then, map them onto
% the resource elements (REs) of a resource grid using linear indices.
cellRSsymbols = lteCellRS(enb,antennaPort);
cellRSindices = lteCellRSIndices(enb,antennaPort,{'1based'});
subframe(cellRSindices) = cellRSsymbols;

%%
% Perform OFDM modulation of the complex symbols in a subframe, |subframe|,
% using cell-wide settings structure, |enb|.
%
[txWaveform,info] = lteOFDMModulate(enb,subframe);
%%
% The first output argument, |txWaveform|, contains the transmitted OFDM
% modulated symbols. The second output argument, |info|, is a structure
% that contains details about the modulation process. The field
% |info.SamplingRate| provides the sampling rate, $R_\mathrm{sampling}$, of
% the time domain waveform:
%
% ${\displaystyle R_\mathrm{sampling}\ = \frac{30.72\;\mathrm{MHz}}{2048
% \times N_\mathrm{FFT}}},$
%
% where $N_\mathrm{FFT}$ is the size of the OFDM inverse Fourier transform
% (IFT).

%% Propagation Channel
% Construct the LTE multipath fading channel. First, set up the channel
% parameters by creating a structure, |channel|.
%
channel.Seed = 1;
channel.NRxAnts = 1;
channel.DelayProfile = 'EVA';
channel.DopplerFreq = 5;
channel.MIMOCorrelation = 'Low';
channel.SamplingRate = info.SamplingRate;
channel.InitTime = 0;
%%
% The sampling rate in the channel model, |channel.SamplingRate|, must be
% set to |info.SamplingRate| which is created by |<docid:lte_ref.bt0lmvf_1
% lteOFDMModulate>|.

%%
% Pass data through the LTE fading channel. To do so, call the function
% |<docid:lte_ref.bt3f52s lteFadingChannel>|. This function generates an
% LTE multipath fading channel, as specified in TS 36.101 [ <#16 1> ]. The
% first input argument, |txWaveform|, is an array of LTE transmitted
% samples. Each row contains the waveform samples for each of the transmit
% antennas. These waveforms are filtered with the delay profiles as
% specified in the parameter structure, |channel|.
rxWaveform = lteFadingChannel(channel,txWaveform);

%% Received Waveform
% The output argument, |rxWaveform|, is the channel output signal matrix.
% Each row corresponds to the waveform at each of the receive antennas.
% Since you have defined one receive antenna, the number of rows in the
% |rxWaveform| matrix is one.
size(rxWaveform)

%% Plot Signal Before and After Fading Channel
% Display a spectrum analyzer with before-channel and after-channel waveforms. Use SpectralAverages = 10 to reduce noise in the plotted signals
title = 'Waveform Before and After Fading Channel';
saScope = dsp.SpectrumAnalyzer('SampleRate',info.SamplingRate,'ShowLegend',true,...
    'SpectralAverages',10,'Title',title,'ChannelNames',{'Before','After'});
saScope([txWaveform,rxWaveform]);

%% References
%
% # 3GPP TS 36.101 "User Equipment (UE) radio transmission and reception".

