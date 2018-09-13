function set_speed( qd_simulation_parameters, speed_kmh, sampling_rate_s )
%SET_SPEED This method can be used to automatically calculate the sample density for a given mobile speed
%
% Calling object:
%   Single object
%
% Input:
%   speed_kmh
%   speed in [km/h]
%
%   sampling_rate_s
%   channel update rate in [s]
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.


qd_simulation_parameters.samples_per_meter = 1/( speed_kmh/3.6 * sampling_rate_s);

end

