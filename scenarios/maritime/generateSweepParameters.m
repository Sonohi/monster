function sweepParameters = generateSweepParameters(Simulation, optimisationMetric) 
	% Constructs the sweep parameters structure to store sweep state for each user
	%
	% :param Simulation: Monster instance
	% :param optimisationMetric: string to choose over which metric the sweep should optimise
	% :returns sweepParameters: sweep parameters for each UE

	enbList(1:length(Simulation.Stations)) = struct('eNodeBId', -1, 'angle', 0, 'rxPowdBm', -realmax, 'sinr', -realmax); 

	% The sweep algorithm is evaluated at every simulation round and the state is kept across rounds.
	% This is to mimic a real-life continuous process discretised in the realm of the simulation
	% At start, the initial antenna angle is used. It is a value between 0 and 360
	% Each round, the antenna can rotate a certain angle.
	% Such angle is given by the rotation speed of the hardware and evaluated in 1 ms time window.
	% Changing such parameter effectively models different hardware capabilities
	% For each simulation round, the UE can perform at most 1 rotation of rotationIncrement and update its state
	% E.g. if a full rotation can be completed in 10s, then rotationIncrement = 0.036
	% The sweep is then stopped once the UE decides to attach to a new eNodeB that offers a better SINR/power 
	totalRotationTime = 10000; % in ms
	sweepParameters(1: length(Simulation.Users)) = struct(...
		'ueId', 0,...
		'eNodeBList', enbList,...
		'metric', optimisationMetric,...
		'timeLastAssociation', 0,...
		'hysteresisTimer', 0,...
		'rotationIncrement', 360/totalRotationTime,...
		'rotationsPerformed', 0, ...
		'currentAngle', 0,...
		'startAngle', 0,...
		'maxAngle', 360); % this is the minimum increment for a rotation, as the 
	for iUser = 1:length(Simulation.Users)
		% assign the id to an empty slot in the sweepParameters
		sweepParameters(iUser).ueId = Simulation.Users.NCellID;
	end

end