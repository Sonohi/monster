function [macroPos, microPos, picoPos, Param] = positionBaseStations (maBS, miBS, piBS, Param)

%   POSITION BASE STATIONS is used to set up the physical location of BSs
%
%   Function fingerprint
%   maBS      ->  number of macro base stations
%   miBS      ->  number of micro base stations
% 	piBS			-> 	number of pico base stations
%   buildings ->  building position matrix
%
%   macroPos ->  positions of the macro base stations
%   microPos ->  positions of the micro base stations
% 	picoPos	 ->	 positions of the pico base stations

%Create position vectors
macroPos = zeros(maBS, 2);
microPos = zeros(miBS, 2);
picoPos = zeros(piBS, 2);
buildings = Param.buildings;

%Find simulation area
area = [min(buildings(:, 1)), min(buildings(:, 2)), max(buildings(:, 3)), ...
	max(buildings(:, 4))];

% Macro BS positioned at centre with single BS
if (maBS == 1)
	xc = (area(3) - area(1))/2;
	yc = (area(4) - area(2))/2;
	macroPos(maBS, :) = [xc yc];
	if Param.draw
		text(Param.LayoutAxes,xc,yc-20,strcat('Macro BS (',num2str(round(xc)),', ',num2str(round(yc)),')'),'HorizontalAlignment','center');
		[macroImg, ~, alpha] = imread('utils/images/macro.png');
		% For some magical reason the image is rotated 180 degrees.
		macroImg = imrotate(macroImg,180);
		alpha = imrotate(alpha,180);
		% Scale size of figure
		scale = 30;
		macroLengthY = length(macroImg(:,1,1))/scale;
		macroLengthX = length(macroImg(1,:,1))/scale;
		% Position and set alpha from png image
		f = imagesc(Param.LayoutAxes,[xc-macroLengthX xc+macroLengthX],[yc yc+macroLengthY*2],macroImg);
		set(f, 'AlphaData', alpha);
	end
end

%Micro BS positioning
if Param.numMicro > 0
	if Param.draw
		[microImg, ~, alpha] = imread('utils/images/micro.png');
		% For some magical reason the image is rotated 180 degrees.
		microImg = imrotate(microImg,180);
		alpha = imrotate(alpha,180);
		% Scale size of figure
		scale = 30;
		microLengthY = length(microImg(:,1,1))/scale;
		microLengthX = length(microImg(1,:,1))/scale;
	end

	switch Param.microPos
		case 'uniform'
			% place the micro bs in a circle of radius around the centre
			theta = 2*pi/miBS;
			rho = 0;
			r = Param.microUniformRadius;
			xc = (area(3) - area(1))/2;
			yc = (area(4) - area(2))/2;
			for iMicro = 1:miBS
				xr = xc + r*cos(rho+iMicro*theta);
				yr = yc + r*sin(rho+iMicro*theta);
				microPos(iMicro, :) = [xr yr];
				if Param.draw
					text(xr,yr+20,strcat('Micro BS ', num2str(iMicro+1),' (',num2str(round(xr)),', ', ...
						num2str(round(yr)),')'),'HorizontalAlignment','center','FontSize',9);
					
					f = imagesc(Param.LayoutAxes,[xr-microLengthX xr+microLengthX],[yr yr+microLengthY*2],microImg);
					set(f, 'AlphaData', alpha);
					drawnow
				end
			end
		case 'random'
			for (i = 1 : miBS)
				valid = false;
				while (~valid)
					x = rand * (area(3) + area(1)) - area(1);
					y = rand * (area(4) + area(2)) - area(2);
					for (b = 1 : length(buildings(:, 1)))
						if (x > buildings(b, 1) && x < buildings(b, 3) && y > buildings(b, 2) && y < buildings(b, 4))
							valid = true;
						end
					end
					for (m = 1 : maBS)
						d = sqrt((macroPos(m, 1) - x) ^ 2 + (macroPos(m, 2) - y) ^ 2);
						if (d < 20)
							valid = false;
						end
					end
					
					for (m = 1 : i - 1)
						d = sqrt((microPos(m, 1) - x) ^ 2 + (microPos(m, 2) - y) ^ 2);
						if (d < 20)
							valid = false;
						end
					end
				end
				microPos(i, :) = [x y];
				if Param.draw
					text(x,y+20,strcat('Micro BS ', num2str(i+1),' (',num2str(round(x)),', ', ...
						num2str(round(y)),')'),'HorizontalAlignment','center','FontSize',9);
					
					f = imagesc(Param.LayoutAxes,[x-microLengthX x+microLengthX],[y y+microLengthY*2],microImg);
					set(f, 'AlphaData', alpha);
					drawnow
				end
			end
			
		case 'clusterized'
			clusters = zeros(Param.numClusters, 2);
			perCluster = miBS / Param.numClusters;
			for (i = 1 : Param.numClusters),
				%% TODO set cluster center
				clusterCenter = [0 0];
				valid = false;
				while (~valid),
					rho = rand * Param.macroRadius;
					if (rho < Param.minClusterDist),
						valid = false;
						continue;
					end
					theta = rand * 2 * pi;
					x = macroPos(1, 1) + rho * cos(theta);
					y = macroPos(1, 1) + rho * sin(theta);
					valid = true;
					for (j = 1 : i - 1),
						if (sqrt((x - clusters(j, 1)) ^ 2 + (y - clusters(j, 2)) ^ 2) < Param.interClusterDist),
							valid = false;
						end
					end
				end
				clusterCenter = [x y];
				clusters(i, :) = [x y];
				for (j = 1 : perCluster),
					valid = false;
					while (~valid),
						rho = rand * Param.microClusterRadius;
						theta = rand * 2 * pi;
						x = clusterCenter(1) + rho * cos(theta);
						y = clusterCenter(2) + rho * sin(theta);
						valid = true;
						for (k = 1 : j - 1 + perCluster * (i - 1)),
							if (sqrt((x - microPos(k, 1)) ^ 2 + (y - microPos(k, 2)) ^ 2) < Param.microDist),
								valid = false;
							end
						end
					end
					microPos(j + (i - 1) * perCluster, :) = [x y];
				end
			end
			for (i = 1 : miBS),
				x = microPos(i, 1);
				y = microPos(i, 2);
				if Param.draw
					text(x,y+20,strcat('Micro BS ', num2str(i+1),' (',num2str(round(x)),', ', ...
						num2str(round(y)),')'),'HorizontalAlignment','center','FontSize',9);
					
					f = imagesc(Param.LayoutAxes,[x-microLengthX x+microLengthX],[y y+microLengthY*2],microImg);
					set(f, 'AlphaData', alpha);
					drawnow
				end
			end
			Param.clusters = clusters;
			
		otherwise
			sonohiLog('Unknown choice for micro BS positioning strategy', 'ERR');
	end
