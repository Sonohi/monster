function [Stations] = createBaseStations (Param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   CREATE BASE Stations is used to generate a struct with the base Stations   %
%                                                                              %
%   Function fingerprint                                                       %
%   Param.numMacro      		->  number of macro eNodeBs                        %
%   Param.numSubFramesMacro	->  number of LTE subframes for macro eNodeBs      %
%   Param.numMicro      		-> 	number of micro eNodeBs                        %
%   Param.numSubFramesMacro ->  number of LTE subframes for micro eNodeBs	     %
%   buildings 							-> building position matrix                        %
%                                                                              %
%   Stations  							-> struct with all Stations details and PDSCH      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	% Initialise struct for base Stations and PDSCH in FDD duplexing mode
	Stations(Param.numMacro + Param.numMicro).DuplexMode = 'FDD';

	% Create position vectors for the macro and micro BSs
	[macroPos, microPos] = positionBaseStations(Param.numMacro, Param.numMicro, ...
		Param.buildings, Param.draw);

	for (iStation = 1: (Param.numMacro + Param.numMicro))
		% For now only 1 macro in the scenario and it's kept as first elem
		if (iStation <= Param.numMacro)
			Stations(iStation).Position = macroPos(iStation, :);
			Stations(iStation).NDLRB = Param.numSubFramesMacro;
			Stations(iStation).PDSCH.PRBSet = (0:Param.numSubFramesMacro - 1)';
		else
			Stations(iStation).Position = microPos(iStation - Param.numMacro, :);
			Stations(iStation).NDLRB = Param.numSubFramesMicro;
			Stations(iStation).PDSCH.PRBSet = (0:Param.numSubFramesMicro - 1)';
		end
		Stations(iStation).NCellID = iStation;
		Stations(iStation).CellRefP = 1;
		Stations(iStation).CyclicPrefix = 'Normal';
		Stations(iStation).CFI = 2;
		Stations(iStation).PHICHDuration = 'Normal';
		Stations(iStation).Ng = 'Sixth';
		Stations(iStation).NFrame = 0;
		Stations(iStation).TotSubframes = 1;
		Stations(iStation).OCNG = 'On';
		Stations(iStation).Windowing = 0;
		Stations(iStation).DuplexMode = 'FDD';
		Stations(iStation).OCNG = 'OFF';
		Stations(iStation).Users(1:Param.numUsers) = struct('velocity',Param.velocity,...
			'queue', struct('size', 0, 'time', 0, 'pkt', 0), 'eNodeB', 0, 'scheduled', false,...
			'ueId', 0, 'position', [0 0], 'wCqi',6);
		Stations(iStation).Schedule(1:Stations(iStation).NDLRB,1) = struct('ueId',0,...
			'mcs',0,'modOrd',0);
		Stations(iStation).rrNext = struct('ueId',0,'index',1);
		Stations(iStation).ReGrid = lteDLResourceGrid(Stations(iStation));
		Stations(iStation).TxWaveform = zeros(Stations(iStation).NDLRB * 307.2, 1);

		% PDSCH (main downlink data channel) config
		% default config overwritten by main loop
		Stations(iStation).PDSCH.TxScheme = 'Port0'; % PDSCH transmission mode 0
		Stations(iStation).PDSCH.Modulation = {'QPSK'};
		Stations(iStation).PDSCH.NLayers = 1;
		Stations(iStation).PDSCH.Rho = -3;
		Stations(iStation).PDSCH.RNTI = 1;
		Stations(iStation).PDSCH.RVSeq = [0 1 2 3];
		Stations(iStation).PDSCH.RV = 0;
		Stations(iStation).PDSCH.NHARQProcesses = 8;
		Stations(iStation).PDSCH.NTurboDecIts = 5;
		Stations(iStation).PDSCH.PRBSet = (0:Param.numSubFramesMacro-1)';
		% Table A.3.3.1.1-2, TS36.101
		Stations(iStation).PDSCH.TrBlkSizes = [8760 8760 8760 8760 8760 0 8760 8760 8760 8760];
		% Table A.3.3.1.1-2, TS36.101
		Stations(iStation).PDSCH.CodedTrBlkSizes = [27600 27600 27600 27600 27600 0 27600 27600 27600 27600];
		Stations(iStation).PDSCH.CSIMode = 'PUCCH 1-0';
		Stations(iStation).PDSCH.PMIMode = 'Wideband';
		Stations(iStation).PDSCH.CSI = 'On';
	end

end
