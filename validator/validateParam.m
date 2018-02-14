function validateParam(Param)

	%   VALIDATE PARAMETERS is used to validate the paramenters
	%
	%   Function fingerprint
	%   PAram		->  test

	validateattributes(Param, {'struct'}, {'nonempty'});
	validateattributes(Param.reset, {'numeric'}, [{'>=',0}, {'<=',1}]);
	validateattributes(Param.draw, {'numeric'}, [{'>=',0}, {'<=',1}]);
	validateattributes(Param.storeTxData, {'numeric'}, [{'>=',0}, {'<=',1}]);
	validateattributes(Param.schRounds, {'numeric'}, {'>=',0});
	validateattributes(Param.numSubFramesMacro, {'numeric'}, {'>=',0});
	validateattributes(Param.numSubFramesMicro, {'numeric'}, {'>=',0});
	validateattributes(Param.numMacro, {'numeric'}, [{'>=',0}, {'<=',1}]);
	validateattributes(Param.numMicro, {'numeric'}, {'>=',0});
	validateattributes(Param.microPos, {'char'}, {'nonempty'});
	validateattributes(Param.microUniformRadius, {'numeric'}, {'>=',0});
	validateattributes(Param.macroHeight, {'numeric'}, {'>=',0});
	validateattributes(Param.microHeight, {'numeric'}, {'>=',0});
	validateattributes(Param.ueHeight, {'numeric'}, {'>=',0});
	validateattributes(Param.buildingHeight, {'numeric'}, [{'>=',0}, {'<=',50}]);
	validateattributes(Param.seed, {'numeric'}, {'>=',0});
	validateattributes(Param.numUsers, {'numeric'}, {'>=',0});
	validateattributes(Param.utilLoThr, {'numeric'}, [{'>=',0}, {'<=',100}]);
	validateattributes(Param.utilHiThr, {'numeric'}, [{'>=',0}, {'<=',100}]);
	validateattributes(Param.ulFreq, {'numeric'}, {'>=',0});
	validateattributes(Param.dlFreq, {'numeric'}, {'>=',0});
	validateattributes(Param.maxTbSize, {'numeric'}, {'>=',0});
	validateattributes(Param.maxCwdSize, {'numeric'}, {'>=',0});
	validateattributes(Param.prbSym, {'numeric'}, {'>=',0});
	validateattributes(Param.ueNoiseFigure, {'numeric'}, {'>=',0});
	validateattributes(Param.prbRe, {'numeric'}, {'>=',0});
	validateattributes(Param.nboRadius, {'numeric'}, {'>=',0});
	validateattributes(Param.tHyst, {'numeric'}, {'>=',0});
	validateattributes(Param.tSwitch, {'numeric'}, {'>=',0});
	validateattributes(Param.rmResults, {'numeric'}, [{'>=',0}, {'<=',1}]);
	validateattributes(Param.mobilityScenario, {'char'}, {'nonempty'});
	validateattributes(Param.saveFrame, {'numeric'}, [{'>=',0}, {'<=',1}]);
	validateattributes(Param.icScheme, {'char'}, {'nonempty'});
	validateattributes(Param.generateHeatMap, {'numeric'}, [{'>=',0}, {'<=',1}]);
	validateattributes(Param.heatMapType, {'char'}, {'nonempty'});
	validateattributes(Param.heatMapRes, {'numeric'}, {'>=',0});
	validateattributes(Param.channel.modeDL, {'char'}, {'nonempty'});
	validateattributes(Param.channel.modeUL, {'char'}, {'nonempty'});
	validateattributes(Param.channel.region, {'char'}, {'nonempty'});
	validateattributes(Param.scheduling, {'char'}, {'nonempty'});
end
