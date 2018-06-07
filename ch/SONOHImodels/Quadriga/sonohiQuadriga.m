classdef sonohiQuadriga < sonohiBase

		properties (Access=private)
			qdLayout;
			qdTrack;
			qdSimulationParameters = qd_simulation_parameters;
			ChannelCoefficients;
		end

    methods

        function obj = sonohiQuadriga(Channel, Chtype)
            % Inherits :class:`ch.SONOHImodels.sonohiBase`
            obj = obj@sonohiBase(Channel, Chtype)
				end
				
				function obj = setup(obj, Stations, Users, Param)

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
						obj.qdLayout.track(1,userIdx).scenario = {'3GPP_3D_UMa_NLOS'};
					end
					
					h = obj.qdLayout.init_builder;
					h.gen_lsf_parameters;
					h.gen_ssf_parameters;
					obj.ChannelCoefficients = h.get_channels;

				end


        function [lossdB] = computePathLoss(obj, TxNode, RxNode)
           
        end


    end

end
