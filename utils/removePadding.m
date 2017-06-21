function a = removePadding(a)

% 	REMOVE PADDING is a utiliy to rmeove padding from a storage matrix
%
%   Function fingerprint
%   a							->	source matrix
%
% 	a							->	output matrix

	a = a';
	a(a == -1) = [];
	a = a';

end
