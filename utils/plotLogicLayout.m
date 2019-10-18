function plotLogicLayout(Cells, Config, Plot)
  %plots the logic layout of the simulated scenario
  
  %Create adjencency matrix and names
  [adj, names] = adjencencyMatrix(Config, Cells);
  G = graph(adj, names);
  
  %Plot logic layout on the right figure
  figure(Plot.LogicLayoutFigure);
  plot(G);

end


function [adj, names] = adjencencyMatrix(Config, Cells)
  %This function creates an adjencency matrix of the size n by n, where n
  %is the number of elements
  
  adj = zeros(1,1);
  
  %Trafficsource
  names = {'Traffic Source'};
  n = 1;
  
  %Backhaul aggregation
  if Config.Backhaul.backhaulOn
    n= n+1;
    adj(n,n)= 0;
    names(n) = {'Aggregation'};
    adj(n-1,n)=1;
    adj(n,n-1)=1;
  end
  CellNumbers = zeros(Config.MacroEnb.sitesNumber*Config.MacroEnb.cellsPerSite...
    +Config.MicroEnb.sitesNumber*Config.MicroEnb.cellsPerSite,1);
  %Macrosites
  for iMacroSite = 1:Config.MacroEnb.sitesNumber
    n= n+1;
    names(n) = {strcat('Macro site', num2str(iMacroSite))};
    adj(n,n) = 0;
    adj(n-(1+(iMacroSite-1)*(Config.MacroEnb.cellsPerSite+1)),n)=1;
    adj(n,n-(1+(iMacroSite-1)*(Config.MacroEnb.cellsPerSite+1)))=1;
    %Macrocells
    for iCell = 1:Config.MacroEnb.cellsPerSite
      n= n+1;
      CellNumbers((iMacroSite-1)*Config.MacroEnb.cellsPerSite+iCell) = n;
      names(n) = {strcat('BS', num2str(Cells((iMacroSite-1)*Config.MacroEnb.cellsPerSite+iCell).NCellID))};
      adj(n,n) = 0;
      adj(n-iCell,n) = 1;
      adj(n,n-iCell) = 1;
    end
  end
  
  %Microsites
  for iMicroSite = 1:Config.MicroEnb.sitesNumber
    n= n+1;
    names(n) = {strcat('Micro site',num2str(iMicroSite+Config.MacroEnb.sitesNumber))};
    adj(n,n) = 0;
    adj(n-(1+(iMicroSite-1)*(Config.MicroEnb.cellsPerSite+1))...
      -(Config.MacroEnb.sitesNumber*Config.MacroEnb.cellsPerSite+Config.MacroEnb.sitesNumber),n)=1;
    adj(n,n-(1+(iMicroSite-1)*(Config.MicroEnb.cellsPerSite+1))...
      -(Config.MacroEnb.sitesNumber*Config.MacroEnb.cellsPerSite+Config.MacroEnb.sitesNumber))=1;
    %Microcells
    for iCell = 1:Config.MicroEnb.cellsPerSite
      n= n+1;
      CellNumbers(Config.MacroEnb.sitesNumber*Config.MacroEnb.cellsPerSite...
        +iCell+((iMicroSite-1)*Config.MicroEnb.cellsPerSite)) = n;
      names(n) = {strcat('BS', num2str(Cells(Config.MacroEnb.sitesNumber*Config.MacroEnb.cellsPerSite...
        +iCell+((iMicroSite-1)*Config.MicroEnb.cellsPerSite)).NCellID))};
      adj(n,n) = 0;
      adj(n-iCell,n) = 1;
      adj(n,n-iCell) = 1;
    end
  end
  
  %UEs
  for iCell = 1:length(Cells)
    AssociatedUsers = Cells(iCell).AssociatedUsers;
    for iUser = 1:length(AssociatedUsers)
      n= n+1;
      names(n) = {strcat('UE',num2str(AssociatedUsers(iUser).UeId))};
      adj(n,n) = 0;
      adj(n,CellNumbers(iCell)) = 1;
      adj(CellNumbers(iCell),n) = 1;
    end
  end
end