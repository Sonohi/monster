function sweepParams = performAntennaSweep(Simulation, sweepParams)
	% Performs the tasks of antenna rotation and evaluates re-association
	%
	% :param Simulation:  Monster instance
	% :param sweepParams: current sweep parameters
	% :return newAssociations: list of new associations for the UEs (can be empty)
	% :return newSweepParams: updated sweep parameters

	% Loop on the users in the simulation and for each build a list
	for iUser = 1:length(Simulation.Users)
		sweepIndex = find([sweepParams.ueId] == Simulation.Users(iUser).NCellID);
		ueSweep = sweepParams(sweepIndex);
		% Evaluate that we are not waiting for an hysteresis timer to expire
		Simulation.Logger.log('(MARITIME SWEEP - evaluateCurrentAngle) evaluating hysteresis for starting sweep', 'DBG');
		if Simulation.Config.Runtime.currentTime - ueSweep.timeLastAssociation >= ueSweep.hysteresisTimer
			ueSweep = evaluateCurrentAngle(Simulation, ueSweep);
		end

		% Once this iteration is completed, save the result in the return structure
		sweepParams(sweepIndex).eNodeBList = ueSweep.eNodeBList;
		sweepParams(sweepIndex).timeLastAssociation = ueSweep.timeLastAssociation;
	end
end

