clear all 
close all

[Config, Stations, Users, Channel, Traffic, Results] = setup();

H = Channel.signalPowerMap(Stations, Users(1), 10);