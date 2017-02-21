[map, step] = load_power('scenario_rxpower.rem');
wrong = [28 31 69 70 86 135 165 168];
for j = 1 : length(wrong),
	i = wrong(j);
	filename = strcat('./pedestrian/realiz',num2str(i),'.mat');
	load(filename);
	path = pathloss(x, y, map, step);
	save(filename,'x','y','path','shadow','fading');
end
