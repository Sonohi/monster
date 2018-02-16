function [macroPos, microPos, h, Param] = positionBaseStations (maBS, miBS, Param)

%   POSITION BASE STATIONS is used to set up the physical location of BSs
%
%   Function fingerprint
%   maBS      ->  number of macro base stations
%   miBS      ->  number of micro base stations
%   buildings ->  building position matrix
%
%   macroPos ->  positions of the macro base stations
%   microPos ->  positions of the micro base stations

%Create position vectors
macroPos = zeros(maBS, 2);
microPos = zeros(miBS, 2);
buildings = Param.buildings;

%Find simulation area
area = [min(buildings(:, 1)), min(buildings(:, 2)), max(buildings(:, 3)), ...
    max(buildings(:, 4))];

% Draw grid
if Param.draw
    h = figure;
    %rectangle('Position',area)
    set(gca, 'XTick', []);
    set(gca, 'YTick', []);
    hold on
    for i = 1:length(buildings(:,1))
        x0 = buildings(i,1);
        y0 = buildings(i,2);
        x = buildings(i,3)-x0;
        y = buildings(i,4)-y0;
        rectangle('Position',[x0 y0 x y],'FaceColor',[0.9 .9 .9])
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
else
    h = [];
end

% Macro BS positioned at centre with single BS
if (maBS == 1)
    xc = (area(3) - area(1))/2;
    yc = (area(4) - area(2))/2;
    macroPos(maBS, :) = [xc yc];
    if Param.draw
        text(xc,yc-6,strcat('Macro BS (',num2str(round(xc)),', ',num2str(round(yc)),')'),'HorizontalAlignment','center')
        [im, map, alpha] = imread('utils/images/basestation.png');
        % For some magical reason the image is rotated 180 degrees.
        im = imrotate(im,180);
        alpha = imrotate(alpha,180);
        % Scale size of figure
        scale = 40;
        ylength = length(im(:,1,1))/scale;
        xlength = length(im(1,:,1))/scale;
        % Position and set alpha from png image
        f = imagesc([xc-xlength xc+xlength],[yc yc+ylength*2],im);
        set(f, 'AlphaData', alpha);
    end
end

%Micro BS positioning
switch Param.microPos
    case 'uniform'
        % place the micro bs in a circle of radius around the centre
        theta = 2*pi/miBS;
        alpha = 0;
        r = Param.microUniformRadius;
        xc = (area(3) - area(1))/2;
        yc = (area(4) - area(2))/2;
        for iMicro = 1:miBS
            xr = xc + r*cos(alpha+iMicro*theta);
            yr = yc + r*sin(alpha+iMicro*theta);
            microPos(iMicro, :) = [xr yr];
            if Param.draw
                text(xr,yr-6,strcat('Micro BS ', num2str(iMicro+1),' (',num2str(round(xr)),', ', ...
                    num2str(round(yr)),')'),'HorizontalAlignment','center','FontSize',9);
                
                rectangle('Position',[xr-5 yr-5 10 10],'Curvature',[1 1],'EdgeColor', ...
                    [0 .5 .5],'FaceColor',[0 .5 .5]);
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
                text(x,y-6,strcat('Micro BS ', num2str(i+1),' (',num2str(round(x)),', ', ...
                    num2str(round(y)),')'),'HorizontalAlignment','center','FontSize',9);
                
                rectangle('Position',[x-5 y-5 10 10],'Curvature',[1 1],'EdgeColor',[0 .5 .5],'FaceColor',[0 .5 .5]);
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
                text(x,y-6,strcat('Micro BS ', num2str(i+1),' (',num2str(round(x)),', ', ...
                    num2str(round(y)),')'),'HorizontalAlignment','center','FontSize',9);
                
                rectangle('Position',[x-5 y-5 10 10],'Curvature',[1 1],'EdgeColor',[0 .5 .5],'FaceColor',[0 .5 .5]);
            end
        end
        Param.clusters = clusters;
        
    otherwise
        sonohiLog('Unknown choice for micro BS positioning strategy', 'ERR');
        
end

end
