% Create Stations, Users and Traffic generators
Param.draw = 0;
Param.channel.modeDL = '3GPP38901';
Param.channel.region = struct();
Param.channel.region.macroScenario = 'UMa';
Param.channel.region.microScenario = 'UMi';
Param.channel.region.picoScenario = 'UMi';
Param.numMacro = 1;
Param.numMicro = 0;
Param.numPico = 0;
[Stations, Param] = createBaseStations(Param);
Users = createUsers(Param);
% Create Channel scenario
Channel = ChBulk_v2(Stations, Users, Param);

distance = linspace(1,300);
results = nan(1,length(distance));
for dist = 1:length(distance)
	Users(1).Position(1:2) = [Stations(1).Position(1)+distance(dist), Stations(1).Position(2)]; 
	[LOS, prop, x, dist2d] = Channel.DownlinkModel.LOSprobability(Channel, Stations(1), Users(1));
	results(dist) = prop;
end
 
figure
plot(distance,results)
ylim([0 1.1])
xlabel('Distance (m)')
ylabel('Probability for LOS')
legend('UMa - Table 7.4.2')
grid on