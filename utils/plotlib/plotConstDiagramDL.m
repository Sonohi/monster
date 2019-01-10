function plotConstDiagramDL(Stations,Users, Config)
	for user = 1:length(Users)

		rxTag = sprintf('user%iRxConstDL',user);
		eqTag = sprintf('user%iEqConstDL',user);

		% Find axes in plot
		% If the constellation diagrams have been added before, delete them
		axEq = findall(Config.Plot.PHYAxes,'Tag',eqTag);
		hEq = get(axEq,'Children');

		if ~isempty(hEq)
			delete(hEq)
		end

		axRx = findall(Config.Plot.PHYAxes,'Tag',rxTag);

		hRx = get(axRx,'Children');

		if ~isempty(hRx)
			delete(hRx)
		end

		dims = size(Users(user).Rx.Subframe);
		sps = 1;
		if dims ~= [0 0]
			iServingStation = find([Stations.NCellID] == Users(user).ENodeBID);
			[indPdsch, info] = Stations(iServingStation).getPDSCHindicies;
			rxSubFrame = Users(user).Rx.Subframe(indPdsch);
			eqSubFrame = Users(user).Rx.EqSubframe(indPdsch);
			plot(axRx, rxSubFrame,'.');
			set(axRx,'Tag',rxTag);
			title(axRx,strcat('User: ',num2str(user)));

			plot(axEq, eqSubFrame,'.');
			set(axEq,'Tag',eqTag);
			title(axEq,strcat('User: ',num2str(user)));
			%ylabel('Quadrature');
			%xlabel('Inphase');
			%set(hs(pp),'FontSize',8);

		end

	end
	drawnow
end