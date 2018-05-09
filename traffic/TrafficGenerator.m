classdef TrafficGenerator
	% This class is used to handle the generation of the traffic in the network
	% A TrafficGenerator object is created for each type of traffic profile used in the simulation
	% A traffic profile is made of:
	%
	% :trafficType: a traffic type (e.g. video streaming or full buffer)
	% :arrivalMode: a process for the arrival mode (e.g. Poisson)
	% :trafficSource: a traffic source with the data used to create packets
	% :associatedUeIds: an array of UE IDs that are associated with this traffic generator
	
	properties
		trafficType;
		arrivalMode;
		trafficSource; 
		associatedUeIds; 
		arrivalTimes;
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
				case 'webBrowsing'
					if (exist('traffic/webBrowsing.mat', 'file') ~= 2 || Param.reset)
						obj.trafficSource = loadWebBrowsingTraffic('traffic/webBrowsing.csv');
					else
						traffic = load('traffic/webBrowsing.mat');
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
			obj.arrivalTimes = obj.setArrivalTimes(Param);
		end
		
		function arrivalTimes = setArrivalTimes(obj, Param)
			% Set arrival times is used to set the starting times for the associated UEs
			%
			% :Param.poissonLambda: mean of the Poisson process, used if the arrival process is Poisson
			% :Param.uniformLower: lower limit of the Uniform process, used if the arrival process is Uniform
			% :Param.uniformUpper: upper limit of the Uniform process, used if the arrival process is Uniform
			% :Param.staticStart: static start time if the arrival process is static
			rng(Param.seed);
			switch obj.arrivalMode
				case 'Poisson'
					for i = 1:length(obj.associatedUeIds)
						tStart(i,1) = random('Poisson', Param.poissonLambda);
					end
				case 'Uniform'
					for i = 1:length(obj.associatedUeIds)
						tStart(i,1) = random('Uniform', Param.uniformLower, Param.uniformUpper);
					end
				case 'Static'
					tStart(1:length(obj.associatedUeIds), 1) = Param.staticStart;
				otherwise
					sonohilog('(TRAFFIC GENERATOR constructor) error, unsupported arrival mode','ERR');
					tStart = [];
			end
			arrivalTimes = tStart*10^-3;
		end

		function tStart = getStartingTime(obj, ueId)
			% Get starting time is used to get the starting time for an individual UE
			%
			% :ueId: UE ID
			ueIx = find(obj.associatedUeIds == ueId);
			if ueIx
				tStart = obj.arrivalTimes(ueIx);
			else
				sonohilog('(TRAFFIC GENERATOR getStartingTime) error, UE not found','ERR');
				tStart = NaN;
			end
		
		end
		
		function newQueue = updateTransmissionQueue(obj, User, simTime)
			% Update transmission queue is used to update the data in the queue for a specific user
			%
			% :param User: User is the UE
			% :type User: :class:`ue.UserEquipment`
			% :param simTime: is the current simulation time
			
			% By default the queue is not updated
			newQueue = User.Queue;
			
			% First, check whether the arrival time of this UE allows it to start
			if User.TrafficStartTime <= simTime
				% first off check the id/index of the next packet to be put into the queue
				pktIx = User.Queue.Pkt;
				if pktIx >= length(obj.trafficSource)
					pktIx = 1;
				end
				
				% Get all packets from the source portion that have a delivery time before the current simTime
				for iPkt = pktIx:length(obj.trafficSource)
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