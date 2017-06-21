function a = removeZeros(a)

% 	REMOVE ZEROS is a utiliy to rmeove zeros from a matrix
%
%   Function fingerprint
%   a							->	source matrix
%
% 	a							->	output matrix

	a = a';
	a(a == 0) = [];
	a = a';

end
