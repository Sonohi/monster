% Sonohi initialization script
% Adds libriaries of sonohi to the MATLAB path.


function sonohi(varargin)

mlock; % Protect function against clear
persistent OHI; if isempty(OHI), OHI = false; end % Initialize OHI on creation
resetFlag = false;
if nargin > 0
	resetFlag=varargin{1};
end
if resetFlag
	restoredefaultpath
end

if ~OHI || resetFlag % Check if previous initialization was successful
	root = mfilename('fullpath');
	root = root(1:find(root==filesep,1,'last')-1); % Get directory of this file
	setpref('sonohi','sonohiRootFolder',root);
	
	
	fprintf(1,'Initializing Sonohi. Adding directories to path:\n');
	fprintf('-> %s\n',root);

	if isunix
	 	addpath(genpath('./'))
	end

	addpath(root);
	
	dirs = {'utils', 'ch', 'enb', 'mac', 'mobility', 'phy', 'power', ...
		'results', 'rlc', 'setup', 'traffic', 'ue', 'validator', 'app', 'logs', 'batches', 'layout'};
	
	for i=1:numel(dirs)
		add = [root filesep dirs{i}];
		fprintf('-> %s\\*\n',add);
		addpath(genpath(add));
	end
	
	if verLessThan('matlab', '8.1.0')
		fprintf(1, 'Adding compatibility layer for MATLAB releases before 8.1.0 (R2013a).\n');
		addpath(genpath(fullfile(root, 'compatibility', '8.1')));
	end
	
	if verLessThan('matlab', '8.5.0')
		fprintf(1, 'Adding compatibility layer for MATLAB releases before 8.5.0 (R2015a).\n');
		addpath(genpath(fullfile(root, 'compatibility', '8.5')));
	end
	
	
	% Disable warnings
	warning('off','catstruct:DuplicatesFound');
	
	OHI = true;
end
