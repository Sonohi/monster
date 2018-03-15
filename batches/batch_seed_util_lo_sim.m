function batch_seed_util_lo_sim(seed_index, utilLo_index)

%   batch_seed_util_lo_sim
%
%   Simulation Parameters
%		seed 						-> 	simulaiton seed
%		util_lo 				->	low utility threshold

seeds = [5 8 42 79 153];
utilLowValues = [1 20 40 60];
sonohi(1);
initParam;
Param.seed = seeds(seed_index);
Param.utilLoThr = utilLowValues(utilLo_index);

% Set Log level
setpref('sonohiLog','logLevel',4)

validateParam(Param);

% Disable warnings about casting classes to struct
w = warning('off', 'all');

% Create Stations and Users
[Stations, ap, Param] = createBaseStations(Param);
Param.AreaPlot = ap;
Users = createUsers(Param);

% Create Channel scenario
Channel = ChBulk_v2(Param);

% Create channel estimator
ChannelEstimator = createChannelEstimator();

% Utilisation ranges
utilLo = Param.utilLoThr;
utilHi = Param.utilHiThr;

% Create struct to pass data to the simulation function
simData = struct('trSource', Param.trSource, 'Stations', Stations, 'Users', Users,...
	'Channel', Channel, 'ChannelEstimator', ChannelEstimator);

% if set, clean the results folder
if Param.rmResults
	removeResults();
end

% Main loop
simulate(Param, simData, utilLowValues(utilLo_index), 100);

end