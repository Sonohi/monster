function cfgLink = layout2Link(cfgLayout)
%LAYOUT2LINK Convert layout parameters to link parameters
%   CFGLINK = LAYOUT2LINK(CFGLAYOUT) returns extended set of link
%   parameters derived from the layout parameters, CFGLAYOUT.

% Copyright 2016 The MathWorks, Inc.

numStn = size(cfgLayout.Pairing, 2);
stnBS = cfgLayout.Stations(cfgLayout.Pairing(1,:)); 
stnMS = cfgLayout.Stations(cfgLayout.Pairing(2,:));
if isempty(coder.target)
    posBS = [stnBS.Pos]; 
    posMS = [stnMS.Pos];
    velMS = [stnMS.Velocity];
else
    posBS = coder.nullcopy(zeros(3, numStn));
    posMS = coder.nullcopy(zeros(3, numStn));
    velMS = coder.nullcopy(zeros(3, numStn));
    for i = 1:numStn
        posBS(:,i) = stnBS(i).Pos; 
        posMS(:,i) = stnMS(i).Pos;
        velMS(:,i) = stnMS(i).Velocity;
    end
end

% MS-BS distance
distBSToMS = sqrt((posBS(1,:)-posMS(1,:)).^2+(posBS(2,:)-posMS(2,:)).^2);
heightBS = posBS(3,:);
heightMS = posMS(3,:);

thetaBS = -atan2(posMS(2,:) - posBS(2,:), posMS(1,:) - posBS(1,:)) + pi/2;
thetaMS = pi + thetaBS;
thetaBS = prin_value(thetaBS*180/pi);
thetaMS = prin_value(thetaMS*180/pi);

directionMS = -atan2(velMS(2,:), velMS(1,:))+pi/2;
directionMS = directionMS * 180/pi;
velocityMS  = sqrt(sum(velMS.^2));

% linkpar struct with layout parameters included
cfgLink = struct('Stations',              cfgLayout.Stations, ...
                 'NofSect',               cfgLayout.NofSect, ...
                 'Pairing',               cfgLayout.Pairing, ...
                 'ScenarioVector',        cfgLayout.ScenarioVector, ...
                 'PropagConditionVector', cfgLayout.PropagConditionVector, ...
                 'ThetaBs',               thetaBS, ...
                 'ThetaMs',               thetaMS, ...
                 'MsHeight',              heightMS, ...
                 'BsHeight',              heightBS, ...
                 'MsBsDistance',          distBSToMS, ...
                 'MsVelocity',            velocityMS, ...
                 'MsDirection',           directionMS, ...
                 'StreetWidth',           cfgLayout.StreetWidth, ...
                 'NumFloors',             cfgLayout.NumFloors, ...
                 'NumPenetratedFloors',   cfgLayout.NumPenetratedFloors, ...
                 'Dist1',                 cfgLayout.Dist1);
end

function y = prin_value(x)
% Map inputs from (-inf,inf) to (-180,180)

y = mod(x,360); % [0, 359]
y = y - 360*floor(y/180); % [-180, 179]

end

% [EOF]
