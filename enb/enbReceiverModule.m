classdef enbReceiverModule
	properties
		NoiseFigure;
		Waveform;
		UeData;
	end

	methods

		function obj = enbReceiverModule(Param)
			obj.NoiseFigure = Param.bsNoiseFigure;
		end

		function obj = set.Waveform(obj,Sig)
			obj.Waveform = Sig;
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
		function obj = demodulate(obj, ueObjs)
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

		function obj = estimateChannel(obj, enbObj, cec)
		
		end

		function obj = equalise(obj, enbObj)
		
		end

		function obj = estimatePucch(obj, enbObj, timeNow)
		
		end

	end



end
