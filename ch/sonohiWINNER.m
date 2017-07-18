classdef sonohiWINNER

    methods(Static)


function [AA, eNBIdx, userIdx] = configureAA(type,stations,users)


% Select antenna array based on station class.
if strcmp(type,'macro')
    AA(1) = winner2.AntennaArray('UCA', 8,  0.3);
elseif strcmp(type,'micro')
    AA(1) = winner2.AntennaArray('UCA', 1,  0.15);
else

    sonohilog(sprintf('Antenna type for %s BsClass not defined, defaulting...',type),'WRN')
    AA(1) = winner2.AntennaArray('UCA', 1,  0.3);
end

% User antenna array
AA(2) = winner2.AntennaArray('UCA', 1,  0.05);

% Assign AA(1) to all stations
eNBIdx = num2cell(ones(length(stations),1));

% For users use antenna configuration 2
userIdx = repmat(2,1,length(users));

end

function cfgLayout =initializeLayout(useridx, eNBidx, numLinks, AA, range)
% Initialize layout struct by antenna array and number of
% links.
cfgLayout = winner2.layoutparset(useridx, eNBidx, numLinks, AA, range);

end

function cfgLayout = addAssociated(cfgLayout, stations, users)
% Adds the index of the stations and users associated, e.g.
% how they link with the station and user objects.
cfgLayout.StationIdx = stations;
cfgLayout.UserIdx = users;

end


function cfgLayout = setPositions(cfgLayout, Stations, Users)
% Set the position of the base station
for iStation = 1:length(cfgLayout.StationIdx)
    cfgLayout.Stations(iStation).Pos(1:3) = int64(floor(Stations(cfgLayout.StationIdx(iStation)).Position(1:3)));
end

% Set the position of the users
% TODO: Add velocity vector of users
for iUser = 1:length(cfgLayout.UserIdx)
    cfgLayout.Stations(iUser+length(cfgLayout.StationIdx)).Pos(1:3) = int64(ceil(Users([Users.UeId] == cfgLayout.UserIdx(iUser)).Position(1:3)));
end

end

function cfgLayout =updateIndexing(cfgLayout,Stations)
% Change useridx of pairing to reflect
% cfgLayout.Stations, e.g. If only one station, user one is
% at cfgLayout.Stations(2)
for ll = 1:length(cfgLayout.Pairing(2,:))
    cfgLayout.Pairing(2,ll) =  length(cfgLayout.StationIdx)+ll;
end


end

function cfgLayout = setPropagationScenario(cfgLayout, Stations, Users, Ch)
numLinks = length(cfgLayout.Pairing(1,:));

for i = 1:numLinks
    userIdx = cfgLayout.UserIdx(cfgLayout.Pairing(2,i)-length(cfgLayout.StationIdx));
    stationIdx =  cfgLayout.StationIdx(cfgLayout.Pairing(1,i));
    cBs = Stations(stationIdx);
    cMs = Users([Users.UeId] == userIdx);
    % Apparently WINNERchan doesn't compute distance based
    % on height, only on x,y distance. Also they can't be
    % doubles...
    distance = Ch.getDistance(cBs.Position(1:2),cMs.Position(1:2));
    if cBs.BsClass == 'micro'
        if distance <= 50
            msg = sprintf('(Station %i to User %i) Distance is %s, which is less than supported for B4 with NLOS, swapping to B4 LOS',...
                stationIdx,userIdx,num2str(distance));
            sonohilog(msg,'NFO0');

            cfgLayout.ScenarioVector(i) = 3; % B1 Typical urban micro-cell
            cfgLayout.PropagConditionVector(i) = 1; %1 for LOS
        else
            cfgLayout.ScenarioVector(i) = 3; % B1 Typical urban micro-cell
            cfgLayout.PropagConditionVector(i) = 0; %0 for NLOS
        end
    elseif cBs.BsClass == 'macro'
        if distance < 50
            msg = sprintf('(Station %i to User %i) Distance is %s, which is less than supported for C2 NLOS, swapping to LOS',...
                stationIdx,userIdx,num2str(distance));
            sonohilog(msg,'NFO0');
            cfgLayout.ScenarioVector(i) = 11; %
            cfgLayout.PropagConditionVector(i) = 1; %
        else
            cfgLayout.ScenarioVector(i) = 11; % C2 Typical urban macro-cell
            cfgLayout.PropagConditionVector(i) = 0; %0 for NLOS
        end
    end


end

end

function cfgModel = configureModel(cfgLayout,Stations)
% Use maximum fft size
% However since the same BsClass is used these are most
% likely to be identical
sw = [Stations(cfgLayout.StationIdx).WaveformInfo];
swNfft = [sw.Nfft];
swSamplingRate = [sw.SamplingRate];
cf = max([Stations(cfgLayout.StationIdx).DlFreq]); % Given in MHz

frmLen = double(max(swNfft));   % Frame length

% Configure model parameters
% TODO: Determine maxMS velocity
maxMSVelocity = max(cell2mat(cellfun(@(x) norm(x, 'fro'), ...
    {cfgLayout.Stations.Velocity}, 'UniformOutput', false)));


cfgModel = winner2.wimparset;
cfgModel.CenterFrequency = cf*10e5; % Given in Hz
cfgModel.NumTimeSamples     = frmLen; % Frame length
cfgModel.IntraClusterDsUsed = 'yes';   % No cluster splitting
cfgModel.SampleDensity      = max(swSamplingRate)/50;    % To match sampling rate of signal
cfgModel.PathLossModelUsed  = 'yes';  % Turn on path loss
cfgModel.ShadowingModelUsed = 'yes';  % Turn on shadowing
cfgModel.SampleDensity = round(physconst('LightSpeed')/ ...
    cfgModel.CenterFrequency/2/(maxMSVelocity/max(swSamplingRate)));

end

    end

end
