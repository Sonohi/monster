close all
clc
clearvars

%addpath(genpath('./comm/'),genpath('./commutilities'));

scenario = 1; %1 --> pedestrianEPA 2--> vehicularEVA
offset = 0;

for (sim = offset + 1 : offset + 10),
    run_scenario(sim, scenario);
end
