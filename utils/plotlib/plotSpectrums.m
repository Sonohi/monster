function plotSpectrums(Users,Stations, Param)
    % For each user add the spectrums to the correct subplots in Param.PHYAxes
  for user = 1:length(Users)
        SpectrumRxTag = sprintf('user%iSpectrumDL',user);
        
        axSpectrum = findall(Param.PHYAxes,'Tag',SpectrumRxTag);
        hSpectrum = get(axSpectrum,'Children');
        
        if ~isempty(hSpectrum)
           delete(hSpectrum) 
        end
        
        
        station = Stations([Stations.NCellID] == Users(user).ENodeBID);
        if checkUserSchedule(Users(user),station)
          Fs = Stations([Stations.NCellID] == Users(user).ENodeBID).Tx.WaveformInfo.SamplingRate;
          sig = setPower(Users(user).Rx.Waveform,Users(user).Rx.RxPwdBm);
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
