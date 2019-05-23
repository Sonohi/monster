classdef VivaldiAntenna < handle
	properties 
		Bearing;
		Pattern;
	end
% Implementation of MiWire Antenna element

methods 

	function obj = VivaldiAntenna(freq)
		obj.loadPattern(freq)
		obj.Bearing = 0;
	end

	function loadPattern(obj, freq)
		% Find pattern of given frequency
		currentPatterns = [850e6, 1800e6, 2100e6, 2400e6, 2600e6];
		threshold = 10e-3;
		distanceFrequency = abs(currentPatterns - freq);
		[~, idx] = min(distanceFrequency);
		if any(distanceFrequency <= threshold)
			FrequencyMHz = freq * 10e-7;
			fileName = sprintf('RadiationPattern%iMHz.csv', FrequencyMHz);

		else
			
			FrequencyMHz = currentPatterns(idx) * 10e-7;
			warning(sprintf('Assigned frequency offset from available radiation patterns. Selecting the one closest. %i',FrequencyMHz))
			fileName = sprintf('RadiationPattern%iMHz.csv', FrequencyMHz);
		end
		
		obj.Pattern = importPattern(fileName);
		obj.Pattern(1,1) = 360;
		obj.Pattern = circshift(obj.Pattern,-1);
	end
	
	function plotPattern(obj)
		
		figure
		plot(obj.Pattern(:,1), obj.Pattern(:,2))
		
	end
	
	function plotPattern3D(obj)
		az = obj.Pattern(:,1);
		el = -90:5:90;

		field = repmat(obj.Pattern(:,2).',length(el),1);

		phi = az';
		theta = (90-el);
		MagE = field';
		figure
		patternCustom(MagE,theta,phi);

	end

	function gain = get3DGain(obj, theta, phi)
		% Compute the radiation pattern given vertical and horizontal
		% theta = Elevation
		% phi = Azimuth
		%
		% Elevation pattern is currently unknown, thus it is kept ideal (e.g. azimuth gain)
		
		az = [obj.Pattern(:,1)-180, obj.Pattern(:,2)];
		%gainPattern = obj.Pattern(:,2);
		%[x, index] = unique(az); 
		gain = interp1(az(:,1), az(:,2), phi);

		% Normalize gain profile
		% Minimum is transformed to 0, max gain is given as the absolute value of the minimum gain
		gain = abs(min(az(:,2))) + gain ;


	end


end

end