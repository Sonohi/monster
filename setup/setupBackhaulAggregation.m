function Backhaul =setupBackhaulAggregation(Stations, Traffic, Config)
    %TODO: make comments describing this function.




    monsterLog('(SETUP - setupBackhaul) setting up backhaul', 'NFO');
    for iStation = 1:(Config.MacroEnb.number+Config.MicroEnb.number)
        Backhaul(iStation) = BackhaulAggregation(Stations(iStation), Traffic, Config);
    end

end 