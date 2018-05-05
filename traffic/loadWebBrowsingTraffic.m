function trSource = loadWebBrowsingTraffic(path)
%   LOAD WEB BROWSING TRAFFIC is used to get data for a web browsing traffic model
%
%   Function fingerprint
%   path      ->  path where the CSV is located
%
%   trSource   ->  matrix with frameSizes

%% Initialize variables.
delimiter = ',';
startRow = 1;
endRow = inf;

%% Format for each line of text:
%   column1: double (%f)
%	column2: double (%f)
% For more information, see the TEXTSCAN documentation.
formatSpec = '%f%f%[^\n\r]';

%% Open the text file.
fileID = fopen(path,'r','n','UTF-8');
% Skip the BOM (Byte Order Mark).
fseek(fileID, 3, 'bof');

%% Read columns of data according to the format.
% This call is based on the structure of the file used to generate this code. If an error
% occurs for a different file, try regenerating the code from the Import Tool.
dataArray = textscan(fileID, formatSpec, endRow(1)-startRow(1)+1, 'Delimiter', delimiter, 'TextType', 'string', 'EmptyValue', NaN, 'HeaderLines', startRow(1)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
for block=2:length(startRow)
	frewind(fileID);
	dataArrayBlock = textscan(fileID, formatSpec, endRow(block)-startRow(block)+1, 'Delimiter', delimiter, 'TextType', 'string', 'EmptyValue', NaN, 'HeaderLines', startRow(block)-1, 'ReturnOnError', false, 'EndOfLine', '\r\n');
	for col=1:length(dataArray)
		dataArray{col} = [dataArray{col};dataArrayBlock{col}];
	end
end

%% Close the text file.
fclose(fileID);

%% Create output variable
trSource(1:length(dataArray{1}),1) = dataArray{1};
trSource(1:length(dataArray{2}),2) = dataArray{2};

% Save to MAT file for faster access next round
save('traffic/webBrowsing.mat', 'trSource');

