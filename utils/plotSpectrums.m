function h1 = plotSpectrums(Users,Stations)

  h1 = figure('Name','Rx Power spectrum');
  set(h1,'Position',[425 425 900 900],'WindowStyle','Docked','Visible','on');
  
  for pp = 1:length(Users)
        hs(pp)=subplot(5,3,pp);
        station = Stations([Stations.NCellID] == Users(pp).ENodeB);
        if checkUserSchedule(Users(pp),station)
          Fs = Stations([Stations.NCellID] == Users(pp).ENodeB).Tx.WaveformInfo.SamplingRate;
          sig = setPower(Users(pp).Rx.Waveform,Users(pp).Rx.RxPwdBm);
          F = fft(sig)./length(sig);
          Fpsd = 10*log10(fftshift(abs(F).^2))+30;
          nfft=length(sig);
          f=Fs/2*[-1:2/nfft:1-2/nfft];
          plot(f,Fpsd);
          title(['User: ',num2str(pp)],'Fontsize',8);
          ylabel('dBm');
          xlabel('Hz');
          ylim([min(Fpsd) max(Fpsd)])
          set(hs(pp),'FontSize',8);
        end
        

  end
end
