function plotSpectrums(Users, Cells, Config, Plot)
	% plotSpectrums plots the spectrum during simulation runtime
	%
	% :param Users: Array<UserEquipment> instances
	% :param Cells: Array;EvolvedNodeB: instances
	% :param Config: MonsterConfig instance
	% :param Plot: Struct plot axes
	%
	% For each user add the spectrums to the correct subplots in Config.PHYAxes
	for user = 1:length(Users)
		SpectrumRxTag = sprintf('user%iSpectrumDL',user);
		
		axSpectrum = findall(Plot.PHYAxes,'Tag',SpectrumRxTag);
		hSpectrum = get(axSpectrum,'Children');
		
		if ~isempty(hSpectrum)
			delete(hSpectrum)
		end
		
		
		Cell = Cells([Cells.NCellID] == Users(user).NCellID);
		
		if ~isempty(Users(user).Rx.Waveform)
			Fs = Cells([Cells.NCellID] == Users(user).ENodeBID).Tx.WaveformInfo.SamplingRate;
			sig = setPower(Users(user).Rx.Waveform,Users(user).Rx.ChannelConditions.RxPwdBm);
			F = fft(sig)./length(sig);
			Fpsd = 10*log10(fftshift(abs(F).^2))+30;
			nfft=length(sig);
			f=Fs/2*[-1:2/nfft:1-2/nfft];
			
			plot(axSpectrum,f,Fpsd);
			set(axSpectrum,'Tag',SpectrumRxTag);
			title(axSpectrum,strcat('User: ',num2str(user)));
			xlabel(axSpectrum,'Hz')
			ylabel(axSpectrum,'dBm')
		end
	end
	drawnow
end
