classdef TrafficGenerator
	% This class is used to handle the generation of the traffic in the network
	% A TrafficGenerator object is created for each type of traffic profile used in the simulation
	% A traffic profile is made of:
	% : a traffic type (e.g. video streaming or full buffer)
	% : a process for the arrival mode (e.g. Poisson)
	% : a traffic source with the data used to create packets
	% : an array of UE IDs that are associated with this traffic generator
	properties 
		trafficType;
		arrivalMode;
		arrival
		trafficSource;
		associatedUeIds;
	end

	methods
		function obj = TrafficGenerator(trafficModel, associatedUeIds, Param)
			obj.trafficType = trafficModel;
			switch trafficModel
				case 'videoStreaming'
					if (exist('traffic/videoStreaming.mat', 'file') ~= 2 || Param.reset)
						obj.trafficSource = loadVideoStreamingTraffic('traffic/videoStreaming.csv', true);
					else
						traffic = load('traffic/videoStreaming.mat');
						obj.trafficSource = traffic.trSource;
						clear traffic
					end
				case 'fullBuffer'
					if (exist('traffic/fullBuffer.mat', 'file') ~= 2 || Param.reset)
						obj.trafficSource = loadFullBufferTraffic('traffic/fullBuffer.csv');
					else
						traffic = load('traffic/fullBuffer.mat');
						obj.trafficSource = traffic.trSource;
						clear traffic
					end
				otherwise
					sonohilog('(TRAFFIC GENERATOR constructor) error, unsupported traffic model','ERR');
			end
			obj.arrivalMode = Param.ueArrivalDistribution;
			obj.associatedUeIds = associatedUeIds;
		end

		function tStart = getStartingTime(obj, UeId, Param)
			% Get starting time is used to get the initial starting time for a UE 
			%
			% : UeId is the ID of the UE 
			% : Param.poissonLambda mean of the Poisson process, used if the arrival process is Poisson
			% : Param.uniformLower lower limit of the Uniform process, used if the arrival process is Uniform 
			% : Param.uniformUpper upper limit of the Uniform process, used if the arrival process is Uniform			 

			% Find index of the UE
			iUser = find(obj.associatedUeIds == UeId);
			if ~isempty(iUSer)
				% Sample from the PDF for the arrival mode
				switch obj.ueArrivalDistribution
					case 'Poisson'
						randomSample = random('Poisson', Param.poissonLambda);
					case 'Uniform' 
						randomSample = random('Uniform', Param.uniformLower, Param.uniformUpper);
					otherwise 
						sonohilog('(TRAFFIC GENERATOR constructor) error, unsupported arrival mode','ERR');	
						randomSample = NaN;
				end
				tStart = randomSample*10^-3;
			else
				fSpec = '(TRAFFIC GENERATOR - getStartingTime) UE with ID %i not found in associated UEs\n';
				s=sprintf(fSpec, UeId);
    		sonohilog(s,'ERR');
			end
		end 

		function newQueue = updateTransmissionQueue(obj, User, simTime)
			% Update transmission queue is used to update the data in the queue for a specific user
			%
			% : User is the UE
			% : simTime is the current simulation time
			
			% By default the queue is not updated
			newQueue = User.Queue;

			% First, check whether the arrival time of this UE allows it to start
			if User.TrafficStartTime >= simTime
				% first off check the id/index of the next packet to be put into the queue
				pktIx = User.Queue.Pkt;
				if pktIx >= length(obj.trafficSource)
					pktIx = 1;
				end

				% Get all packets from the source portion that have a delivery time before the current simTime
				for iPkt = pktIx:length(src)
					if obj.trafficSource(iPkt, 1) <= simTime
						% increase frame size and update frame delivery deadline
						newQueue.Size = newQueue.Size + obj.trafficSource(iPkt, 2);
						newQueue.Time = obj.trafficSource(iPkt, 1);
					else
						% all packets in this delivery window have been added, save the ID of the next
						newQueue.Pkt = iPkt;
						break;
					end
				end

			end
		end

	end

	
end