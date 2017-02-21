function run_scenario( sim, scenario )

rng('shuffle');
time_interval = 0.001;
fc = 2.4e9; %Hz
numRBs = 1;
BS_position = [0 0]; %base station position
do = 1;  % m
Lcorr = 8.0 % shadowing correlation length [m]
sigma = 4; % sigma log normal, 4, 8 ,16

% TODO finish mobility model
valid = false;
while (~valid),
    [x, y, valid] = mobility(scenario);
end

if (scenario == 1), % pedestrian
    filename = strcat('pedestrian_realiz', num2str(sim), '.mat');
end
if scenario == 2 % vehicular
    filename = strcat('vehicular_realiz', num2str(sim), '.mat');
end

if (scenario ~= 1 && scenario ~= 2),
    return;
end

v = zeros(1, length(x) - 1);
for (i = 1 : length(x) - 1),
    v(i) = dist_2d(x(i), y(i), x(i + 1), y(i + 1));
end

traceDuration = length(x) * time_interval;

%[pathloss_map, map_step] = load_power('scenario_rxpower.rem');
pathloss_vector = 0; %pathloss(x, y, pathloss_map, map_step);
%fading = fast_fading(fc, mean(v), numRBs, traceDuration, scenario, time_interval);
shadow = 0;%shadowing(fc, Lcorr, sigma, mean(v), traceDuration, time_interval);

%save(filename, 'x', 'y', 'pathloss_vector','shadow');

end
