classdef enbReceiverModule < matlab.mixin.Copyable
	properties
		NoiseFigure;
		UeData;
		RxPwdBm;
		ReceivedSignals; %Cells containing: waveform(s) from a user, and userID
		Waveform;
		Waveforms;
		Mimo;
	end
	
	properties (Access=private)
		enbObj; % Parent object
	end

	methods
		
		function obj = enbReceiverModule(enb, Config)
			obj.enbObj = enb;
			obj.Mimo = enb.Mimo;
			switch enb.BsClass
				case 'macro'
					obj.NoiseFigure = Config.MacroEnb.noiseFigure;
				case 'micro'
					obj.NoiseFigure = Config.MicroEnb.noiseFigure;
				otherwise
					obj.enbObj.Logger.log(sprintf('(ENODEB RECEIVER - constructor) eNodeB %i has an invalid class %s', enb.NCellID, enb.BsClass), 'ERR');
			end
			obj.ReceivedSignals = cell(Config.Ue.number,1);
		end
		
		function createRecievedSignalStruct(obj, id)
			obj.ReceivedSignals{id} = struct('Waveform', [], 'WaveformInfo', [],'RxPw', [], 'RxPwdBm', [], 'SNR', [], 'SNRdB', [], 'SINR', [], 'SINRdB', [], 'PathFilters', [], 'PathGains', []);
		end

		function obj = setWaveform(obj, id, Waveform, WaveformInfo)
			obj.ReceivedSignals{id}.Waveform = Waveform;
			obj.ReceivedSignals{id}.WaveformInfo = WaveformInfo;
		end

		function obj = setRxPw(obj, id, RxPw)
			obj.ReceivedSignals{id}.RxPw = RxPw;
			obj.ReceivedSignals{id}.RxPwdBm = 10*log10(RxPw)+30;
		end

		function obj = setSNR(obj, id, SNR)
			obj.ReceivedSignals{id}.SNR = SNR;
			obj.ReceivedSignals{id}.SNRdB = 10*log10(SNR);
		end

		function obj = setSINR(obj, id, SINR)
			obj.ReceivedSignals{id}.SINR = SINR;
			obj.ReceivedSignals{id}.SINRdB = 10*log10(SINR);
		end

		function obj = setPathConditions(obj, id, PathGains, PathFilters)
			obj.ReceivedSignals{id}.PathGains = PathGains;
			obj.ReceivedSignals{id}.PathFilters = PathFilters;
		end

		function foundSignals = anyReceivedSignals(obj)
			numberOfUsers = length(obj.ReceivedSignals);
			foundSignals = false;
			for iUser = 1:numberOfUsers
				if isempty(obj.ReceivedSignals{iUser})
					continue
				end
				
				if isempty(obj.ReceivedSignals{iUser}.Waveform)
					continue
				end
				
				foundSignals = true;
			end
		end

		function createReceivedSignal(obj)
			uniqueUes = obj.enbObj.getUserIDsScheduledUL();
			
			if ~isempty(uniqueUes)
				
				% Check length of each received signal
				for iUser = 1:length(uniqueUes)
					ueId = uniqueUes(iUser);
					waveformLengths(iUser) =  length(obj.ReceivedSignals{ueId}.Waveform);
				end

				obj.Waveform = zeros(max(waveformLengths), obj.Mimo.numRxAntennas);

				for iUser = 1:length(uniqueUes)
					ueId = uniqueUes(iUser);
					% Add waveform with corresponding power
					ueWaveform = setPower(obj.ReceivedSignals{ueId}.Waveform, obj.ReceivedSignals{ueId}.RxPwdBm);
					% Depending on the MIMO configuration, the ueWaveform can be 1 or 2 dimensional
					if obj.Mimo.numRxAntennas > 1
						obj.Waveforms(iUser,:, :) = ueWaveform;
					else
						obj.Waveforms(iUser, :) = ueWaveform;
					end
				end

				% Create finalized waveform
				compositeWaveform = sum(obj.Waveforms, 1);
				
				% Waveform is transposed due to the SCFDMA demodulator requiring a column vector.
				if obj.Mimo.numRxAntennas > 1
					obj.Waveform(1:max(waveformLengths), 1: obj.Mimo.numRxAntennas) = compositeWaveform(1, :, :).';
				else
					obj.Waveform = compositeWaveform.';
				end
			end
		end
		
		% Used to split the received waveform into the different portions of the different
		% UEs scheduled in the UL
		function parseWaveform(obj)
			uniqueUes = unique([obj.enbObj.getUserIDsScheduledUL()]);
			for iUser = 1:length(uniqueUes)
				ueId = uniqueUes(iUser);
				obj.UeData(iUser).UeId = ueId;
				obj.UeData(iUser).Waveform = obj.ReceivedSignals{ueId}.Waveform;
				obj.UeData(iUser).PathGains = obj.ReceivedSignals{ueId}.PathGains;
				obj.UeData(iUser).PathFilters = obj.ReceivedSignals{ueId}.PathFilters;
			end
		end
		
		
		% Used to demodulate each single UE waveform separately
		function obj = demodulateWaveforms(obj, ueObjs)
			for iUser = 1:length(ueObjs)
				localIndex = find([obj.UeData.UeId] == ueObjs(iUser).NCellID);
				ue = struct(ueObjs(iUser));
				
				testSubframe = lteSCFDMADemodulate(ue, obj.UeData(localIndex).Waveform);
				
				if all(testSubframe(:) == 0)
					obj.UeData(localIndex).Subframe = [];
					obj.UeData(localIndex).DemodBool = 0;
				else
					obj.UeData(localIndex).Subframe = testSubframe;
					obj.UeData(localIndex).DemodBool = 1;
				end
			end
			
		end
		
		function obj = estimateChannels(obj, ueObjs, cec)
			
			if isempty(obj.UeData)
				obj.enbObj.Logger.log('No UE Data to estimate channels on','ERR','MonstereNBReceiverModule:NoWaveformParsed');
			end
			
			for iUser = 1:length(ueObjs)
				localIndex = find([obj.UeData.UeId] == ueObjs(iUser).NCellID);
				ue = ueObjs(iUser);
				if (ue.Tx.PUSCH.Active)
					[obj.UeData(localIndex).EstChannelGrid, obj.UeData(localIndex).NoiseEst] = ...
						lteULChannelEstimate(struct(ue), struct(ue).PUSCH, cec, obj.UeData(localIndex).Subframe, ue.Tx.Ref.Grid);
					[obj.UeData(localIndex).perfectChannelEst] = nrPerfectChannelEstimate(obj.UeData(localIndex).PathGains, obj.UeData(localIndex).PathFilters, ue.NULRB, 15, 0);
				end
			end
		end
		
		function obj = equaliseSubframes(obj, ueObjs)
			for iUser = 1:length(ueObjs)
				localIndex = find([obj.UeData.UeId] == ueObjs(iUser).NCellID);
				ue = ueObjs(iUser);
				if (ue.Tx.PUSCH.Active)
					obj.UeData(localIndex).EqSubframe = lteEqualizeMMSE(obj.UeData(localIndex).Subframe,...
						obj.UeData(localIndex).EstChannelGrid, obj.UeData(localIndex).NoiseEst);
				end
			end
		end
		
		function obj = estimatePucch(obj, enbObj, ueObjs, timeNow)
			for iUser = 1:length(ueObjs)
				localIndex = find([obj.UeData.UeId] == ueObjs(iUser).NCellID);
				ue = ueObjs(iUser);
				
				switch ue.Tx.PUCCH.Format
					case 1
						obj.UeData(localIndex).PUCCH = ltePUCCH1Decode(struct(ue), ue.Tx.PUCCH, 0, ...
							obj.UeData(localIndex).Subframe(ue.Tx.PUCCH.Indices));
					case 2
						obj.UeData(localIndex).PUCCH = ltePUCCH2Decode(struct(ue), ue.Tx.PUCCH, ...
							obj.UeData(localIndex).Subframe(ue.Tx.PUCCH.Indices));
					case 3
						obj.UeData(localIndex).PUCCH = ltePUCCH3Decode(struct(ue), ue.Tx.PUCCH, ...
							obj.UeData(localIndex).Subframe(ue.Tx.PUCCH.Indices));
				end
				
				% Estimate soft bits to hard bits
				% TODO this feels a bit dumb, let's try something smarter
				for iSym = 1:length(obj.UeData(localIndex).PUCCH)
					if obj.UeData(localIndex).PUCCH(iSym) > 0
						obj.UeData(localIndex).PUCCH(iSym) = int8(1);
					else
						obj.UeData(localIndex).PUCCH(iSym) = int8(0);
					end
				end
				
			end
		end

		
		function obj = estimatePusch(obj, enbObj, ueObjs, timeNow)
			for iUser = 1:length(ueObjs)
				localIndex = find([obj.UeData.UeId] == ueObjs(iUser).NCellID);
				ue = ueObjs(iUser);
				if (ue.Tx.PUSCH.Active)
					
				end
			end
		end

		function obj = reset(obj)
			obj.UeData = [];
			obj.Waveform = [];
			obj.Waveforms = [];
			obj.RxPwdBm = [];
			obj.ReceivedSignals = cell(length(obj.ReceivedSignals),1);
		end
		
	end
	
	
	
end
