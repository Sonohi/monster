function sweep_seed_users_sim(seed_index, users_index)

%   sweep_seed_users_sim
%
%   Simulation Parameters
%		seed_index 				-> 	simulation seed
%		users_index				->	users index

seeds = [5 8 42 79 153];
numUsers = [10 20 30 40];
sonohi(1);
initParam;
Param.seed = seeds(seed_index);
Param.numUsers = numUsers(users_index);
Param.utilLoThr = 40;

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

% create powerState mapping
powerState = [
	"active", ...
	"overload", ...
	"underload", ...
	"shutdown", ...
	"inactive", ...
	"boot"];

% Main loop
simulate(Param, simData, utilLo, utilHi);

end