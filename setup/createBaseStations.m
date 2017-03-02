function [stations] = createBaseStations (param)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   CREATE BASE STATIONS is used to generate a struct with the base stations   %
%                                                                              %
%   Function fingerprint                                                       %
%   param.macroNum      		->  number of macro eNodeBs                        %
%   param.numSubFramesMacro	->  number of LTE subframes for macro eNodeBs      %
%   param.microNum      		-> 	number of micro eNodeBs                        %
%   param.numSubFramesMacro ->  number of LTE subframes for micro eNodeBs	     %
%   buildings 							-> building position matrix                        %
%                                                                              %
%   stations  							-> struct with all stations details and PDSCH      %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

	%Initialise struct for base stations and PDSCH in FDD duplexing mode
	stations(param.macroNum + param.microNum).DuplexMode = 'FDD';

	%Create position vectors for the macro and micro BSs
	[macro_pos, micro_pos] = positionBaseStations(param.macroNum, param.microNum, param.buildings);

	for i = 1: (param.macroNum + param.microNum)
		%For now only 1 macro in the scenario and it's kept as first elem
		if(i <= param.macroNum)
			stations(i).Position = macro_pos(i, :);
			stations(i).NDLRB = param.numSubFramesMacro;
			stations(i).PDSCH.PRBSet = (0:param.numSubFramesMacro - 1)';
		else
			stations(i).Position = micro_pos(i - param.macroNum, :);
			stations(i).NDLRB = param.numSubFramesMicro;
			stations(i).PDSCH.PRBSet = (0:param.numSubFramesMicro - 1)';
		end
		stations(i).NCellID = i;
		stations(i).CellRefP = 1;
		stations(i).CyclicPrefix = 'Normal';
		stations(i).CFI = 2;
		stations(i).PHICHDuration = 'Normal';
		stations(i).Ng = 'Sixth';
		stations(i).NFrame = 0;
		stations(i).TotSubframes = 1;
		stations(i).OCNG = 'On';
		stations(i).Windowing = 0;
		stations(i).DuplexMode = 'FDD';
		stations(i).OCNG = 'OFF';

		%PDSCH (main downlink data channel config
		%TODO check if this makes sense in the scenario
		stations(i).PDSCH.TxScheme = 'Port0'; % PDSCH transmission mode 0
		stations(i).PDSCH.Modulation = {'QPSK'};
		stations(i).PDSCH.NLayers = 1;
		stations(i).PDSCH.Rho = -3;
		stations(i).PDSCH.RNTI = 1;
		stations(i).PDSCH.RVSeq = [0 1 2 3];
		stations(i).PDSCH.RV = 0;
		stations(i).PDSCH.NHARQProcesses = 8;
		stations(i).PDSCH.NTurboDecIts = 5;
		stations(i).PDSCH.PRBSet = (0:param.numSubFramesMacro-1)';
		% Table A.3.3.1.1-2, TS36.101
		stations(i).PDSCH.TrBlkSizes = [8760 8760 8760 8760 8760 0 8760 8760 8760 8760];
		% Table A.3.3.1.1-2, TS36.101
		stations(i).PDSCH.CodedTrBlkSizes = [27600 27600 27600 27600 27600 0 27600 27600 27600 27600];
		stations(i).PDSCH.CSIMode = 'PUCCH 1-0';
		stations(i).PDSCH.PMIMode = 'Wideband';
		stations(i).PDSCH.CSI = 'On';
	end

end
