function [data] = getTrafficData (path)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%   GET TRAFFIC DATA is used to get a matrix of frame sizes                    %
%   currently the module is limited to model video streaming with frame sizes  %
%   taken from the big buck bunny video                                        %
%                                                                              %
%   Function fingerprint                                                       %
%   path  ->  path where the CSV is located                                    %
%                                                                              %
%   data  ->  matrix with frameSizes                                           %
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  %select only certain columns with relevant data
  formatSpec = '%*s%s%*s%*s%*s%*s%*s%*s%*s%*s%s%s%s%s%[^\n\r]';
  fileID = fopen(path,'r');
  dataArray = textscan(fileID, formatSpec, 'Delimiter', ',',  'ReturnOnError', false);
  fclose(fileID);

  raw = repmat({''},length(dataArray{1})-1,length(dataArray)-1);
  for col=1:length(dataArray)-1
  	raw(1:length(dataArray{col}),col) = dataArray{col};
  end
  numericData = NaN(size(dataArray{1},1),size(dataArray,2));

  for col=[2,3,4,5]
  	rawData = dataArray{col};
  	for row=1:size(rawData, 1);
  		regexstr = '(?<prefix>.*?)(?<numbers>([-]*(\d+[\,]*)+[\.]{0,1}\d*[eEdD]{0,1}[-+]*\d*[i]{0,1})|([-]*(\d+[\,]*)*[\.]{1,1}\d+[eEdD]{0,1}[-+]*\d*[i]{0,1}))(?<suffix>.*)';
  		try
  			result = regexp(rawData{row}, regexstr, 'names');
  			numbers = result.numbers;
  			invalidThousandsSeparator = false;
  			if any(numbers==',');
  				thousandsRegExp = '^\d+?(\,\d{3})*\.{0,1}\d*$';
  				if isempty(regexp(numbers, thousandsRegExp, 'once'));
  					numbers = NaN;
  					invalidThousandsSeparator = true;
  				end
  			end
  			if ~invalidThousandsSeparator;
  				numbers = textscan(strrep(numbers, ',', ''), '%f');
  				numericData(row, col) = numbers{1};
  				raw{row, col} = numbers{1};
  			end
  		catch me
  		end
  	end
  end


  % Split data into numeric and cell columns.
  rawNumericColumns = raw(:, [2,3,4,5]);
  rawCellColumns = raw(:, 1);
  % remove first and last rows in sources (labels)
  rawNumericColumns(1,:) = [];
  rawNumericColumns(length(rawNumericColumns), :) = [];
  rawCellColumns(1,:) = [];
  rawCellColumns(length(rawCellColumns), :) = [];

  % Replace non-numeric cells with NaN
  R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns);
  rawNumericColumns(R) = {NaN};

  % Fill in output data cell
  data.media = rawCellColumns(:, 1);
  data.duration = cell2mat(rawNumericColumns(:, 1));
  data.time = cell2mat(rawNumericColumns(:, 2));
  data.pos = cell2mat(rawNumericColumns(:, 3));
  data.size = cell2mat(rawNumericColumns(:, 4));


end
