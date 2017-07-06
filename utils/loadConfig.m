function param = loadConfig(path)

%   LOAD CONFIGURATION is used to laod the config file in a struct
%
%   Function fingerprint
%   path		->  path for the config file
%
%   param		->  parameters structure

	fid = fopen(path);
	row = fgetl(fid);
	while ischar(row)
		if isempty(row) || row(1) == '%'
			row = fgetl(fid);
		else
			% parse the row into an array
			tokenList = strread(row, '%s', 'delimiter', ' ');
			% store to cell and then struct
			param.(tokenList{1}) = tokenList{3};
			row = fgetl(fid);
		end
	end
end
