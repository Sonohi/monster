classdef sonohi3GPP38901 < sonohiBase
	% This is implemented using the 3GPP TR 38901 v14 document
	% 5G; Study on channel model for frequencies from .5 to 100 GHZ
	%
	% .. todo:: Add fast fading as specified by the specification. E.g. CDL and TDL
	%
	% V1 contains only the implementation of pathloss with shadowing added as log-normal distributions based on a standard deviation.
	%
	% Current scenarios are implemented and usable:
	%
	% * 'RMa' - Rural Macro
	% * 'UMa' - Urban Macro
	% * 'UMi' - Urban Micro
	
	properties
		ShadowMaps = struct(); % Struct for storing shadow maps for each staiton
	end
	
	methods
		
		function obj = sonohi3GPP38901(Channel, Chtype)
			% Inherits :class:`ch.SONOHImodels.sonohiBase`
			obj = obj@sonohiBase(Channel, Chtype);
			
		end
		
		function setupShadowing(obj, Stations)
			% For each base station, construct a shadow map. This is done using '`interpolation`' method as described in [#chmodelbook]_.
			% Values for decorrelation distance and the magnitude of shadowing are given in Table 7.5-6 of TR 38.901
			for stationIdx = 1:length(Stations)
				station = Stations(stationIdx);
				stationString = sprintf('station%i',station.NCellID);
				
				obj.ShadowMaps.(stationString) = struct();
				
				% Generate map for station based on station class
				[LOSmap, NLOSmap, axisLOS, axisNLOS] = obj.generateShadowMap(station);
				obj.ShadowMaps.(stationString).LOS = LOSmap;
				obj.ShadowMaps.(stationString).NLOS = NLOSmap;
				obj.ShadowMaps.(stationString).axisLOS = axisLOS;
				obj.ShadowMaps.(stationString).axisNLOS = axisNLOS;
				
			end
		end
		
		function [mapLOS, mapNLOS, axisLOS, axisNLOS] = generateShadowMap(obj, station)
			areaType = obj.Channel.getAreaType(station);
			fMHz = station.DlFreq; % Freqency in MHz
			radius = obj.Channel.getAreaSize(); % Get range of grid
			switch areaType
				case 'RMa'
					sigmaSFLOS = 5;
					sigmaSFNLOS = 8;
					dCorrLOS = 37;
					dCorrNLOS = 120;
				case 'UMa'
					sigmaSFLOS = 4;
					sigmaSFNLOS = 6;
					dCorrLOS = 37;
					dCorrNLOS = 50;
				case 'UMi'
					sigmaSFLOS = 4;
					sigmaSFNLOS = 7.82;
					dCorrLOS = 10;
					dCorrNLOS = 13;
			end
			[mapLOS, xaxis, yaxis] = obj.spartialCorrMap(sigmaSFLOS, dCorrLOS, fMHz, radius, 'interpolation');
			axisLOS = [xaxis; yaxis];
			[mapNLOS, xaxis, yaxis] = obj.spartialCorrMap(sigmaSFNLOS, dCorrNLOS, fMHz, radius, 'interpolation');
			axisNLOS = [xaxis; yaxis];
		end
		
		
		function [map, xaxis, yaxis] = spartialCorrMap(obj, sigmaSF, dCorr, fMHz, radius, method)
			
			switch method
				case 'interpolation'
					lambdac=300/fMHz;   % wavelength in m
					interprate=round(dCorr/lambdac);
					Lcorr=lambdac*interprate;
					Nsamples=round(radius/Lcorr);
					
					map = randn(2*Nsamples,2*Nsamples)*sigmaSF;
					xaxis=[-Nsamples:Nsamples-1]*Lcorr;
					yaxis=[-Nsamples:Nsamples-1]*Lcorr;
			end
			
			
		end
		
		function XCorr = computeShadowingLoss(obj, stationID, userPosition, LOS)
			stationString = sprintf('station%i',stationID);
			if LOS
				map = obj.ShadowMaps.(stationString).LOS;
				axisXY = obj.ShadowMaps.(stationString).axisLOS;
			else
				map = obj.ShadowMaps.(stationString).NLOS;
				axisXY = obj.ShadowMaps.(stationString).axisNLOS;
			end
			XCorr = interp2(axisXY(1,:), axisXY(2,:), map, userPosition(1), userPosition(2), 'spline');
			
		end
		
		
		function [lossdB] = computePathLoss(obj, TxNode, RxNode)
			% Computes path loss. uses the following parameters
			%
			% * `f` - Frequency in GHz
			% * `hBs` - Height of Tx
			% * `hUt` - height of Rx
			% * `d2d` - Distance in 2D
			% * `d3d` - Distance in 3D
			% * `LOS` - Link LOS boolean, determined by :meth:`ch.SonohiChannel.isLinkLOS`
			% * `shadowing` - Boolean for enabling/disabling shadowing using log-normal distribution
			% * `avgBuilding` - Average height of buildings
			% * `avgStreetWidth` - Average width of the streets
			f = TxNode.DlFreq/10e2; % Frequency in GHz
			hBs = TxNode.Position(3);
			hUt = RxNode.Position(3);
			distance2d =  obj.Channel.getDistance(TxNode.Position(1:2),RxNode.Position(1:2));
			distance3d = obj.Channel.getDistance(TxNode.Position,RxNode.Position);
			
			areatype = obj.Channel.getAreaType(TxNode);
			seed = obj.Channel.getLinkSeed(RxNode);
			LOS = obj.Channel.isLinkLOS(TxNode, RxNode, false);
			shadowing = obj.Channel.enableShadowing;
			avgBuilding = mean(obj.Channel.BuildingFootprints(:,5));
			avgStreetWidth = obj.Channel.BuildingFootprints(2,2)-obj.Channel.BuildingFootprints(1,4);
			lossdB = loss3gpp38901(areatype, distance2d, distance3d, f, hBs, hUt, avgBuilding, avgStreetWidth, LOS);
			
			if shadowing
				lossdB = lossdB + obj.computeShadowingLoss(TxNode.NCellID, RxNode.Position, LOS);
			end
		end
		
	end
	
	methods(Static)
		function [LOS, varargout]  = LOSprobability(Channel, Station, User)
			% LOS probability using table 7.4.2-1 of 3GPP TR 38.901
			areaType = Channel.getAreaType(Station);
			dist2d = Channel.getDistance(Station.Position(1:2), User.Position(1:2));
			
			switch areaType
				case 'RMa'
					if dist2d <= 10
						prop = 1;
					else
						prop = exp(-1*((dist2d-10)/1000));
					end
					
				case 'UMi'
					if dist2d <= 18
						prop = 1;
					else
						prop = 18/dist2d + exp(-1*((dist2d)/36))*(1-(18/dist2d));
					end
					
				case 'UMa'
					if dist2d <= 18
						prop = 1;
					else
						if User.Position(3) <= 13
							C = 0;
						elseif (User.Position(3) > 13) && (User.Position(3) <= 23)
							C = ((User.Position(3)-13)/10)^(1.5);
						else
							sonohilog('Error in computing LOS. Height out of range','ERR');
						end
						prop = (18/dist2d + exp(-1*((dist2d)/63))*(1-(18/dist2d)))*(1+C*(5/4)*(dist2d/100)^3*exp(-1*(dist2d/150)));
					end
					
				otherwise
					sonohilog(sprintf('AreaType: %s not valid for the LOSMethod %s',areaType, Channel.LOSMethod),'ERR');
					
			end
			
			x = rand;
			if x > prop
				LOS = 0;
			else
				LOS = 1;
			end
			
			if nargout > 1
				varargout{1} = prop;
				varargout{2} = x;
				varargout{3} = dist2d;
			end
			
		end
	end
	
end
