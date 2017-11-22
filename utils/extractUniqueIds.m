function c = extractUniqueIds(a)

% 	EXTRACT UNIQUE IDS is a utility to extract unique UEs from an array
%
%   Function fingerprint
%   a							->	source array
%
% 	c							->	output array

	b = find(a ~= -1);
	c = unique(a(b));
	
end
