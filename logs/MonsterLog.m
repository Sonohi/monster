classdef MonsterLog < matlab.mixin.Copyable
	% Defines a logger for a simulation
	%
	% :level: (string) the desired log level
	% 

	properties
		level = 'NFO';
		logLevelTypeIdx;
		validLogLevelValues;
		textColors = {[1 0 0], [1, 0.5, 0], [0 0.7 1],[0 0 0], [0 0.7 1]};
		logToFile = false;
		logFile = 'monster.log'
		logInBlack = 0;
	end

	methods
		function obj = MonsterLog(Config)
			% MonsterLog constructor 
			% 
			% :param Config: MonsterConfig instance
			% :returns obj: MonsterLog instance
			%
			obj.validLogLevelValues = {'ERR', 'WRN', 'DBG', 'NFO', 'NFO0'};
			
			% Check preferences for log level
			[isLogLevelValid, logLevelTypeIdx] = ismember(Config.Logs.logLevel, obj.validLogLevelValues);
			if ~isLogLevelValid
				error('Monster log level must be one of ERR, WRN, DBG, NFO, NFO0');
			else 
				obj.level = Config.Logs.logLevel;
				obj.logLevelTypeIdx = logLevelTypeIdx;
			end

			% Check preferences for log to file
			obj.logToFile = Config.Logs.logToFile;
			obj.logFile = Config.Logs.logFile;

			% Check preferences for colours
			obj.logInBlack = Config.Logs.logInBlack;

		end

		function obj = log(obj, msg, varargin)
			% Logs a message based on the settings
			% 
			% :param obj: MonsterLog instance
			% :param msg: log message
			% :param varargin: arguments
			
			
			% Check if the message log level is valid, otherwise assume NFO level
			isMsgLogLevelValid=0;
			if nargin > 1 && ischar(varargin{1})
				[isMsgLogLevelValid, msgLogLevelIdx] = ismember(varargin{1}, obj.validLogLevelValues);
				if isMsgLogLevelValid
					msgLogLevel = varargin{1};
					argIdx = 2;
					if strcmp(msgLogLevel,'ERR')
						try
							errType = varargin{2};
						catch ME
							errType = 'Monster:unspecified';
						end
					end
				end
			end

			if nargin == 1 || ~isMsgLogLevelValid
				msgLogLevel = 'NFO';
				msgLogLevelIdx = find(strcmp(obj.validLogLevelValues, msgLogLevel));
				argIdx = 1;
			end

			% If the msg log level is above the one set in the config, do not log
			if msgLogLevelIdx > obj.logLevelTypeIdx
				return
			end

			%Get the name of the caller function
			db = dbstack(1);
			if ~isempty(db)
				callerName = strsplit(db(1).name, '.');
				callerName = callerName(1);
				callerName = callerName{:};
			else
				% the caller is a script not a function
				callerName='main';
			end

			% if caller is unit, rather use the actual unit
			if strcmpi(callerName,'unit')
				callerName = evalin('caller','class(obj)');
			end

			%Double escape % and \ because we call sprintf twice
			msg = strrep(msg, '%%', '%%%%');
			msg = strrep(msg, '\\', '\\\\');

			%Perform the logging
			%If we have more than one arguments, all the arguments from the argidx are
			%parameters for printf
			if nargin > 1
				%What is passed as string argument to robolog (%s) should be treated as string
				%but since we are passing it into sprintf twice we need to escape % and \\.
				%There cannot be escape sequences into the string arguments.
				idx = cellfun(@isstr, varargin);
				varargin(idx) = strrep(varargin(idx), '%', '%%');
				varargin(idx) = strrep(varargin(idx), '\', '\\');
				msg=sprintf(['%s\tIn %s: ', msg], msgLogLevel, callerName, varargin{argIdx:end});
			else
					msg=sprintf(['%s\tIn %s: ', msg], msgLogLevel, callerName);
			end

			%Detect newlines and align subsequent lines vertically to the first one by adding spaces
			prefixLength = 16;
			spacedNewLine = ['\n' repmat(' ', 1, prefixLength + length(callerName))];
			logMsg = strrep(msg, sprintf('\n'), spacedNewLine);
			logMsg = [logMsg '\n'];

			%If we need to log to file, we open it in append mode
			if obj.logToFile
				fileId = fopen(obj.logFile, 'a');
				fprintf(fileId, logMsg);
				fclose(fileId);
			end

			%If the log type is an error, launch an error and break the code execution
			if strcmp(msgLogLevel, 'ERR')
				me = MException(errType, logMsg);
				throwAsCaller(me);
			elseif obj.logToFile == 2 || obj.logToFile == 0
				% Log to console if logToFile is 0 or 2 (log both on file and terminal)
				if strcmp(msgLogLevel, 'NFO') || obj.logInBlack
					fprintf(1, logMsg);
				else
					cprintf(obj.textColors{msgLogLevelIdx}, logMsg);
				end
			end

		end
	end
end