function resourceRoot = winner2ResourceRoot()
%WINNER2RESOURCEROOT returns path to the resources folder for WINNER II

% Copyright 2016 The MathWorks, Inc.

resourceRoot = fileparts(fileparts(fileparts( ...
    fileparts(fileparts(fileparts(fileparts(mfilename('fullpath'))))))));

end