end

%Pico BS positioning
if Param.numPico > 0
	if Param.draw
		[picoImg, ~, alpha] = imread('utils/images/pico.png');
		% For some magical reason the image is rotated 180 degrees.
		picoImg = imrotate(picoImg,180);
		alpha = imrotate(alpha,180);
		% Scale size of figure
		scale = 30;
		picoLengthY = length(picoImg(:,1,1))/scale;
		picoLengthX = length(picoImg(1,:,1))/scale;
	end
	switch Param.picoPos
		case 'uniform'
			% place the pico bs in a circle of radius around the centre
			theta = 2*pi/piBS;
			rho = 0;
			r = Param.picoUniformRadius;
			xc = (area(3) - area(1))/2;
			yc = (area(4) - area(2))/2;
			for iPico = 1:piBS
				xr = xc + r*cos(rho+iPico*theta);
				yr = yc + r*sin(rho+iPico*theta);
				picoPos(iPico, :) = [xr yr];
				if Param.draw
					text(xr,yr+20,strcat('Pico BS ', num2str(iPico+1),' (',num2str(round(xr)),', ', ...
						num2str(round(yr)),')'),'HorizontalAlignment','center','FontSize',9);
					
					f = imagesc(Param.LayoutAxes,[xr-picoLengthX xr+picoLengthX],[yr yr+picoLengthY*2],picoImg);
					set(f, 'AlphaData', alpha);
					drawnow
				end
			end
		case 'random'
			for i = 1 : piBS
				valid = false;
				while (~valid)
					x = rand * (area(3) + area(1)) - area(1);
					y = rand * (area(4) + area(2)) - area(2);
					for (b = 1 : length(buildings(:, 1)))
						if (x > buildings(b, 1) && x < buildings(b, 3) && y > buildings(b, 2) && y < buildings(b, 4))
							valid = true;
						end
					end
					for m = 1 : maBS
						d = sqrt((macroPos(m, 1) - x) ^ 2 + (macroPos(m, 2) - y) ^ 2);
						if (d < 20)
							valid = false;
						end
					end
					
					for m = 1 : i - 1
						d = sqrt((picoPos(m, 1) - x) ^ 2 + (picoPos(m, 2) - y) ^ 2);
						if (d < 20)
							valid = false;
						end
					end
				end
				picoPos(i, :) = [x y];
				if Param.draw
					text(x,y+20,strcat('Pico BS ', num2str(i+1),' (',num2str(round(x)),', ', ...
						num2str(round(y)),')'),'HorizontalAlignment','center','FontSize',9);
					
					f = imagesc(Param.LayoutAxes,[x-picoLengthX x+picoLengthX],[y y+picoLengthY*2],picoImg);
					set(f, 'AlphaData', alpha);
					drawnow
				end
			end
		otherwise
			sonohiLog('Unknown choice for pico BS positioning strategy', 'ERR');
	end
end

% Draw grid
if Param.draw
	for i = 1:length(buildings(:,1))
		x0 = buildings(i,1);
		y0 = buildings(i,2);
		x = buildings(i,3)-x0;
		y = buildings(i,4)-y0;
		rectangle(Param.LayoutAxes,'Position',[x0 y0 x y],'FaceColor',[0.9 .9 .9 0.4],'EdgeColor',[1 1 1 0.6])
	end
	
	% Plot 3d manhattan grid.
	%h2 = figure;
	%set(gca, 'XTick', []);
	%set(gca, 'YTick', []);
	%set(gca,'Visible','off')
	%hold on
	%for i = 1:length(buildings(:,1))
	%   x0 = buildings(i,1);
	%   y0 = buildings(i,2);
	%   x = buildings(i,3);
	%   y = buildings(i,4);
	%   z = buildings(i,5);
	%   verts = [x0 y0 0; x y0 0; x y 0; x0 y 0;
	%             x0 y0 z; x y0 z; x y z; x0 y z];
	%   fac = [1 2 3 4; 2 3 7 6; 1 2 6 5; 4 3 7 8;
	%             5 8 7 6; 1 4 8 5];
	%   patch('Vertices',verts,'Faces',fac,'FaceColor',[0.9 .9 .9])
	%end
	drawnow
end



end
