function install(reInstallFlag)
% install - adds the directories for the simulation to the path
%
% Syntax: install(reInstallFlag)
% :reInstallFlag: (boolean) when true the folders are re-installed

% Protect function against clear
mlock; 
persistent MONSTER; 
% Initialize MONSTER on creation
if isempty(MONSTER)
	MONSTER = false; 
end 

if reInstallFlag
	restoredefaultpath
end

% Check if previous initialization was successful
if ~MONSTER || reInstallFlag 
	root = mfilename('fullpath');
	% Get directory of this file
	root = root(1:find(root==filesep,1,'last')-1); 
	setpref('monster','monsterRootFolder',root);
	
	
	fprintf(1,'(MONSTER - install) Adding directories to path:\n');
	fprintf('-> %s\n',root);

	if isunix
	 	addpath(genpath('./'))
	end

	addpath(root);
	
	dirs = {'utils', 'ch', 'enb', 'mac', 'mobility', 'phy', 'power', 'results', 'rlc', ...
		'setup', 'traffic', 'ue', 'validator', 'app', 'logs', 'batches'};
	
	for i=1:numel(dirs)
		add = [root filesep dirs{i}];
		fprintf('-> %s\\*\n',add);
		addpath(genpath(add));
	end
	
	if verLessThan('matlab', '8.1.0')
		fprintf(1, '(MONSTER - install) Adding compatibility layer for MATLAB releases before 8.1.0 (R2013a).\n');
		addpath(genpath(fullfile(root, 'compatibility', '8.1')));
	end
	
	if verLessThan('matlab', '8.5.0')
		fprintf(1, '(MONSTER - install) Adding compatibility layer for MATLAB releases before 8.5.0 (R2015a).\n');
		addpath(genpath(fullfile(root, 'compatibility', '8.5')));
	end
	
	
	% Disable warnings
	warning('off','catstruct:DuplicatesFound');
	
	MONSTER = true;
end
end
