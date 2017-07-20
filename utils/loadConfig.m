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
			tokenList = strread(row, '%s', 'delimiter', ' '); %#ok<*DSTRRD>
			% cast and store
			switch tokenList{4}
				case 'AD' % Array of double
					param.(tokenList{1}) = str2num(tokenList{3}); %#ok<*ST2NM>
				case 'B' % Boolean
					param.(tokenList{1}) = round(str2double(tokenList{3}));
				case 'C' % Char array
					param.(tokenList{1}) = strrep(tokenList{3}, '''', '');
				case 'D' % Double
					param.(tokenList{1}) = str2double(tokenList{3});
				case 'I' % Integer
					param.(tokenList{1}) = round(str2double(tokenList{3}));
			end

			row = fgetl(fid);
		end
	end
	fclose(fid);
end
