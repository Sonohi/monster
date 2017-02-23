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
  dataCols=[1 2 3];
  format=[];
  for I=1:num_cols
    if any(I == dataCols)
      format = [format '%n'];
    else
      format = [format '%*n'];
    end
  end

  fid=fopen(path,'rt');

  data=textscan(fid,format,'delimiter',',')

  fclose(fid);
end
