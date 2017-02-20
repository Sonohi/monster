%	MAIN 
% 
%	numFrames			= number of LTE frames for which to run each sim
%	numSubFramesMacro	= number of subframes availbale for macro eNodeB
%	numSubFramesMicro	= number of subframes availbale for micro eNodeB
clear
close all

numFrames = 10;
numSubFramesMacro = 50;
numSubFramesMicro = 25;

macroNum = 1;
microNum = 5;
stations = zeros(macroNum + microNum, 0);

%Baseline configuration of base station 
eNb = struct;
eNb.NDLRB = numSubFramesMacro;
eNb.CellRefP = 1;
eNb.CyclicPrefix = 'Normal';
eNb.CFI = 2;
eNb.PHICHDuration = 'Normal';
eNb.Ng = 'Sixth';
eNb.NFrame = 0;
eNb.TotSubframes = 1;
eNb.OCNG = 'On';
eNb.Windowing = 0;
eNb.DuplexMode = 'FDD';

% PDSCH configuration substructure
eNb.PDSCH.TxScheme = 'Port0'; % PDSCH transmission mode 0
eNb.PDSCH.Modulation = {'QPSK'};
eNb.PDSCH.NLayers = 1;
eNb.PDSCH.Rho = -3;
eNb.PDSCH.RNTI = 1;
eNb.PDSCH.RVSeq = [0 1 2 3];
eNb.PDSCH.RV = 0;
eNb.PDSCH.NHARQProcesses = 8;
eNb.PDSCH.NTurboDecIts = 5;
eNb.PDSCH.PRBSet = (0:numSubFramesMacro-1)';
% Table A.3.3.1.1-2, TS36.101
eNb.PDSCH.TrBlkSizes = [8760 8760 8760 8760 8760 0 8760 8760 8760 8760]; 
% Table A.3.3.1.1-2, TS36.101
eNb.PDSCH.CodedTrBlkSizes = [27600 27600 27600 27600 27600 0 27600 27600 27600 27600]; 
eNb.PDSCH.CSIMode = 'PUCCH 1-0';
eNb.PDSCH.PMIMode = 'Wideband';
eNb.PDSCH.CSI = 'On';








