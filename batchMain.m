%Set Log level
setpref('sonohiLog','logLevel',4);
dateStr = datestr(datetime, 'yyyy-mm-dd_HH.MM.SS');
logName = strcat('logs/', dateStr,'.txt'); 
setpref('sonohiLog', 'logToFile', 1);
setpref('sonohiLog', 'logFile', logName);

parfor i = 1:4
	try
		batchUsers(i);
	catch ME
		sonohilog(sprintf('(BATCH MAIN) Error in batch for simulation index %i', i),'WRN');
		sonohilog(ME.stack);
	end			
end