classdef sonohiQuadriga < sonohiBase

		properties (Access=private)
			qdLayout;
			qdTrack;
			qdBuilder;
			qdSimulationParameters = qd_simulation_parameters;
			ChannelCoefficients;
		end

    methods

        function obj = sonohiQuadriga(Channel, Chtype)
            % Inherits :class:`ch.SONOHImodels.sonohiBase`
            obj = obj@sonohiBase(Channel, Chtype);
				end

				function obj = setupShadowing(obj, ~)
					sonohilog('Large-scale and small-scale parameters are set during setup.','NFO')
				end
				
				function obj = setup(obj, Stations, Users, Param)
					sonohilog('Setting up Quadriga model.','NFO')
					% Setup Parameters for each tier of propagation
					obj.qdSimulationParameters.center_frequency = Param.dlFreq*10e8;      % 2.53 GHz carrier frequency
					obj.qdSimulationParameters.use_absolute_delays = 1;        % Include delay of the LOS path
					obj.qdSimulationParameters.show_progress_bars = 1;         % Disable progress bars

					% Setup transmitter positions and antenna properties
					obj.qdLayout = qd_layout(obj.qdSimulationParameters);
					obj.qdLayout.no_tx = length(Stations);
					txAntenna = qd_arrayant('omni');	
					for stationIdx = 1:length(Stations)
						station = Stations(stationIdx);
						obj.qdLayout.tx_position(:,stationIdx) = station.Position;
						obj.qdLayout.tx_array(1,stationIdx) = copy(txAntenna);  
						obj.qdLayout.tx_name{stationIdx} = sprintf('station%i',station.NCellID);
					end
		
					% Setup receiver antenna
					obj.qdLayout.no_rx = length(Users);
					rxAntenna = qd_arrayant('dipole');
					for userIdx = 1:length(Users)
						user = Users(userIdx);
						obj.qdLayout.rx_position(:,userIdx) = user.Position;
						obj.qdLayout.rx_array(1,userIdx) = copy(rxAntenna);
						obj.qdLayout.rx_name{userIdx} = sprintf('user%i',user.NCellID);
						obj.qdLayout.track(1,userIdx).name = sprintf('user%itrack',user.NCellID);
						obj.qdLayout.track(1,userIdx).no_snapshots = length(user.Mobility.Trajectory);
						obj.qdLayout.track(1,userIdx).positions = [(user.Mobility.Trajectory - user.Position(1:2)), zeros(length(user.Mobility.Trajectory),1)]';
						% TODO determine scenario for each position. E.g. LOS, NLOS
						% etc.
						obj.qdLayout.track(1,userIdx).scenario = {'3GPP_3D_UMa_LOS'};
					end
					
					
					sonohilog('Computing channel coefficents.','NFO')
					obj.qdBuilder = obj.qdLayout.init_builder;
					obj.qdBuilder.gen_lsf_parameters;
					obj.qdBuilder.gen_ssf_parameters;
					obj.ChannelCoefficients = obj.qdBuilder.get_channels;
					
					figure
					[ map, x_coords, y_coords] = obj.qdLayout.power_map('3GPP_38.901_UMa_NLOS', 'quick', 5, -2000, 2000, -2000, 2000, 1.5);
					P = 10*log10(sum(abs(cat(3,map{:}) ) .^2, 3));
					obj.qdLayout.visualize([],[],0);
					hold on
					imagesc(x_coords, y_coords, P);
					colorbar
					xlim([-2000, 2000])
					ylim([-2000, 2000])
					% The outputted structure is num_tx * num_rx, sorted by the pairing
					% in qdLayout

				end
				
				function idx = getPairingIdx(obj, TxNode, RxNode)
					indicies = find(TxNode.NCellID == obj.qdLayout.pairing(1,:));
					idx = find(RxNode.NCellID == obj.qdLayout.pairing(2,indicies));
				end


        function [lossdB] = computePathLoss(obj, TxNode, RxNode)
           idx = obj.getPairingIdx(TxNode, RxNode);
					 iRound = obj.Channel.iRound;
					 coeff = obj.ChannelCoefficients(idx).coeff;
					 lossdB = abs(10*log10(sum(abs(coeff(1,1,:,iRound+1)).^2)));
					 %lossdB = abs(10*log10(mean(abs(coeff(1,1,:,iRound+1).^2))));
					 
        end


    end

end
