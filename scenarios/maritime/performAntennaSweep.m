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
		sweepCompleted = false;
		while ~sweepCompleted
			[ueSweep, sweepCompleted] = evaluateCurrentAngle(Simulation, ueSweep);
		end

		% Once the sweep is completed, save the result in the return structure
		sweepParams(sweepIndex).eNodeBList = ueSweep.eNodeBList;
		sweepParams(sweepIndex).timeLastAssociation = ueSweep.timeLastAssociation;

	end
end

function [ueSweep, sweepCompleted] = evaluateCurrentAngle(Simulation, ueSweep)
	% Performs the evaluation of the algorithm at the current angle 
	%
	% :param Simulation: Monster instance
	% :param ueSweep: current sweep state for a single UE
	% :returns ueSweep: updated sweep state
	% :returns sweepCompleted: boolean to control the sweep outer recursion

	% Scan reachable eNodeBs at current rotation angle
	monsterLog('(MARITIME SWEEP - evaluateCurrentAngle) scanning for nearby eNodeBs', 'NFO');

	% Find UE in main Simulation list and initialise scan result
	user = Simulation.Users([Simulation.Users.NCellID] == ueSweep.ueId);
	scanResult(1:length(Simulation.Stations)) = struct('eNodeBId', -1,'rxPowdBm', -realmax, 'sinr', -realmax);
	% Check over which metric we need to perform the sweep
	if strcmp(ueSweep.metric, 'sinr')
		sinrList = Simulation.Channel.ChannelModel.getENBSINRList(user, Simulation.Stations, 'downlink');
	elseif strcmp(ueSweep.metric, 'power')
		powerList = Simulation.Channel.ChannelModel.getENBPowerList(user, Simulation.Stations, 'downlink');
		fieldsList = fieldnames(powerList);
		for iField = 1:numel(fieldsList)
			field = fieldsList{iField};
			listItem = powerList.(field);
			scanResult(iField).eNodeBId = listItem.NCellID;
			scanResult(iField).rxPowdBm = listItem.receivedPowerdBm;
		end
		% Identify the eNodeB with the highest received power
		monsterLog('(MARITIME SWEEP - evaluateCurrentAngle) analysing scan results', 'NFO');
		maxMetric = max([scanResult.rxPowdBm]);
		targetEnbId = scanResult([scanResult.rxPowdBm] == maxMetric).eNodeBId;
	else 
		monsterLog('(MARITIME SWEEP - evaluateCurrentAngle) error, unsupported optimisation metric', 'ERR');
	end
	
	if targetEnbId ~= -1
		% Check whether this eNodeB id is already in the sweep state
		monsterLog('(MARITIME SWEEP - evaluateCurrentAngle) identified best eNodeB, evaluating local state', 'NFO');
		searchResult = find([ueSweep.eNodeBList.eNodeBId] == targetEnbId, 1);
		if isempty(searchResult)
			% This eNodeBId is not present in the list, add it
			for iStation = 1:length(ueSweep.eNodeBList)
				if ueSweep.eNodeBList(iStation).eNodeBId == 0
					ueSweep.eNodeBList(iStation) = struct('eNodeBId', targetEnbId, 'angle', ueSweep.currentAngle, 'rxPowdBm', maxMetric, 'sinr', maxMetric);
					break;
				end
			end
		end

		monsterLog('(MARITIME SWEEP - evaluateCurrentAngle) updated local state evaluating rotation,', 'NFO');
		if ueSweep.currentAngle < ueSweep.maxAngle - ueSweep.rotationIncrement
			% Sweep not completed, evaulate rotation
			monsterLog('(MARITIME SWEEP - evaluateCurrentAngle) evaluating hysteresis for rotation', 'NFO');
			if Simulation.Config.Runtime.currentTime - ueSweep.timeLastAssociation >= ueSweep.hysteresisTimer
				monsterLog('(MARITIME SWEEP - evaluateCurrentAngle) rotating antenna', 'NFO');
				ueSweep.currentAngle = ueSweep.currentAngle + ueSweep.rotationIncrement;
				sweepCompleted = false;
				monsterLog('(MARITIME SWEEP - evaluateCurrentAngle) evaluation at current angle completed', 'NFO');
			else
				% TODO how to handle this case? The UE needs to "wait", evaluate whether the loop should be broken
				monsterLog('(MARITIME SWEEP - evaluateCurrentAngle) unsupported case', 'ERR');
			end
		else
			% Sweep completed, evaluate the local state
			monsterLog('(MARITIME SWEEP - evaluateCurrentAngle) evaluating local state for best eNodeB', 'NFO');
			if strcmp(ueSweep.metric, 'sinr')
				maxMetric = max([ueSweep.eNodeBList.sinr]);
				maxEnodeBs = ueSweep.eNodeBList([ueSweep.eNodeBList.sinr] == maxMetric);
			elseif strcmp(ueSweep.metric, 'power')
				maxMetric = max([ueSweep.eNodeBList.rxPowdBm]);
				maxEnodeBs = ueSweep.eNodeBList([ueSweep.eNodeBList.rxPowdBm] == maxMetric);
			else
				monsterLog('(MARITIME SWEEP - evaluateCurrentAngle) error, unsupported optimisation metric', 'ERR');
			end
			
			% The case with 2 associations having the same SINR is rare, check in any case
			targetEnb = maxEnodeBs(1);
			% Update the rotation parameters
			angleMaxMetric = targetEnb.angle;
			ueSweep.currentAngle = angleMaxMetric - ueSweep.rotationIncrement;
			ueSweep.maxAngle = 2*ueSweep.rotationIncrement;
			ueSweep.rotationIncrement = ueSweep.rotationIncrement/2;

			% Evaluate the max angle and see whether we should stop the sweep
			if ueSweep.maxAngle <= ueSweep.minAngle
				sweepCompleted = true;
				monsterLog('(MARITIME SWEEP - evaluateCurrentAngle) sweep completed, evaluating whether to re-associate', 'NFO');
				if user.ENodeBID ~= targetEnb.eNodeBId
					monsterLog('(MARITIME SWEEP - evaluateCurrentAngle) associating with new target eNodeB', 'NFO');
					% Call the handler for the handover that will take care of processing the change
					[~, Simulation.Stations] = handleHangover(user, Simulation.Stations, targetEnb.eNodeBId, Simulation.Config);
					ueSweep.timeLastAssociation = Simulation.Config.Runtime.currentTime;
				end
			else
				% In this case the sweep is not completed, so we should return to the main loop 
				% and repeat the search for a new sweep angle
				sweepCompleted = false;
			end
		end
	else
		% In this case, no eNodeB was found, exit 
		monsterLog('(MARITIME SWEEP - evaluateCurrentAngle) no eNodeB found for search parameters', 'WRN');
		% TODO, should the antenna be rotated in this case?
		ueSweep.currentAngle = ueSweep.currentAngle + ueSweep.rotationIncrement;
		sweepCompleted = false;
	end
end
