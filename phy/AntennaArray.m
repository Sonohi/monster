classdef AntennaArray < handle
    % Implementation of Antenna Array configuration pr. ITU M.2412/3GPP 38.901
    % Copyright Jakob Thrane/DTU 2018
    properties
        Panels;
        ElementsPerPanel
        Polarizations;
        Bearing;
        Tilt;
				Type; % 3GPP38901, Omni
    end
    
    properties (Access = private)
        HEspacing; % Horizontal antenna element spacing
        VEspacing; % Vertical antenna element spacing
    end
    
    methods
        function obj = AntennaArray(type)

						obj.Type = type;
						switch type
							case '3GPP38901'
								obj.config3gpp38901()
							case 'Omni'
								obj.configOmniDirectional()
						end
						


				end
				
				function configOmniDirectional(obj)
					% Omni directional antenna
					% arrayTuple defines structure of array in accordance with 3GPP
					% 38.901. (Mg, Ng, M, N, P). Where
					% Mg x Ng = Number of panels in rectangular grid
					% M x N = Number of elements per panel in rectangular grid
					% P = Number of polarizations per element. 
					arrayTuple = [1, 1, 1, 1, 1];
					obj.Panels = cell((arrayTuple(1)*arrayTuple(2)),1);
				end

				function config3gpp38901(obj)
					% arrayTuple defines structure of array in accordance with 3GPP
					% 38.901. (Mg, Ng, M, N, P). Where
					% Mg x Ng = Number of panels in rectangular grid
					% M x N = Number of elements per panel in rectangular grid
					% P = Number of polarizations per element.
					arrayTuple = [1, 1, 1, 1, 1];
					bearing = 30;
					tilt = 102;
					obj.Panels = cell((arrayTuple(1)*arrayTuple(2)),1);
					obj.ElementsPerPanel = arrayTuple(3:4);
					obj.Polarizations = arrayTuple(5);
					obj.Bearing = bearing;
					obj.Tilt = tilt;
					for iPanel = 1:length(obj.Panels)
						obj.Panels{iPanel} = obj.constructAntennaElements();
					end
				end
        
				function plotBearing(obj, Position, Color)
					alpha = deg2rad(obj.Bearing+90);
					L = 500;
					x = Position(1);
					y = Position(2);
					x2=x+(L*cos(alpha));
					y2=y+(L*sin(alpha));
					arrow([x y],[x2 y2], 'EdgeColor',Color, 'FaceColor',Color)
				end
				
        function antennaElements = constructAntennaElements(obj)
            % Generate elements in rectangular grid
            antennaElements = cell(obj.ElementsPerPanel);
            for iAntennaM = 1:obj.ElementsPerPanel(1)
                for iAntennaN = 1:obj.ElementsPerPanel(2)
                 antennaElements{iAntennaM,iAntennaN} = AntennaElement(obj.Tilt,'');
                end
            end
				end
				
				function AzimuthAngle = getAzimuthAngle(obj, TxPosition, RxPosition)
					
					deltaX = TxPosition(1)- RxPosition(1);
					deltaY = TxPosition(2)- RxPosition(2);
					RxBearing = rad2deg(atan2(deltaY,deltaX));
					AzimuthAngle = obj.Bearing + RxBearing;
					
					% If Azimuth is below -180 or above 180 degrees, the angle at
					% which the radiation pattern is compute is opposite. E.g. 183
					% degrees is beyond the radiation pattern limit of -pi to pi, so
					% -177 is the correct conversion.
					if AzimuthAngle < -180
						AzimuthAngle = AzimuthAngle+360;
					end
					
					if AzimuthAngle > 180
						AzimuthAngle = AzimuthAngle-360;
					end
					
				end
				
				function antennaGains = compute3GPPAntennaGains(obj, TxPosition, RxPosition)
					% compute antenna gains for all elements given position of array
					% and position of receiver
					
					% Get azimuth angle using atan2
					AzimuthAngle = obj.getAzimuthAngle(TxPosition, RxPosition);
					
					% Elevation is given by tan(theta) = deltaH/dist2d
					% Horizontal is 90 degrees, zenith is 0
					deltaH = TxPosition(3)-RxPosition(3);
					dist2d = norm(RxPosition(1:2)-TxPosition(1:2));
					ElevationAngle = rad2deg(atan(deltaH/dist2d))+90;
					antennaGains = cell([length(obj.Panels),obj.ElementsPerPanel]);
					% Loop all panels, and elements and get the gain of each 
					for iPanel = 1:length(obj.Panels)
						elements = obj.Panels{1};
						for iAntennaM = 1:obj.ElementsPerPanel(1)
							for iAntennaN = 1:obj.ElementsPerPanel(2)
								antennaGains{iPanel,iAntennaM,iAntennaN} = elements{iAntennaM, iAntennaN}.get3DGain(ElevationAngle, AzimuthAngle);
							end
						end
					end
			
					
				end
				
				function antennaGains = getAntennaGains(obj, TxPosition, RxPosition)
					switch obj.Type
						case '3GPP38901'
							antennaGains = obj.compute3GPPAntennaGains(TxPosition, RxPosition);
						case 'Omni'
							antennaGains = {0}; %Ideal antenna pattern in all directions
						otherwise
							sonohilog(sprintf('Antenna Type %s not known', obj.Type),'ERR')
					end
					
				end

        function numPanels = NumberOfPanels(obj)
            numPanels = length(obj.Panels);
        end
    end
end

