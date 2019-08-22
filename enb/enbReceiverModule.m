classdef enbReceiverModule < matlab.mixin.Copyable
	properties
		NoiseFigure;
		UeData;
		RxPwdBm;
		ReceivedSignals; %Cells containing: waveform(s) from a user, and userID
		Waveform;
		Waveforms;
	end
	
	properties (Access=private)
		enbObj; % Parent object
	end

	methods
		
		function obj = enbReceiverModule(enb, Config)
			obj.enbObj = enb;
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
			obj.ReceivedSignals{id} = struct('Waveform', [], 'WaveformInfo', [], 'RxPwdBm', [], 'SNR', [], 'PathFilters', [], 'PathGains', []);
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

				% This will break with MIMO

				obj.Waveform = zeros(max(waveformLengths),1);

				for iUser = 1:length(uniqueUes)
					ueId = uniqueUes(iUser);
					% Add waveform with corresponding power
					obj.Waveforms(iUser,:) = setPower(obj.ReceivedSignals{ueId}.Waveform, obj.ReceivedSignals{ueId}.RxPwdBm);
				end

				% Create finalized waveform
				obj.Waveform = sum(obj.Waveforms, 1).';

				% Waveform is transposed due to the SCFDMA demodulator requiring a column vector.
			end
		end

		function obj = set.UeData(obj,UeData)
			obj.UeData = UeData;
		end
		
		% Used to split the received waveform into the different portions of the different
		% UEs scheduled in the UL
		function parseWaveform(obj, enbObj)
			uniqueUes = unique([enbObj.ScheduleUL]);
			for iUser = 1:length(uniqueUes)
				ueId = uniqueUes(iUser);
				obj.UeData(iUser).UeId = ueId;
				obj.UeData(iUser).Waveform = obj.ReceivedSignals{ueId}.Waveform;
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
			for iUser = 1:length(ueObjs)
				localIndex = find([obj.UeData.UeId] == ueObjs(iUser).NCellID);
				ue = ueObjs(iUser);
				if (ue.Tx.PUSCH.Active)
					[obj.UeData(localIndex).EstChannelGrid, obj.UeData(localIndex).NoiseEst] = ...
						lteULChannelEstimate(struct(ue), cec, obj.UeData(localIndex).Subframe);
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
			obj.RxPwdBm = [];
		end
		
	end
	
	
	
end