function ueSweep = evaluateCurrentAngle(Simulation, ueSweep)
	% Performs the evaluation of the algorithm at the current angle 
	%
	% :param Simulation: Monster instance
	% :param ueSweep: current sweep state for a single UE
	% :returns ueSweep: updated sweep state

	% Scan reachable eNodeBs at current rotation angle
	Simulation.Logger.log('(MARITIME SWEEP - evaluateCurrentAngle) scanning for nearby eNodeBs', 'DBG');

	% Find UE in main Simulation list and initialise scan result
	user = Simulation.Users([Simulation.Users.NCellID] == ueSweep.ueId);
	% Set antenna bearing value based on current angle
	user.Rx.AntennaArray.Bearing = ueSweep.currentAngle;
	scanResult(1:length(Simulation.Stations)) = struct('eNodeBId', -1,'rxPowdBm', -realmax, 'sinr', -realmax);
	% Check over which metric we need to perform the sweep
	switch ueSweep.metric
		case 'sinr'
			sinrList = Simulation.Channel.getENBSINRList(user, Simulation.Stations, 'downlink');
			for iSinr = 1:length(sinrList)
				scanResult(iSinr).eNodeBId = Simulation.Stations(iSinr).NCellID;
				scanResult(iSinr).sinr = sinrList(iSinr);
			end
			% Identify the eNodeB with the highest SINR
			Simulation.Logger.log('(MARITIME SWEEP - evaluateCurrentAngle) analysing scan results for highest SINR', 'DBG');
			maxMetric = max([scanResult.sinr]);
			targetEnbId = scanResult([scanResult.sinr] == maxMetric).eNodeBId;
		case 'power'
			powerList = Simulation.Channel.getENBPowerList(user, Simulation.Stations, 'downlink');
			fieldsList = fieldnames(powerList);
			for iField = 1:numel(fieldsList)
				field = fieldsList{iField};
				listItem = powerList.(field);
				scanResult(iField).eNodeBId = listItem.NCellID;
				scanResult(iField).rxPowdBm = listItem.receivedPowerdBm;
			end
			% Identify the eNodeB with the highest received power
			Simulation.Logger.log('(MARITIME SWEEP - evaluateCurrentAngle) analysing scan results for highest rx power', 'DBG');
			maxMetric = max([scanResult.rxPowdBm]);
			targetEnbId = scanResult([scanResult.rxPowdBm] == maxMetric).eNodeBId;
		otherwise 
			Simulation.Logger.log('(MARITIME SWEEP - evaluateCurrentAngle) error, unsupported optimisation metric', 'ERR');
	end
	
	if targetEnbId ~= -1
		% Check whether this eNodeB id is already in the sweep state
		Simulation.Logger.log('(MARITIME SWEEP - evaluateCurrentAngle) identified best eNodeB, evaluating local state', 'DBG');
		searchResult = find([ueSweep.eNodeBList.eNodeBId] == targetEnbId, 1);
		if isempty(searchResult)
			% This eNodeBId is not present in the list, add it
			for iStation = 1:length(ueSweep.eNodeBList)
				if ueSweep.eNodeBList(iStation).eNodeBId == -1
					ueSweep.eNodeBList(iStation) = struct('eNodeBId', targetEnbId, 'angle', ueSweep.currentAngle, 'rxPowdBm', maxMetric, 'sinr', maxMetric);
					break;
				end
			end
		else
			% In this case, we have already the eNodeB in the list, let's check whether we need to update 
			currentEnBMetrics = ueSweep.eNodeBList(searchResult);
			switch ueSweep.metric
				case 'sinr'
					if maxMetric > currentEnBMetrics.sinr
						ueSweep.eNodeBList(searchResult).sinr = maxMetric;
						ueSweep.eNodeBList(searchResult).angle = ueSweep.currentAngle;
					end
				case 'power'
					if maxMetric > currentEnBMetrics.rxPowdBm
						ueSweep.eNodeBList(searchResult).rxPowdBm = maxMetric;
						ueSweep.eNodeBList(searchResult).angle = ueSweep.currentAngle;
					end
				otherwise 
					Simulation.Logger.log('(MARITIME SWEEP - evaluateCurrentAngle) error, unsupported optimisation metric', 'ERR');
			end
		end

		Simulation.Logger.log('(MARITIME SWEEP - evaluateCurrentAngle) updated local state evaluating rotation,', 'DBG');
		if ueSweep.rotationsPerformed < 360/ueSweep.rotationIncrement
			% Rotate
			Simulation.Logger.log('(MARITIME SWEEP - evaluateCurrentAngle) rotating antenna', 'DBG');
			ueSweep.rotationsPerformed = ueSweep.rotationsPerformed + 1;
			ueSweep.currentAngle = ueSweep.currentAngle + ueSweep.rotationIncrement;
			if ueSweep.currentAngle >= 360
				ueSweep.currentAngle = ueSweep.currentAngle - 360;
			end
		else
			ueSweep.rotationsPerformed = 0;
			% Full rotation completed, evaluate the local state
			Simulation.Logger.log('(MARITIME SWEEP - evaluateCurrentAngle) evaluating local state for best eNodeB', 'DBG');
			switch ueSweep.metric
				case 'sinr'
					maxMetric = max([ueSweep.eNodeBList.sinr]);
					maxEnodeBs = ueSweep.eNodeBList([ueSweep.eNodeBList.sinr] == maxMetric);
				case 'power'
					maxMetric = max([ueSweep.eNodeBList.rxPowdBm]);
					maxEnodeBs = ueSweep.eNodeBList([ueSweep.eNodeBList.rxPowdBm] == maxMetric);
				otherwise
					Simulation.Logger.log('(MARITIME SWEEP - evaluateCurrentAngle) error, unsupported optimisation metric', 'ERR');
			end
			
			% The case with 2 associations having the same SINR is rare, check in any case
			targetEnb = maxEnodeBs(1);
			% Once a full rotation is completed, evaluate whether a re-association should be done
			if user.ENodeBID ~= targetEnb.eNodeBId
				Simulation.Logger.log('(MARITIME SWEEP - evaluateCurrentAngle) associating with new target eNodeB', 'DBG');
				% Call the handler for the handover that will take care of processing the change
				[~, Simulation.Stations] = handleHangover(user, Simulation.Stations, targetEnb.eNodeBId, Simulation.Config);
				ueSweep.timeLastAssociation = Simulation.Config.Runtime.currentTime;
				ueSweep.currentAngle = targetEnb.angle;
				ueSweep.startAngle = targetEnb.angle;
				ueSweep.maxAngle = targetEnb.angle + 360;
			end
		end
	else
		% In this case, no eNodeB was found, exit 
		Simulation.Logger.log('(MARITIME SWEEP - evaluateCurrentAngle) no eNodeB found for search parameters', 'WRN');
		% TODO, should the antenna be rotated in this case?
		ueSweep.currentAngle = ueSweep.currentAngle + ueSweep.rotationIncrement;
	end
end
