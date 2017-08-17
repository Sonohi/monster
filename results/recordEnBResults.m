function [res, resStore] = recordEnBResults(Stations, resStore, res, ix)

%   RECORD eNodeB RESULTS records eNodeB-space results
%
%   Function fingerprint
%   Stations		->  eNodeBs list
%   res					->  results data structure
%   ix					->  index of scheduling round

% 	res					-> updeted results
% 	resStore		-> cleaned temporary store

for iStation = 1:length(Stations)
	res(ix + 1, iStation) = struct(...
		'util', resStore(iStation).util,...
		'power', resStore(iStation).power, ...
		'schedule', resStore(iStation).schedule);
end
resStore = [];
end
