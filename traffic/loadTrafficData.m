function [trSource] = loadTrafficData (path, sort)

%   LOAD TRAFFIC DATA is used to get a matrix of frame sizes
%   currently the module is limited to model video streaming with frame sizes
%   taken from the big buck bunny video
%
%   Function fingerprint
%   path      ->  path where the CSV is located
%   sort      ->  true if it has to be sorted (e.g. interleaved A/V frames)
%
%   trSource   ->  matrix with frameSizes

  %select only certain columns with relevant data
  formatSpec = '%*s%s%*s%*s%*s%s%*s%*s%*s%*s%*s%*s%*s%s%[^\n\r]';
  fileID = fopen(path,'r');
  dataArray = textscan(fileID, formatSpec, 'Delimiter', ',',  'ReturnOnError', false);
  fclose(fileID);

  raw = repmat({''},length(dataArray{1})-1,length(dataArray)-1);
  for col=1:length(dataArray)-1
  	raw(1:length(dataArray{col}),col) = dataArray{col};
  end
  numericData = NaN(size(dataArray{1},1),size(dataArray,2));

  for col=[2,3]
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


  rawNumericColumns = raw(:, [2,3]);
  % remove first and last rows in sources (labels)
  rawNumericColumns(1,:) = [];
  rawNumericColumns(length(rawNumericColumns), :) = [];

  % Replace non-numeric cells with NaN
  R = cellfun(@(x) ~isnumeric(x) && ~islogical(x),rawNumericColumns);
  rawNumericColumns(R) = {NaN};

  % Fill in output data cell
  data.time = cell2mat(rawNumericColumns(:, 1));
  data.size = cell2mat(rawNumericColumns(:, 2));
  % reshape to cell array TODO check this step
  dataCell = struct2cell(data);
  dataSize = size(dataCell);
  dataCell = reshape(dataCell, dataSize(1), []);
  trSource = cell2mat(dataCell');

  % Sort using the time column if it has to be shuffled (e.g. interleaved source)
  % first column is timestamp
  if (sort);
    trSource = sortrows(trSource, 1);
  end

  % Save to MAT file for faster access next round
  save('traffic/trafficSource.mat', 'trSource');



end
