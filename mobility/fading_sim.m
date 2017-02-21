offset = 180;

numRBs = 1;
fc = 2.4e9;
time_interval = 0.001;
T = 250000;
scenario = 1;

for (i = offset + 1 : offset + 20),
    fading = fast_fading(fc, 1.5, numRBs, T, scenario, time_interval);
    save(strcat('./fading/fading_ped_', num2str(i), '.mat'), 'fading');
end
