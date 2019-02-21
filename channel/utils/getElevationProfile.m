function [numPoints,distVec,elavationProfile] = getElevationProfile(BuildingFootprints, txPos, rxPos)
			% Moves through the building footprints structure and gathers the
			% height. A resolution of 0.05 meters used. Outputs a distance vector
			%
			% :param txPos: Position consisting of x, y, z coordinates
			% :param rxPos: Position consisting of x, y, z coordinates
			% :returns: `numPoints` number of elevation points between txPos and rxPos
			% :returns: `distVec` vector with resolution 0.05 meters from txPos to rxPos
			% :returns: `elevationProfile` vector of height values
			elavationProfile(1) = 0;
			distVec(1) = 0;
			
			% Check if x and y are equal
			if txPos(1:2) == rxPos(1:2)
				numPoints = 0;
				distVec = 0;
				elavationProfile = 0;
			else
				
				% Walk towards rxPos
				signX = sign(rxPos(1)-txPos(1));
				
				signY = sign(rxPos(2)-txPos(2));
				
				avgG = (txPos(1)-rxPos(1))/(txPos(2)-rxPos(2))+normrnd(0,0.01); %Small offset
				position(1:2,1) = txPos(1:2);
				i = 2;
				max_i = 10e6;
				numPoints = 0;
				resolution = 0.05; % Given in meters
				
				while true
					if i >= max_i
						break;
					end
					
					% Check current distance
					distance = norm(position(1:2,i-1)'-rxPos(1:2));
					
					% Move position
					[moved_dist,position(1:2,i)] = move(position(1:2,i-1),signX,signY,avgG,resolution);
					distVec(i) = distVec(i-1)+moved_dist; %#ok
					
					% Check if new position is at a greater distance, if so, we
					% passed it.
					distance_n = norm(position(1:2,i)'-rxPos(1:2));
					if distance_n >= distance
						break;
					else
						% Check if we're inside a building
						fbuildings_x = obj.BuildingFootprints(obj.BuildingFootprints(:,1) < position(1,i) & obj.BuildingFootprints(:,3) > position(1,i),:);
						fbuildings_y = fbuildings_x(fbuildings_x(:,2) < position(2,i) & fbuildings_x(:,4) > position(2,i),:);
						
						if ~isempty(fbuildings_y)
							elavationProfile(i) = fbuildings_y(5); %#ok
							if elavationProfile(i-1) == 0
								numPoints = numPoints +1;
							end
						else
							elavationProfile(i) = 0; %#ok
						end
					end
					i = i+1;
				end
			end
			
			
			
			function [distance,position] = move(position,signX,signY,avgG,moveS)
				if abs(avgG) > 1
					moveX = abs(avgG)*signX*moveS;
					moveY = 1*signY*moveS;
					position(1) = position(1)+moveX;
					position(2) = position(2)+moveY;
					
				else
					moveX = 1*signX*moveS;
					moveY = (1/abs(avgG))*signY*moveS;
					position(1) = position(1)+moveX;
					position(2) = position(2)+moveY;
				end
				distance = sqrt(moveX^2+moveY^2);
			end
		end		