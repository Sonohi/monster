function batchUsers(usersIndex)

%   batchUsers
%
%   Simulation Parameters
%		usersIndex				->	users index

numUsers = [10 30 60 90];
initParam;
Param.numUsers = numUsers(usersIndex);

validateParam(Param);

% Disable warnings about casting classes to struct
w = warning('off', 'all');

% Create Stations and Users
[Stations, Param] = createBaseStations(Param);

Users = createUsers(Param);
[Users, TrafficGenerators] = trafficGeneratorBulk(Users, Param);

% Create Channel scenario
Channel = ChBulk_v2(Param);

% Create channel estimator
ChannelEstimator = createChannelEstimator();

% Utilisation ranges
utilLo = Param.utilLoThr;
utilHi = Param.utilHiThr;

% Create struct to pass data to the simulation function
simData = struct(...
	'TrafficGenerators', TrafficGenerators,... 
	'Stations', Stations,...
	'Users', Users,...
	'Channel', Channel,... 
	'ChannelEstimator', ChannelEstimator);

% Main loop
simulate(Param, simData, utilLo, utilHi);

end