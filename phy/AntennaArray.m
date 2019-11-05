classdef AntennaArray < handle
	% Implementation of Antenna Array configuration pr. ITU M.2412/3GPP 38.901
	% Copyright Jakob Thrane/DTU 2018
	properties
		Panels;
		ElementsPerPanel
		Polarizations;
		Bearing = 0;
		Tilt;
		Type; % 3GPP38901, Omni, Vivaldi
		Logger;
		Mimo;
	end
	
	properties (Access = private)
		HEspacing; % Horizontal antenna element spacing
		VEspacing; % Vertical antenna element spacing
	end
	
	methods
		function obj = AntennaArray(type, Logger, varargin)
			% AntennaArray constructor
			% 
			% :param type: String type of antenna array sectorised | omni | vivaldi
			% :param Logger: MonsterLog instance 
			% :param varargin: variable input for extra optional config e.g. MIMO setup
			% :return obj: AntennaArray instance
			%

			obj.Logger = Logger;
			obj.Type = type;
			switch type
				case 'sectorised'
					obj.Mimo = varargin{1};
					obj.config3gpp38901()
				case 'omni'
					obj.Mimo = varargin{1};
					obj.configOmniDirectional()
				case 'vivaldi'
					obj.configVivaldi(varargin{1})
			end			
		end
		
		function antennaGains = getAntennaGains(obj, TxPosition, RxPosition, varargin)
			% Returns the antenna gains for the array
			% 
			% :param obj: AntennaArray instance
			% :param TxPosition: 3x1 array of double with TX coordinates
			% :param RxPosition: 3x1 array of double with RX coordinates
			% :param varargin: cell array optional extra parameters for selecting specific element by index
			% :return antennaGains: scalar | cell double antenna gains
			% 
			
			switch obj.Type
				case 'sectorised'
					iSelectedElement = [];
					if ~isempty(varargin)
						iSelectedElement = varargin{1};
					end
					antennaGains = obj.compute3GPPAntennaGains(TxPosition, RxPosition, iSelectedElement);
				case 'omni'
					antennaGains = {0}; %Ideal antenna pattern in all directions
				case 'vivaldi'
					antennaGains = {obj.computeVivaldiAntennaGains(TxPosition, RxPosition)};
				otherwise
					obj.Logger.log(sprintf('Antenna Type %s not known', obj.Type),'ERR','MonsterAntenna:UnknownType')
			end
		end		
		
		function plotBearing(obj, Position, Color)
			% Utility to plot the bearing of the antenna array
			% 
			% :param obj: AntennaArray instance
			% :param Position: 2x1 array of Double with the coordinates
			% :param Color: string plotting color
			%

			alpha = deg2rad(obj.Bearing+90);
			L = 500;
			x = Position(1);
			y = Position(2);
			x2=x+(L*cos(alpha));
			y2=y+(L*sin(alpha));
			line([x y],[x2 y2])
		end
		
		function numPanels = NumberOfPanels(obj)
			numPanels = length(obj.Panels);
		end

	end

	methods (Access = private)
		function configVivaldi(obj, varargin)
			% Configures the antenna array when the vivaldi type is selected
			% 
			% :param obj: AntennaArray instance
			% :param varargin: downlink frequency as option
			% :return obj: AntennaArray instance
			%

			obj.Panels{1} = VivaldiAntenna(varargin{1});
		end
		
		function configOmniDirectional(obj)
			% Configures the antenna array when the omnidirectional type is selected
			% arrayTuple defines structure of array in accordance with 3GPP
			% 38.901. (Mg, Ng, M, N, P). Where
			% Mg x Ng = Number of panels in rectangular grid
			% M x N = Number of elements per panel in rectangular grid
			% P = Number of polarizations per element.
			% 
			% :param obj: AntennaArray instance
			% :return obj: AntennaArray instance
			% 
				
			obj.Tilt = 102;
			obj.Panels = cell((obj.Mimo.arrayTuple(1)*obj.Mimo.arrayTuple(2)),1);
			obj.ElementsPerPanel = obj.Mimo.arrayTuple(3:4);
			obj.Polarizations = obj.Mimo.arrayTuple(5);
			for iPanel = 1:length(obj.Panels)
				obj.Panels{iPanel} = obj.constructAntennaElements();
			end
		end

		function config3gpp38901(obj)
			% Configures the antenna array when the sectorised type is selected
			% arrayTuple defines structure of array in accordance with 3GPP
			% 38.901. (Mg, Ng, M, N, P). Where
			% Mg x Ng = Number of panels in rectangular grid
			% M x N = Number of elements per panel in rectangular grid
			% P = Number of polarizations per element.
			% 
			% :param obj: AntennaArray instance
			% :return obj: AntennaArray instance
			%

			bearing = 30;
			tilt = 102;
			obj.Panels = cell((obj.Mimo.arrayTuple(1)*obj.Mimo.arrayTuple(2)),1);
			obj.ElementsPerPanel = obj.Mimo.arrayTuple(3:4);
			obj.Polarizations = obj.Mimo.arrayTuple(5);
			obj.Bearing = bearing;
			obj.Tilt = tilt;
			for iPanel = 1:length(obj.Panels)
				obj.Panels{iPanel} = obj.constructAntennaElements();
			end
		end

		function antennaElements = constructAntennaElements(obj)
			% Generate elements in rectangular grid for the antenna array
			%
			% :param obj: AntennaArray instance
			% :return obj: AntennaArray instance
			%

			antennaElements = cell(obj.ElementsPerPanel);
			for iAntennaM = 1:obj.ElementsPerPanel(1)
				for iAntennaN = 1:obj.ElementsPerPanel(2)
					antennaElements{iAntennaM,iAntennaN} = AntennaElement(obj.Tilt,'');
				end
			end
		end

		function AzimuthAngle = getAzimuthAngle(obj, TxPosition, RxPosition)
			% Returns the azimuth angle given tx and rx positions
			%
			% :param obj: AntennaArray instance
			% :param TxPosition: 3x1 array of double with the TX coordinates
			% :param RxPosition: 3x1 array of double with the RX coordinates
			%
			
			deltaX = RxPosition(1)- TxPosition(1) ;
			deltaY = RxPosition(2)- TxPosition(2) ;
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

		function antennaGains = compute3GPPAntennaGains(obj, TxPosition, RxPosition, iSelectedElement)
			% Computes antenna gains for all elements given tx ad rx positions
			% 
			% :param obj: AntennaArray instance
			% :param TxPosition: 3x1 array of double with the TX coordinates
			% :param RxPosition: 3x1 array of double with the RX coordinates
			% :param iSelectedPanel: optional selection of specific element by index
			% :return antennaGains: cell of antenna gains
			% 

			% Get azimuth angle using atan2
			AzimuthAngle = obj.getAzimuthAngle(TxPosition, RxPosition);
			
			% Elevation is given by tan(theta) = deltaH/dist2d
			% Horizontal is 90 degrees, zenith is 0
			deltaH = TxPosition(3)-RxPosition(3);
			dist2d = norm(RxPosition(1:2)-TxPosition(1:2));
			ElevationAngle = rad2deg(atan(deltaH/dist2d))+90;

			% Check if a specific element gain is requested or not
			if ~isempty(iSelectedElement)
				antennaGains = obj.Panels{iSelectedElement}.get3DGain(ElevationAngle, AzimuthAngle);
			else
				% In this case, defaults to calculating all the gains
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
		end

		function antennaGain = computeVivaldiAntennaGains(obj, TxPosition, RxPosition)
			% Computes antenna gain for vivaldi antenna given tx and rx positions
			% 
			% :param obj: AntennaArray instance
			% :param TxPosition: 3x1 array of double with the TX coordinates
			% :param RxPosition: 3x1 array of double with the RX coordinates
			% :return antennaGain: double value of antenna gain
			% 

			% Get azimuth angle using atan2
			AzimuthAngle = obj.getAzimuthAngle(TxPosition, RxPosition);
			
			antennaGain = obj.Panels{1}.get3DGain([], AzimuthAngle);			
		end
	end
end

