function prop = losProb3gpp38901(areaType, d2d, hUt)
% Computes the LOS probability according to LOS probability using table 7.4.2-1 of 3GPP TR 38.901
prop = zeros(size(d2d));
switch areaType
	case 'RMa'
		% If the user is less than 18 meters away, set the probability to
		% 100%
		leq_10_m = (d2d <=10);
		gt_10_m =  (d2d >10);
		prop(leq_10_m)=1;
		prop(gt_10_m)= exp(-1*((d2d(gt_10_m)-10)/1000));
		
	case 'UMi'
		% If the user is less than 18 meters away, set the probability to
		% 100%
		leq_18_m = (d2d<=18);
		gt_18_m = (d2d>18);
		prop(leq_18_m)=1;
		
		% Else, base it on distance
		prop(gt_18_m)=18./d2d(gt_18_m)+ exp(-1*((d2d(gt_18_m))/36)).*(1-(18./d2d(gt_18_m)));
		
		
	case 'UMa'
		if hUt >23
			error('Error in computing LOS. Height out of range')
		end
		
		% If the user is less than 18 meters away, set the probability to 100%
		leq_18_m = (d2d<=18); % Logical indexer
		prop(leq_18_m)=1;
		
		% If the user height is below or equal to 13 meters
		leq_13_m = (prop~=1 & hUt <= 13); % Logical indexer
		prop(leq_13_m) = (18./d2d(leq_13_m) + exp(-1*((d2d(leq_13_m))/63)).*(1-(18./d2d(leq_13_m))));
		
		% If the user position is between 13 and 23 meters
		leq_13_leq_23 = (prop~=1 & hUt > 13 & hUt <= 23); % Logical indexer
		if any(any(leq_13_leq_23))
			A = (18./d2d(leq_13_leq_23) + exp(-1*((d2d(leq_13_leq_23))/63)).*(1-(18./d2d(leq_13_leq_23)))); % First part of the equation [] square brackets
			B = (1+((hUt-13)/10).^(1.5)*(5/4)*(d2d(leq_13_leq_23)/100).^3.*exp(-1*(d2d(leq_13_leq_23)/150))); % Second part, round brackets
			prop(leq_13_leq_23) = A.*B;
		end
		
	otherwise
		error('AreaType: %s not valid',areaType)
end

end