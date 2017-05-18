function [modOrd] = cqi2modOrd(cqi)

%   CQI TO MODULAION ORDER is a simple mapping for the number of bits/symbol 	 
%
%   Function fingerprint
%   cqi				->  input Channel Quality Index
%
%   modOrd		-> modulation order


	if (cqi < 7)
		modOrd = 2;
	elseif (cqi > 9)
		modOrd = 4;
	else
		modOrd = 6;
	end

end
