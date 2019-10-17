function Mimo = generateMimoConfig(Config)
% Generates a MIMO configuration structure from Config parameters
%
% :param Config: MonsterConfig instance
% :return Mimo: struct with Mimo configuration
% 
	Mg = 1; % number of panels along X
	Ng = 1; % nuber of panels along Y
	M = Config.Mimo.elementsPerPanel(1); % number of elements per panel along X
	N = Config.Mimo.elementsPerPanel(2); % number of elements per panel along Y
	P = 1; % polarization

	mimo = struct(...
		arrayTuple, [Mg, Ng, M, N, P], ...
		txMode, Config.Mimo.transmissionMode,...
		numTxAntennas, Mg*Ng*M*N,...
		numRxAntennas, Mg*Ng*M*N...
		);
end