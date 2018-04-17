classdef enbReceiverModule
	properties
		NoiseFigure;
		Waveform;
		UeData;
		RxPwdBm;
	end
	
	methods
		
		function obj = enbReceiverModule(Param)
			obj.NoiseFigure = Param.eNBNoiseFigure;
		end
		
		function obj = set.Waveform(obj,Sig)
			obj.Waveform = Sig;
		end
		
		function obj = set.RxPwdBm(obj,RxPwdBm)
			obj.RxPwdBm = RxPwdBm;
		end

		function obj = set.UeData(obj,UeData)
			obj.UeData = UeData;
		end
		
		% Used to split the received waveform into the different portions of the different
		% UEs scheduled in the UL
		function obj = parseWaveform(obj, enbObj)
			uniqueUes = unique([enbObj.ScheduleUL]);
			scFraction = length(obj.Waveform)/length(uniqueUes);
			for iUser = 1:length(uniqueUes)
				scStart = (iUser - 1)*scFraction ;
				scEnd = scStart + scFraction;
				obj.UeData(iUser).UeId = uniqueUes(iUser);
				obj.UeData(iUser).Waveform = obj.Waveform(scStart + 1 : scEnd, 1);
			end
		end
		
		% Used to demodulate each single UE waveform separately
		function obj = demodulateWaveforms(obj, ueObjs)
			for iUser = 1:length(ueObjs)
				localIndex = find([obj.UeData.UeId] == ueObjs(iUser).NCellID);
				ue = cast2Struct(ueObjs(iUser));
				
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
				ue = cast2Struct(ueObjs(iUser));
				if (ue.Tx.PUSCH.Active)
					[obj.UeData(localIndex).EstChannelGrid, obj.UeData(localIndex).NoiseEst] = ...
						lteULChannelEstimate(ue, cec, obj.UeData(localIndex).Subframe);
				end
			end
		end
		
		function obj = equaliseSubframes(obj, ueObjs)
			for iUser = 1:length(ueObjs)
				localIndex = find([obj.UeData.UeId] == ueObjs(iUser).NCellID);
				ue = cast2Struct(ueObjs(iUser));
				if (ue.Tx.PUSCH.Active)
					obj.UeData(localIndex).EqSubframe = lteEqualizeMMSE(obj.UeData(localIndex).Subframe,...
						obj.UeData(localIndex).EstChannelGrid, obj.UeData(localIndex).NoiseEst);
				end
			end
		end
		
		function obj = estimatePucch(obj, enbObj, ueObjs, timeNow)
			for iUser = 1:length(ueObjs)
				localIndex = find([obj.UeData.UeId] == ueObjs(iUser).NCellID);
				ue = cast2Struct(ueObjs(iUser));
				
				switch ue.Tx.PUCCH.Format
					case 1
						obj.UeData(localIndex).PUCCH = ltePUCCH1Decode(ue, ue.Tx.PUCCH, 0, ...
							obj.UeData(localIndex).Subframe(ue.Tx.PUCCH.Indices));
					case 2
						obj.UeData(localIndex).PUCCH = ltePUCCH2Decode(ue, ue.Tx.PUCCH, ...
							obj.UeData(localIndex).Subframe(ue.Tx.PUCCH.Indices));
					case 3
						obj.UeData(localIndex).PUCCH = ltePUCCH3Decode(ue, ue.Tx.PUCCH, ...
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
				ue = cast2Struct(ueObjs(iUser));
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
