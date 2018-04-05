function batch_util_users_sim(util_index, users_index)

%   batch_seed_users_sim
%
%   Simulation Parameters
%		util_index 				-> 	utilisation low thr
%		users_index				->	users index

utilValues = [1 20 40 60];
numUsers = [15 30 60];
sonohi(1);
initParam;
Param.numUsers = numUsers(users_index);
Param.utilLoThr = utilValues(util_index);

% Set Log level
setpref('sonohiLog','logLevel',4);
logName = strcat('logs/simulation-utilLoThr_',num2str(Param.utilLoThr), '-numUsers_',num2str(Param.numUsers),'.txt'); 
setpref('sonohiLog', 'logToFile', 1);
setpref('sonohiLog', 'logFile', logName);

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
simulate(Param, simData, utilLo, utilHi);

end