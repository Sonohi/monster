function data = extractUserMetrics(ueOut,Users,Param)


for iUser = 1:length(Users)
  positions = [ueOut(1,1,:,iUser).rxPosition];
  txpositions = [ueOut(1,1,:,iUser).txPosition];
  xx = positions(1:3:end);
  yy = positions(2:3:end);
  zz = positions(3:3:end);
  xx_tx = txpositions(1:3:end);
  yy_tx = txpositions(2:3:end);
  zz_tx = txpositions(3:3:end);
  postEvm = [ueOut(1,1,:,iUser).postEvm];
  cqi = [ueOut(1,1,:,iUser).cqi];
  snr = [ueOut(1,1,:,iUser).snr];
  sinr = [ueOut(1,1,:,iUser).sinr];
  servingStation = [ueOut(1,1,:,iUser).servingStation];
  err_blocks = 0;
  for iRound = 1:Param.no_rounds
    blocks = [ueOut(1,1,iRound,iUser).blocks];
    bits = [ueOut(1,1,iRound,iUser).bits];
    bit_rate(iRound) = bits.tot/Param.round_duration;
    bler(iRound) =  blocks.err/Param.round_duration;
    ble(iRound) = blocks.err;
    err(iRound) = bits.err;
    ber(iRound) = bits.err/Param.round_duration;
    distance(iRound) = sqrt((xx_tx(iRound)-xx(iRound)).^2+(yy_tx(iRound)-yy(iRound)).^2+(zz_tx(iRound)-zz(iRound)).^2);
    
  end
  data(iUser) = struct('postEvm',postEvm,'cqi',cqi,'snr',snr,'sinr',sinr,...
    'bit_rate',bit_rate,'distance',distance,'txpos',[xx_tx;yy_tx],'rxpos',[xx; yy],...
    'bler',bler,'ble',ble,'biterr',err,'servingStation',servingStation);
end


end