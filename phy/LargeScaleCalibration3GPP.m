clear all
close all

%% Construct antenna array per table 7.8-1
% 1 x 1 Panel with 10 x 1 antenna elements at 1 polarization spaced with
% 0.5lambda. Tilted at 102 degrees for UMa

% Sector 1
aaSector1 = AntennaArray([1, 1, 10, 1, 1], 30, 102);

% Sector 2
aaSector2 = AntennaArray([1, 1, 10, 1, 1], 150, 102);

% Sector 3
aaSector3 = AntennaArray([1, 1, 10, 1, 1], 270, 102);

% Visualize radiation pattern

elements = aaSector1.Panels{1};
elements{1}.plotPattern()

theta = 0:180; % Elevation
phi = -180:180; % Azimuth
figure
plot(phi,elements{1}.get3DGain(90,phi))
xlabel('Azimuth (degrees)')
ylabel('Antenna gain (dB)')

figure
plot(elements{1}.get3DGain(theta,0), theta)
set(gca,'Ydir','reverse')
ylabel('Elevation (degrees)')
xlabel('Antenna gain (dB)')