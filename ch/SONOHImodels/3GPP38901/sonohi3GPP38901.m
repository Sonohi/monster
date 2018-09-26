classdef sonohi3GPP38901 < sonohiBase
	% V1 This is implemented using the 3GPP TR 38901 v14 document 5G; Study on channel model for frequencies from .5 to 100 GHZ
	%
	% .. todo:: Add fast fading as specified by the specification. E.g. CDL and TDL
	%
	% V1 contains only the implementation of pathloss with shadowing added as log-normal distributions based on a standard deviation.
	% V2 added indoor propagation losses with uniform distributions based on indoor depth and material losses as documented in 38901.
	%
	% Current scenarios are implemented and usable:
	%
	% * 'RMa' - Rural Macro
	% * 'UMa' - Urban Macro
	% * 'UMi' - Urban Micro
	
	properties
		SpatialMaps = struct(); % Struct for storing spatial maps for each station.
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
				
				obj.SpatialMaps.(stationString) = struct();
				
				% Generate map for station based on station class
				[LOSmap, NLOSmap, LOSpropmap, axisLOS, axisNLOS, axisLOSprop] = obj.generateShadowMap(station);
                
                obj.SpatialMaps.(stationString).LOSprop = LOSpropmap;
				obj.SpatialMaps.(stationString).LOS = LOSmap;
				obj.SpatialMaps.(stationString).NLOS = NLOSmap;
				obj.SpatialMaps.(stationString).axisLOS = axisLOS;
				obj.SpatialMaps.(stationString).axisNLOS = axisNLOS;
                obj.SpatialMaps.(stationString).axisLOSprop = axisLOSprop; 
				
			end
		end
		
		function [mapLOS, mapNLOS, mapLOSprop, axisLOS, axisNLOS, axisLOSprop] = generateShadowMap(obj, station)
			% .. todo:: check station.Seed is unique per station.
			areaType = obj.Channel.getAreaType(station);
			fMHz = station.DlFreq; % Freqency in MHz
			radius = obj.Channel.getAreaSize(); % Get range of grid
			switch areaType
				case 'RMa'
					sigmaSFLOS = 5;
					sigmaSFNLOS = 8;
					dCorrLOS = 37;
					dCorrNLOS = 120;
          dCorrLOSprop = 60;
				case 'UMa'
					sigmaSFLOS = 4;
					sigmaSFNLOS = 6;
					dCorrLOS = 37;
					dCorrNLOS = 50;
          dCorrLOSprop = 50;
				case 'UMi'
					sigmaSFLOS = 4;
					sigmaSFNLOS = 7.82;
					dCorrLOS = 10;
					dCorrNLOS = 13;
					dCorrLOSprop = 50;
      end
			% Configure LOS probability map G, with correlation distance
			% according to 7.6-18. 
			[mapLOSprop, xaxis, yaxis] = obj.LOSpropMap(dCorrLOSprop, fMHz, radius,  station.Seed);
			axisLOSprop = [xaxis; yaxis];
			
			% Spatial correlation map of LOS Large-scale SF
			[mapLOS, xaxis, yaxis] = obj.spatialCorrMap(sigmaSFLOS, dCorrLOS, fMHz, radius, station.Seed);
			axisLOS = [xaxis; yaxis];
			
			% Spatial correlation map of NLOS Large-scale SF
			[mapNLOS, xaxis, yaxis] = obj.spatialCorrMap(sigmaSFNLOS, dCorrNLOS, fMHz, radius, station.Seed);
			axisNLOS = [xaxis; yaxis];
			end
		
      
        function XCorr = computeShadowingLoss(obj, stationID, userPosition, LOS)
        % Interpolation between the random variables initialized
				% provides the magnitude of shadow fading given the LOS state.
				%
				% .. todo:: Compute this using the cholesky decomposition as explained in the WINNER II documents of all LSP.
				stationString = sprintf('station%i',stationID);
				if LOS
					map = obj.SpatialMaps.(stationString).LOS;
					axisXY = obj.SpatialMaps.(stationString).axisLOS;
				else
					map = obj.SpatialMaps.(stationString).NLOS;
					axisXY = obj.SpatialMaps.(stationString).axisNLOS;
            end
            
            obj.checkInterpolationRange(axisXY, userPosition);
						XCorr = interp2(axisXY(1,:), axisXY(2,:), map, userPosition(1), userPosition(2), 'spline');
			
        end
        
        function LOS = spatialLOSstate(obj, stationID, userPosition, LOSprop)
            % Determine spatial LOS state by realizing random variable from
            % spatial correlated map and comparing to LOS probability. Done
            % according to 7.6.3.3
            stationString = sprintf('station%i',stationID);
            map = obj.SpatialMaps.(stationString).LOSprop;
            axisXY = obj.SpatialMaps.(stationString).axisLOSprop;
            LOSrealize = interp2(axisXY(1,:), axisXY(2,:), map, userPosition(1), userPosition(2), 'spline');
            if LOSrealize < LOSprop
               LOS = 1;
            else
               LOS = 0;
            end
            
        end
        
        
		
		function [lossdB, varargout] = computePathLoss(obj, TxNode, RxNode)
			% Computes path loss. uses the following parameters
			%
			% ..todo:: Compute indoor depth from mobility class
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
			[LOS, prop] = obj.Channel.isLinkLOS(TxNode, RxNode, false);
			if ~isnan(prop)
					% LOS state is determined by comparing with spatial map of
					% random variables, if the probability of determining LOS
					% is used. 
					LOS = obj.spatialLOSstate(TxNode.NCellID, RxNode.Position, prop);
			end

			
           
			shadowing = obj.Channel.enableShadowing;
			avgBuilding = mean(obj.Channel.BuildingFootprints(:,5));
			avgStreetWidth = obj.Channel.BuildingFootprints(2,2)-obj.Channel.BuildingFootprints(1,4);
			lossdB = loss3gpp38901(areatype, distance2d, distance3d, f, hBs, hUt, avgBuilding, avgStreetWidth, LOS);
            RxNode.Rx.ChannelConditions.BaseLoss = lossdB;
            
			if RxNode.Mobility.Indoor 
				% Low loss model consists of LOS
				materials = {'StandardGlass', 'Concrete'; 0.3, 0.7};
				sigma_P = 4.4;

				% High loss model consists of
				%materials = {'IIRGlass', 'Concrete'; 0.7, 0.3}
				%sigma_P = 6.5;

				PL_tw = buildingloss3gpp38901(materials, f);

				% If indoor depth can be computed
				%PL_in = indoorloss3gpp38901('', 2d_in);
				% Otherwise sample from uniform
				PL_in  = indoorloss3gpp38901(areatype);
				indoorLosses = PL_tw + PL_in + randn(1, 1)*sigma_P;
				lossdB = lossdB + indoorLosses;
				RxNode.Rx.ChannelConditions.IndoorLoss = indoorLosses;

			end
			            
			% Return of channel conditions if required.
			RxNode.Rx.ChannelConditions.lossdB = lossdB;
			RxNode.Rx.ChannelConditions.LOS = LOS;
			RxNode.Rx.ChannelConditions.LOSprop = prop;
			RxNode.Rx.ChannelConditions.AreaType = areatype;

			if shadowing
				XCorr = obj.computeShadowingLoss(TxNode.NCellID, RxNode.Position, LOS);
				RxNode.Rx.ChannelConditions.LSP = XCorr; % Only large scale parameters at the moment is shadowing.
				lossdB = lossdB + XCorr;
			end

			RxNode.Rx.ChannelConditions.pathloss = lossdB;

			varargout{1} = RxNode;
		end
		
	end
	
	methods(Static)

			
		function [map, xaxis, yaxis] = spatialCorrMap(sigmaSF, dCorr, fMHz, radius, seed)
			% Create a map of independent Gaussian random variables according to the decorrelation distance. Interpolation between the random variables can be used to realize the 2D correlations. 
			lambdac=300/fMHz;   % wavelength in m
			interprate=round(dCorr/lambdac);
			Lcorr=lambdac*interprate;
			Nsamples=round(radius/Lcorr);
      rng(seed);
			map = randn(2*Nsamples,2*Nsamples)*sigmaSF;
			xaxis=[-Nsamples:Nsamples-1]*Lcorr;
			yaxis=[-Nsamples:Nsamples-1]*Lcorr;
			
		end
		
		function [map, xaxis, yaxis] = LOSpropMap(dCorr, fMHz, radius, seed)
			% Spatial correlation of LOS probabilities, used to realize if
			% the link is LOS. See 7.6.3.3.
			%
			% .. todo:: refactorize this function with spatialCorrMap, only difference is the prior distribution of uniform vs gaussian.
			lambdac=300/fMHz;   % wavelength in m
			interprate=round(dCorr/lambdac);
			Lcorr=lambdac*interprate;
			Nsamples=round(radius/Lcorr);
			
			% LOS is determined by probability and realized by comparing
			% the distance-based LOS probability function with the spatial
			% correlated random variable.
			rng(seed);
			map = rand(2*Nsamples,2*Nsamples);
			xaxis=[-Nsamples:Nsamples-1]*Lcorr;
			yaxis=[-Nsamples:Nsamples-1]*Lcorr;
			
		end
		
		function checkInterpolationRange(axisXY, Position)
		% Function used to check if the position can be interpolated
		extrapolation = false;
		if Position(1) > max(axisXY(1,:))
			extrapolation = true;
		elseif Position(1) < min(axisXY(1,:))
			extrapolation = true;
		elseif Position(2) > max(axisXY(2,:))
			extrapolation = true;
		elseif Position(3) < min(axisXY(2,:))
			extrapolation = true;
		end
		
		if extrapolation
				pos = sprintf('(%s)',num2str(Position));
				bound = sprintf('(%s)',num2str([min(axisXY(1,:)), min(axisXY(2,:)), max(axisXY(1,:)), max(axisXY(2,:))]));
				sonohilog(sprintf('Position of Rx out of bounds. Bounded by %s, position was %s. Increase Channel.getAreaSize',bound,pos), 'ERR')
		end
			
		end
		


		function [LOS, varargout] = LOSprobability(Channel, Station, User)
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
