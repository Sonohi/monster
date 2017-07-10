classdef ChBulk_v2
	%CHBULK_V2 Summary of this class goes here
	%   Detailed explanation goes here

	properties
		Area;
		Mode;
		Buildings;
		Draw;
		Region;
		WconfigLayout;
		WconfigParset;
	end

	methods(Static)


		function distance = getDistance(txPos,rxPos)
			distance = norm(rxPos-txPos);
			if distance < 0.5
				disp('shit!');
			end
		end

		function thermalNoise = ThermalNoise(NDLRB)
			switch NDLRB
				case 6
					BW = 1.4e6;
				case 15
					BW = 3e6;
				case 25
					BW = 5e6;
				case 50
					BW = 10e6;
				case 75
					BW = 15e6;
				case 100
					BW = 20e6;
			end

			T = 290;
			k = physconst('Boltzmann');
			thermalNoise = k*T*BW;
		end




	end

	methods(Access = private)

		function [numPoints,distVec,elavationProfile] = getElevation(obj,txPos,rxPos)

			elavationProfile(1) = 0;
			distVec(1) = 0;
			% Walk towards rxPos
			signX = sign(rxPos(1)-txPos(1));
			signY = sign(rxPos(2)-txPos(2));
			avgG = (txPos(1)-rxPos(1))/(txPos(2)-rxPos(2));
			position(1:2,1) = txPos(1:2);
			%plot(position(1,1),position(2,1),'r<')
			i = 2;
			numPoints = 0;
			while true
				% Check current distance
				distance = norm(position(1:2,i-1)'-rxPos(1:2));

				% Move position
				[moved_dist,position(1:2,i)] = move(position(1:2,i-1),signX,signY,avgG,0.1);
				distVec(i) = distVec(i-1)+moved_dist;
				%plot(position(1,i),position(2,i),'bo')
				% Check if new position is at a greater distance, if so, we
				% passed it.
				distance_n = norm(position(1:2,i)'-rxPos(1:2));
				if distance_n > distance
					break;
				else
					% Check if we're inside a building
					fbuildings_x = obj.Buildings(obj.Buildings(:,1) < position(1,i) & obj.Buildings(:,3) > position(1,i),:);
					fbuildings_y = fbuildings_x(fbuildings_x(:,2) < position(2,i) & fbuildings_x(:,4) > position(2,i),:);

					if ~isempty(fbuildings_y)
						elavationProfile(i) = fbuildings_y(5);
						if elavationProfile(i-1) == 0
							numPoints = numPoints +1;
						end
					else
						elavationProfile(i) = 0;

					end
				end
				i = i+1;
			end

			%figure
			%plot(elavationProfile)


			function [distance,position] = move(position,signX,signY,avgG,moveS)
				if abs(avgG) > 1
					moveX = abs(avgG)*signX*moveS;
					moveY = 1*signY*moveS;
					position(1) = position(1)+moveX;
					position(2) = position(2)+moveY;

				else
					moveX = 1*signX*moveS;
					moveY = (1/abs(avgG))*signY*moveS;
					position(1) = position(1)+moveX;
					position(2) = position(2)+moveY;
				end
				distance = sqrt(moveX^2+moveY^2);
			end

		end

		function [rxSig, SNRLin] = addPathlossAwgn(obj,Station,User,txSig,varargin)
			thermalNoise = obj.ThermalNoise(Station.NDLRB);
			hbPos = Station.Position;
			hmPos = User.Position;
			distance = obj.getDistance(hbPos,hmPos)/1e3;
			switch obj.Mode
				case 'eHATA'
					[lossdB, ~] = ExtendedHata_MedianBasicPropLoss(Station.DlFreq, ...
					  distance, hbPos(3), hmPos(3), obj.Region);

% 					[numPoints,distVec,elev_profile] = obj.getElevation(hbPos,hmPos);
% 
% 					if numPoints == 0
% 						numPoints_scale = 1;
% 					else
% 						numPoints_scale = numPoints;
% 					end
% 
% 					elev = [numPoints_scale; distVec(end)/(numPoints_scale); hbPos(3); elev_profile'; hmPos(3)];
% 
% 					lossdB = ExtendedHata_PropLoss(Station.DlFreq, hbPos(3), ...
% 						hmPos(3), obj.Region, elev);

				case 'winner'

					if nargin > 3
						nVargs = length(varargin);
						for k = 1:nVargs
							if strcmp(varargin{k},'loss')
								lossdB = varargin{k+1};
							end
						end
					end




			end


			txPw = 10*log10(Station.Pmax)+30; %dBm.

			rxPw = txPw-lossdB;
			% SNR = P_rx_db - P_noise_db
			rxNoiseFloor = 10*log10(thermalNoise)+User.NoiseFigure;
			SNR = rxPw-rxNoiseFloor;
			SNRLin = 10^(SNR/10);
			str1 = sprintf('Station(%i) to User(%i)\n Distance: %s\n SNR:  %s\n',...
				Station.NCellID,User.UeId,num2str(distance),num2str(SNR));
			sonohilog(str1,'NFO0');

			%% Apply SNR

			% Compute average symbol energy
			% This is based on the number of useed subcarriers.
			% Scale it by the number of used RE since the power is
			% equally distributed
			Es = sqrt(2.0*Station.CellRefP*double(Station.WaveformInfo.Nfft)*Station.WaveformInfo.OfdmEnergyScale);

			% Compute spectral noise density NO
			N0 = 1/(Es*SNRLin);

			% Add AWGN

			noise = N0*complex(randn(size(txSig)), ...
				randn(size(txSig)));

			rxSig = txSig + noise;

		end

		function rx = addFading(obj,tx,info)
			cfg.SamplingRate = info.SamplingRate;
			cfg.Seed = 1;                  % Random channel seed
			cfg.NRxAnts = 1;               % 1 receive antenna
			cfg.DelayProfile = 'EPA';      % EVA delay spread
			cfg.DopplerFreq = 120;         % 120Hz Doppler frequency
			cfg.MIMOCorrelation = 'Low';   % Low (no) MIMO correlation
			cfg.InitTime = 0;              % Initialize at time zero
			cfg.NTerms = 16;               % Oscillators used in fading model
			cfg.ModelType = 'GMEDS';       % Rayleigh fading model type
			cfg.InitPhase = 'Random';      % Random initial phases
			cfg.NormalizePathGains = 'On'; % Normalize delay profile power
			cfg.NormalizeTxAnts = 'On';    % Normalize for transmit antennas

			% Pass data through the fading channel model
			rx = lteFadingChannel(cfg,tx);
		end

		function [cfgLayout,cfgModel] = configureWinner(obj,Stations,Users)
			sonohilog('Setting up WINNER II channel model...','NFO')

			% Find number of base station types
			% A model is created for each type
			classes = unique({Stations.BsClass});
			for class = 1:length(classes)
				varname = classes{class};
				types.(varname) = find(strcmp({Stations.BsClass},varname));

			end

			Snames = fieldnames(types);

			for model = 1:numel(Snames)
				type = Snames{model};
				stations = types.(Snames{model});


				% Get number of links associated with the station.
				users = nonzeros([Stations(stations).Users]);
				numLinks = nnz(users);

				if isempty(users)
					% If no users are associated, skip the model
					continue
				end

				% Select antenna array based on station class.
				if strcmp(type,'macro')
					AA(1) = winner2.AntennaArray('UCA', 1,  0.3);
				elseif strcmp(type,'micro')
					AA(1) = winner2.AntennaArray('UCA', 1,  0.15);
				else

					sonohilog(sprintf('Antenna type for %s BsClass not defined, defaulting...',type),'WRN')
					AA(1) = winner2.AntennaArray('UCA', 1,  0.3);
				end

				% User antenna array
				AA(2) = winner2.AntennaArray('UCA', 1,  0.05);

				% Assign AA(1) to all stations
				eNBidx = num2cell(ones(length(stations),1));

				% For users use antenna configuration 2
				useridx = repmat(2,1,length(users));

				range = max(obj.Area);

				cfgLayout{model} = winner2.layoutparset(useridx, eNBidx, numLinks, AA, range);

				% Add station idx and user idx
				cfgLayout{model}.StationIdx = stations;
				cfgLayout{model}.UserIdx = users;

				% Set the position of the base station
				for iStation = 1:length(stations)
					cfgLayout{model}.Stations(iStation).Pos(1:3) = int64(floor(Stations(stations(iStation)).Position(1:3)));
				end

				% Set the position of the users
				% TODO: Add velocity vector of users
				for iUser = 1:length(users)
					cfgLayout{model}.Stations(iUser+length(stations)).Pos(1:3) = int64(floor(Users(users(iUser)).Position(1:3)));
				end

				cfgLayout{model}.Pairing = obj.getPairing(Stations(stations));

				% Change useridx of pairing to reflect
				% cfgLayout.Stations, e.g. user one is most likely
				% cfgLayout.Stations(2)
				for ll = 1:length(cfgLayout{model}.Pairing(2,:))
					cfgLayout{model}.Pairing(2,ll) =  length(stations)+ll;
				end




				for i = 1:numLinks
					userIdx = users(cfgLayout{model}.Pairing(2,i)-length(stations));
					stationIdx = stations(cfgLayout{model}.Pairing(1,i));
					cBs = Stations(stationIdx);
					cMs = Users(userIdx);
					% Apparently WINNERchan doesn't compute distance based
					% on height, only on x,y distance. Also they can't be
					% doubles...
					distance = obj.getDistance(cBs.Position(1:2),cMs.Position(1:2));
					if cBs.BsClass == 'micro'
						if distance <= 50
							msg = sprintf('(Station %i to User %i) Distance is %s, which is less than supported for B4 with NLOS, swapping to B4 LOS',...
								stationIdx,userIdx,num2str(distance));
							sonohilog(msg,'NFO0');

							cfgLayout{model}.ScenarioVector(i) = 6; % B4 Typical urban micro-cell
							cfgLayout{model}.PropagConditionVector(i) = 1; %1 for LOS
						else
							cfgLayout{model}.ScenarioVector(i) = 6; % B4 Typical urban micro-cell
							cfgLayout{model}.PropagConditionVector(i) = 0; %0 for NLOS
						end
					elseif cBs.BsClass == 'macro'
						if distance < 50
							msg = sprintf('(Station %i to User %i) Distance is %s, which is less than supported for C2 NLOS, swapping to LOS',...
								stationIdx,userIdx,num2str(distance));
							sonohilog(msg,'NFO0');
							cfgLayout{model}.ScenarioVector(i) = 11; %
							cfgLayout{model}.PropagConditionVector(i) = 1; %
						else
							cfgLayout{model}.ScenarioVector(i) = 11; % C2 Typical urban macro-cell
							cfgLayout{model}.PropagConditionVector(i) = 0; %0 for NLOS
						end
					end


				end

				% Use maximum fft size
				% However since the same BsClass is used these are most
				% likely to be identical
				sw = [Stations(stations).WaveformInfo];
				swNfft = [sw.Nfft];
				swSamplingRate = [sw.SamplingRate];
				cf = max([Stations(stations).DlFreq]); % Given in MHz

				frmLen = double(max(swNfft));   % Frame length

				% Configure model parameters
				% Determine maxMS velocity
				maxMSVelocity = max(cell2mat(cellfun(@(x) norm(x, 'fro'), ...
					{cfgLayout{model}.Stations.Velocity}, 'UniformOutput', false)));


				cfgModel{model} = winner2.wimparset;
				cfgModel{model}.CenterFrequency = cf*10e5; % Given in Hz
				cfgModel{model}.NumTimeSamples     = frmLen; % Frame length
				cfgModel{model}.IntraClusterDsUsed = 'yes';   % No cluster splitting
				cfgModel{model}.SampleDensity      = max(swSamplingRate)/50;    % To match sampling rate of signal
				cfgModel{model}.PathLossModelUsed  = 'yes';  % Turn on path loss
				cfgModel{model}.ShadowingModelUsed = 'yes';  % Turn on shadowing
				cfgModel{model}.SampleDensity = round(physconst('LightSpeed')/ ...
					cfgModel{model}.CenterFrequency/2/(maxMSVelocity/max(swSamplingRate)));

			end



		end


	end

	methods
		function obj = ChBulk_v2(Param)
			obj.Area = Param.area;
			obj.Mode = Param.channel.mode;
			obj.Buildings = Param.buildings;
			obj.Draw = Param.draw;
			obj.Region = Param.channel.region;
		end



		function [Stations,Users,obj] = traverse(obj,Stations,Users)

			% Assuming one antenna port, number of links are equal to
			% number of users scheuled in the given round
			users  = [Stations.Users];
			numLinks = nnz(users);

			Pairing = obj.getPairing(Stations);
			% Apply channel based on configuration.
			if strcmp(obj.Mode,'winner')
				[obj.WconfigLayout, obj.WconfigParset] = obj.configureWinner(Stations,Users);

				% Compute Rx for each model
				for model = 1:length(obj.WconfigLayout)

					if isempty(obj.WconfigLayout{model})
						sonohilog(sprintf('Nothing assigned to %i model',model),'NFO')
						continue
					end

					wimCh = comm.WINNER2Channel(obj.WconfigParset{model}, obj.WconfigLayout{model});

					chanInfo = info(wimCh);
					numTx    = chanInfo.NumBSElements(1);
					Rs       = chanInfo.SampleRate(1);
					numRx = chanInfo.NumLinks(1);




					impulseR = [ones(1, numTx); zeros(obj.WconfigParset{model}.NumTimeSamples-1, numTx)];
					h = wimCh(impulseR);

					% Debugging code. Use of direct waveform for validating
					% transferfunction
					%release(wimCh)
					%rxSig2 = wimCh(Stations(obj.WconfigLayout{model}.StationIdx(1)).TxWaveform);

					% Go through all links for the given scenario
					% 1. Compute transfer function for each link
					% 2. Apply transferfunction and  compute loss
					% 3. Add loss as AWGN
					for link = 1:numRx
						% Get TX from the WINNER layout idx
						txIdx = obj.WconfigLayout{model}.Pairing(1,link);
						% Get RX from the WINNER layout idx
						rxIdx = obj.WconfigLayout{model}.Pairing(2,link)-length(obj.WconfigLayout{model}.StationIdx);
						Station = Stations(obj.WconfigLayout{model}.StationIdx(txIdx));
						User = Users(obj.WconfigLayout{model}.UserIdx(rxIdx));
						% Get corresponding TxSig
						txSig = Station.TxWaveform;
						txPw = 10*log10(bandpower(txSig));


						%figure
						%plot(10*log10(abs(fftshift(fft(txSig)).^2)))
						%hold on

						% Compute channel transfer function
						H{link} = fft(h{link},length(txSig));

						% Apply transfer function to signal

						X = fft(txSig)./length(txSig);
						Y = X.*H{link};


						rxSig = ifft(Y)*length(txSig);
						rxPw = 10*log10(bandpower(rxSig));
						lossdB = txPw-rxPw;
						%plot(10*log10(abs(fftshift(fft(rxSig)).^2)));
						%plot(10*log10(abs(fftshift(fft(rxSig2{1}))).^2));

						% Normalize signal and add loss as AWGN based on
						% noise floor
						rxSigNorm = rxSig.*10^(lossdB/20);

						rxSigNorm = obj.addPathlossAwgn(Station, User, rxSigNorm, 'loss', lossdB);

						%plot(10*log10(abs(fftshift(fft(rxSigNorm)).^2)),'Color',[0.5,0.5,0.5,0.2]);
						% Assign to user
						Users(obj.WconfigLayout{model}.UserIdx(rxIdx)).RxWaveform = rxSigNorm;


						% TODO: Save transfer function for each link and use
						% it for SyncRoutine in combination with the main
						% simulation loop

					end
				end

			elseif strcmp(obj.Mode,'eHATA')
				for i = 1:numLinks
					station = Stations(Pairing(1,i));
					Users(Pairing(2,i)).RxWaveform = obj.addFading([...
						station.TxWaveform;zeros(25,1)],station.WaveformInfo);
					Users(Pairing(2,i)).RxWaveform = obj.addPathlossAwgn(...
						station,Users(Pairing(2,i)),Users(Pairing(2,i)).RxWaveform);

				end
			end

		end

		function Pairing = getPairing(obj,Stations)
			users  = [Stations.Users];

			nlink=1;
			for i = 1:length(Stations)
				for ii = 1:nnz(users(:,i))
					Pairing(:,nlink) = [i; users(ii,i)];
					nlink = nlink+1;
				end
			end

		end

		function pwr = calculateReceivedPower(obj, User, Station)
			% calculate pathloss and fading for this link
			rxWaveform = obj.addFading([Station.TxWaveform;zeros(25,1)], ...
				Station.WaveformInfo);
			rxWaveform = obj.addPathlossAwgn(Station, User, rxWaveform);

			pwr = bandpower(rxWaveform);
		end

		function [snr, evm] = calculateSignalDegradation(obj, User, Station)
			% calculate pathloss and fading for this link
			rxWaveform = obj.addFading([Station.TxWaveform;zeros(25,1)], ...
				Station.WaveformInfo);
			[rxWaveform, snr] = obj.addPathlossAwgn(Station, User, rxWaveform);

			% TODO remove stub for EVM
			evm = 0;
		end

	end
end
