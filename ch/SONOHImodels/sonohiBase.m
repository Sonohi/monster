classdef sonohiBase < handle
	% This is the parent class for all channel modelling. Wrappers for channel models should be written using this structure. For examples on how to do so see the other implementations.
	
	properties
		Channel % For accessing variables in the channel coordinator :class:`ch.SonohiChannel`
		Chtype % Chtype: `'Downlink'` or `'Uplink'` switcher that executes :meth:`downlink` or :meth:`uplink`
	end
	
	methods
		function obj = sonohiBase(Channel, Chtype)
			sonohilog('Initializing channel model.','NFO0')
			obj.Channel = Channel;
			obj.Chtype = Chtype;
		end

		function obj = setup(obj, ~, ~, ~)
			% pass
		end
		
		function [stations,users] = run(obj,Stations,Users,varargin)
			% Main execution method, switches between uplink and downlink logic.
			%
			% :param varargin: If the channel property needs to be updated before execution it can be added as 'channel, :class:`ch.SonohiChannel`'
			if ~isempty(varargin)
				vargs = varargin;
				nVargs = length(vargs);
				
				for k = 1:nVargs
					if strcmp(vargs{k},'channel')
						obj.Channel = vargs{k+1};
					end
				end
			end
			
			
			switch obj.Chtype
				case 'downlink'
					users = obj.downlink(Stations,Users);
					stations = Stations;
				case 'uplink'
					stations = obj.uplink(Stations,Users);
					users = Users;
			end
			
		end
		
		function [users] = downlink(obj,Stations,Users)
			% Standard downlink logic. Output of this function is written into the :class:`ue.ueReceiverModule` of the users. If the users are scheduled for transmission
			% The downlink logic follows the follow flow
			%
			% 1. Find links and eNB - UE pairing.
			% 2. Setup transmission by copying :attr:`Stations.Tx.Waveform` into :attr:`Users.Rx.Waveform`.
			% 3. Compute link budget and thus calucated receiver power.
			% 4. If :attr:`Channel.enableFading`, add fading to waveform.
			% 5. Add AWGN based on thermal noise and receiver power. Compute SNR.
			% 6. Add propagation delay.
			%
			% :param Stations: Primarily need :attr:`Stations.Tx` Transmitter module
			% :type Stations: :class:`enb.EvolvedNodeB`
			% :param Users: Primarily need :attr:`Users.Tx` Receiver module
			% :type Users: :class:`ue.UserEquipment`
			users = Users;
			numLinks = length(Users);
			Pairing = obj.Channel.getPairing(Stations);
			for i = 1:numLinks
				% Local copy for mutation
				station = Stations([Stations.NCellID] == Pairing(1,i));
				user = Users(find([Users.NCellID] == Pairing(2,i))); %#ok
				
				% Setup transmission
				user = obj.setWaveform(station, user);
				
				% compute link budget and calculate Receiver power
				user = obj.computeLinkBudget(station, user);
				
				if strcmp(obj.Channel.fieldType,'full')
					if obj.Channel.enableFading
						user = obj.addFading(user);
					end
					user = obj.addAWGN(station, user);
				else
					user = obj.addAWGN(station, user);
				end
				
				user = obj.addPropDelay(station, user);
				
				% Write changes to user object in array.
				users(find([Users.NCellID] == Pairing(2,i))) = user;
			end
		end
		
		function setupShadowing(obj, varargin)
			% Function needs overwrite from models to enable shadowing
			sonohilog(sprintf('No setupShadowing method detected on chosen model %s',obj.Chtype),'ERR');
		end
		
		function RxNode = addPropDelay(obj,  TxNode, RxNode)
			% Adds propagation delay based on distance and frequency
			RxNode.Rx.PropDelay = obj.Channel.getDistance(TxNode.Position, RxNode.Position);
		end
		
		function [RxNode] = computeLinkBudget(obj, TxNode, RxNode)
			% Compute link budget for Tx -> Rx
			%
			% This requires a :meth:`computePathLoss` method, which is supplied by child classes.
			% returns updated RxPwdBm of RxNode.Rx
			[lossdB, RxNode] = obj.computePathLoss(TxNode, RxNode);
			EIRPdBm = TxNode.Tx.getEIRPdBm;
			rxPwdBm = EIRPdBm-lossdB-RxNode.Rx.NoiseFigure; %dBm
			RxNode.Rx.RxPwdBm = rxPwdBm;
			
		end
		
		function RxNode = addFading(obj, RxNode)
			% Adds fading using lteFadingChannel
			cfg.SamplingRate = RxNode.Rx.WaveformInfo.SamplingRate;
			cfg.Seed = obj.Channel.getLinkSeed(RxNode);        % Rx specific seed
			cfg.NRxAnts = 1;               % 1 receive antenna
			cfg.DelayProfile = 'EPA';      % EVA delay spread
			cfg.DopplerFreq = 5;         % 120Hz Doppler frequency
			cfg.MIMOCorrelation = 'Low';   % Low (no) MIMO correlation
			cfg.InitTime = obj.Channel.getSimTime();  % Initialization relative to sim time
			cfg.NTerms = 16;               % Oscillators used in fading model
			cfg.ModelType = 'GMEDS';       % Rayleigh fading model type
			cfg.InitPhase = 'Random';      % Random initial phases
			cfg.NormalizePathGains = 'On'; % Normalize delay profile power
			cfg.NormalizeTxAnts = 'On';    % Normalize for transmit antennas
			% Pass data through the fading channel model
			sig = [RxNode.Rx.Waveform;zeros(25,1)];
			rxsig = lteFadingChannel(cfg,sig);
			RxNode.Rx.Waveform = rxsig;
		end
		
		function lossdB = atmosphericLoss(obj, TxNode, RxNode)
			% Compute atmospheric loss based on
			%
			% * dry air preassure of 101300 Pa
			% * water vapour density 7.5 g/m^3
			% * Tempature 23 degrees calsius
			P = 101300; % dry air pressure in Pa
			ROU = 7.5;  % water vapour density in g/m^3
			freq = TxNode.DlFreq*10e6; % To Hz
			T = 23;
			R0 = obj.Channel.getDistance(TxNode.Position, RxNode.Position)/1000;
			lossdB = 10*log10(gaspl(R0,freq,T,P,ROU));
		end
		
		function lossdBm = thermalLoss(obj, RxNode)
			% Compute thermal loss based on bandwidth, at T = 290 K.
			% Worst case given by the number of resource blocks. Bandwidth is
			% given based on the waveform. Computed using matlabs :obj:`obw`
			bw = obw(RxNode.Rx.Waveform, RxNode.Rx.WaveformInfo.SamplingRate);
			T = 290;
			k = physconst('Boltzmann');
			thermalNoise = k*T*bw;
			lossdBm = 10*log10(thermalNoise*1000);
		end
		
		function [RxNode] = addAWGN(obj, TxNode, RxNode)
			% Adds gaussian noise based on thermal noise and calculated recieved power.
			
			% TODO: Gass Loss relevant to compute when moving into mmWave range
			%gasLossdB = obj.atmosphericLoss(TxNode, RxNode);
			thermalLossdBm = obj.thermalLoss(RxNode);
			
			%rxNoiseFloor = thermalLossdB-gasLossdB;
			rxNoiseFloor = thermalLossdBm;
			SNR = RxNode.Rx.RxPwdBm-rxNoiseFloor;
			SNRLin = 10^(SNR/10);
			str1 = sprintf('Station(%i) to User(%i)\n SNR:  %s\n RxPw:  %s\n', TxNode.NCellID,RxNode.NCellID,num2str(SNR),num2str(RxNode.Rx.RxPwdBm));
			sonohilog(str1,'NFO0');
			Es = sqrt(2.0*TxNode.CellRefP*double(RxNode.Rx.WaveformInfo.Nfft));
			
			% Compute spectral noise density NO
			N0 = 1/(Es*SNRLin);
			
			% Add AWGN
			noise = N0*complex(randn(size(RxNode.Rx.Waveform)), randn(size(RxNode.Rx.Waveform)));
			
			rxSig = RxNode.Rx.Waveform + noise;
			
			RxNode.Rx.SNR = SNRLin;
			RxNode.Rx.Waveform = rxSig;
			
		end
		
		
		
	end
	
	methods(Static)
		
		function RxNode = setWaveform(TxNode, RxNode)
			% Copies waveform and waveform info to Rx module, enables transmission.
			RxNode.Rx.Waveform = TxNode.Tx.Waveform;
			RxNode.Rx.WaveformInfo =  TxNode.Tx.WaveformInfo;
		end
		
		
	end
	
	
	
end
