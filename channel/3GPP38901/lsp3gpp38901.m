function [lsp] = lsp3gpp38901(areaType)

lsp = struct();
switch areaType
	case 'RMa'
		sigmaSFLOS = 5;
		sigmaSFNLOS = 8;
		dCorrLOS = 37;
		dCorrNLOS = 120;
		dCorrLOSprop = 60;
	case 'UMa'
		sigmaSFLOS = 4;
		sigmaSFNLOS = 6;
		dCorrLOS = 37;
		dCorrNLOS = 50;
		dCorrLOSprop = 50;
	case 'UMi'
		sigmaSFLOS = 4;
		sigmaSFNLOS = 7.82;
		dCorrLOS = 10;
		dCorrNLOS = 13;
		dCorrLOSprop = 50;
end

lsp.sigmaSFLOS = sigmaSFLOS;
lsp.sigmaSFNLOS = sigmaSFNLOS;
lsp.dCorrLOS = dCorrLOS;
lsp.dCorrNLOS = dCorrNLOS;
lsp.dCorrLOSprop = dCorrLOSprop;


end