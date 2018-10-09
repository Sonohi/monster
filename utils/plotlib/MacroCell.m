%Class defining all relevant coordinates for a site with 3 sectors.
classdef MacroCell < BaseCell

    %Properties
    properties 

        CellRadius;
        Area;
        MicroPos;
        PicoPos;
    end

    methods 
        function obj = MacroCell(xc, yc, Param, cellId)
            %Constructor
            obj = obj@BaseCell(xc, yc, Param, cellId, 'macro')
            %Set arguments
            obj.CellRadius = obj.Radius/3;
            obj.Area    = 3*2*sqrt(3)*(obj.CellRadius)^2; %Total area of all three cells belonging to that site
            obj.computeMicroPos();
            obj.computePicoPos(Param);
        end

    end

    methods (Access = private)
        %Compute the possible micro positions
        function obj = computeMicroPos(obj)
            microPos = zeros(9,2);
            p=0;
            theta = 2*pi/3;
            %3 cells per macro site
            for i=1:3
                %3 micro pos per macro cell
                for j=1:3
                    p=p+1;
                    microPos(p,1) = obj.Center(1) + obj.CellRadius*cos((i-1)*theta) + obj.CellRadius/2 * cos((p-1)*theta);
                    microPos(p,2) = obj.Center(2) + obj.CellRadius*sin((i-1)*theta) + obj.CellRadius/2 * sin((p-1)*theta);
                end
            end
            obj.MicroPos =microPos;
        end

        %Compute random pico pos within the different cells
        function obj = computePicoPos(obj, Param)
            %Picocells pr macro site
            picoPos = zeros(floor(Param.numPico/Param.numMacro),2);
            iPico = 1;
            theta = 2*pi/3;
            while iPico <= length(picoPos(:,1))

                %Choose random position, within the grid 
                phi = rand * 2 * pi;                
                r = sqrt(rand) * sqrt(3)/2*obj.CellRadius;
                x = r * cos(phi) + obj.Center(1) + obj.CellRadius*cos((iPico-1)*theta);
                y = r * sin(phi) + obj.Center(2) + obj.CellRadius*sin((iPico-1)*theta);
                valid = true ;

                %Avoid placement too close to macro BST
                d = sqrt((obj.Center(1) - x) ^ 2 + (obj.Center(2) - y) ^ 2);
                if d < 20
                    valid = false;
                end
                %Avoid placement too close to micro BST
                for m = 1:9
                    d = sqrt((obj.MicroPos(m, 1) - x) ^ 2 + (obj.MicroPos(m, 2) - y) ^ 2);
                    if (d < 20)
                        valid = false;
                    end
                end
                %Avoid placement too close to another pico BST
                for m = 1:iPico-1
                    d = sqrt((picoPos(m, 1) - x) ^ 2 + (picoPos(m, 2) - y) ^ 2);
                    if (d < 15)
                        valid = false;
                    end
                end
                if valid 
                    picoPos(iPico,:)=[x y];
                    iPico = iPico+1;
                end
            end

            obj.PicoPos=picoPos;
        end
    end

end
