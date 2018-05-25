function [ x, y ] = traffic_mobility ( scenario, velocity, seed, timestep )
% Set base seed
rng(seed);

% load buildings and parameters
buildings = load_buildings('buildings.txt');
road_width = 9;
lane_width = road_width / 3;
wall_distance = 0.5 * scenario;
pedestrian_distance = 0.5;
pedestrian_turn_pause = 0.2 / timestep;
pedestrian_crossing_pause = 5 / timestep;

valid = false;

while (~valid)
    % starting point and destination
    start = randi(length(buildings(1, :)));
    stop = randi(length(buildings(1, :)));
    start_side = randi(4);
    stop_side = randi(4);
    if scenario == 1
        [x0, y0] = exit_point(buildings(:, start), start_side, wall_distance);
        [xf, yf] = exit_point(buildings(:, stop), stop_side, wall_distance);
    else
        % check that the point is on a valid road
        x0 = 1E9;
        xf = 1E9;
        y0 = 1E9;
        yf = 1E9;
        roads = load_roads('roads.txt');
        while (length(find_road(x0, y0, roads)) == 0 || length(find_road(xf, yf, roads)) == 0),
            [x0, y0] = exit_point(buildings(:, start), start_side, wall_distance + lane_width / 2);
            [xf, yf] = exit_point(buildings(:, stop), stop_side, wall_distance + lane_width / 2);
            start = randi(length(buildings(1, :)));
            stop = randi(length(buildings(1, :)));
            start_side = randi(4);
            stop_side = randi(4);
        end
    end
    
    % initialize values
    t_ms = 1;
    x = x0;
    y = y0;
    valid = false;
    
    % static scenario
    if (velocity <= 0),
        duration = 60 * 1000 * 10; % 10 minutes
        x = ones(1, duration) * x0;
        y = ones(1, duration) * y0;
        return;
    end
    
    % pedestrian scenario simulation
    if (scenario == 1),
        % add wall distance to the buildings
        corners = zeros(2, length(buildings(1, :)) * 4);
        for (i = 1 : length(buildings(1, :))),
            corners(:, 4 * (i - 1) + 1 : 4 * i) = add_walldist(buildings(:, i), wall_distance);
        end
        
        % initialize current building and direction value
        building_path = start;
        current_building = start;
        dir = 0;
        prev_corner = [1E9 1E9];
        
        % movement
        while (current_building ~= stop),
            building_path = [building_path current_building];
            if(t_ms > 2 * 1E5),
                return;
            end
            
            % decision: cross or keep on the same building
            if (t_ms > 1),
                % cross or keep moving
                [x_cross, y_cross, crossing_time, crossing, dir] =pedestrian_crossing(x(t_ms), y(t_ms), xf, yf, velocity, buildings(:, current_building), road_width, pedestrian_turn_pause, pedestrian_crossing_pause, dir, timestep);
                t_ms = t_ms + crossing_time;
                x = [x x_cross];
                y = [y y_cross];
                if (crossing),
                    current_building = ceil(find_closest_corner(x(t_ms), y(t_ms), corners) / 4);
                    continue;
                end
            end
            
            % find the corner that takes the pedestrian closer to the end
            building_corners = adjacent_corners(corners(:, 4 * (current_building - 1) + 1 : 4 * current_building), x(t_ms), y(t_ms));
            [index, xc, yc] = find_closest_corner(xf, yf, building_corners);
            
            % do not go back
            if (dist_2d(xc, yc, prev_corner(1), prev_corner(2)) < 1),
                building_corners(:, index) = [];
                xc = building_corners(1);
                yc = building_corners(2);
            end
            
            dir  = cart2pol(xc - x(t_ms),yc - y(t_ms));
            if (dir == 0)
                dir = 2 * pi;
            end
            
            % move to the corner of the building
            prev_corner = [x(t_ms) y(t_ms)];
            [xw, yw, walking_time] = straight( x(t_ms), y(t_ms), xc, yc, velocity, timestep);
            t_ms = t_ms + walking_time;
            x = [x xw];
            y = [y yw];
        end
        
        % move along the final building
        while (dist_2d(x(t_ms), y(t_ms), xf, yf) > 0.1),
            
            % check if the pedestrian is on the right side
            side_distance = min([abs(x(t_ms) - xf) abs(y(t_ms) - yf)]);
            if (side_distance < 1),
                [xw, yw, walking_time] = straight( x(t_ms), y(t_ms), xf, yf, velocity, timestep);
                t_ms = t_ms + walking_time;
                x = [x xw];
                y = [y yw];
            else
                % find the corner that takes the pedestrian closer to the end
                building_corners = adjacent_corners(corners(:, 4 * (current_building - 1) + 1 : 4 * current_building), x(t_ms), y(t_ms));
                [index, xc, yc] = find_closest_corner(xf, yf, building_corners);
                
                % do not go back
                if (dist_2d(xc, yc, prev_corner(1), prev_corner(2)) < 1),
                    building_corners(:, index) = [];
                    xc = building_corners(1);
                    yc = building_corners(2);
                end
                
                dir  = cart2pol(xc - x(t_ms),yc - y(t_ms));
                % move to the corner of the building
                [xw, yw, walking_time] = straight( x(t_ms), y(t_ms), xc, yc, velocity, timestep);
                t_ms = t_ms + walking_time;
                x = [x xw];
                y = [y yw];
            end
            valid = true;
        end
        
        % vehicular scenario simulation
    else
        % initialize
        [road, final_road] = find_road(xf, yf, roads);
        [road, current_road] = find_road(x0, y0, roads);
        dir = road(5);
        lane = 1;
        dist_x = dist_2d(xf, yf, xf, road(4)) - dist_2d(xf, yf, xf, road(2));
        dist_y = dist_2d(xf, yf, road(3), yf) - dist_2d(xf, yf, road(1), yf);
        if ((dir == 2 * pi && dist_x < 0) || (dir == pi && dist_x > 0) || (dir == pi / 2 && dist_y > 0) || (dir == 3 * pi / 2 && dist_y < 0) ),
            lane = -1;
        end
        road_path = [current_road lane];
        
        % the car is not on the right road yet!
        while (current_road ~= final_road),
            % get through the next intersection
            [xs, ys, tau, path ] = next_turn (x(t_ms), y(t_ms), xf, yf, velocity, lane, current_road, roads, lane_width, timestep);
            x = [x xs];
            y = [y ys];
            t_ms = length(x);
            road_path = [road_path; path];
            if (tau == 0 || t_ms > 2 * 1E5),
                return;
            end
            current_road = road_path(end, 1);
            lane = road_path(end, 2);
            dir = roads(5, current_road);
        end
        
        % get to the correct lane
        dir = roads(5, current_road);
        right = false;
        road = roads(:, current_road);
        dist_x = dist_2d(xf, yf, xf, road(4)) - dist_2d(xf, yf, xf, road(2));
        dist_y = dist_2d(xf, yf, road(3), yf) - dist_2d(xf, yf, road(1), yf);
        if (abs((mod(dir, 2 * pi)) < 0.5 && dist_x > 0) || (abs(dir - pi) < 0.5 && dist_x < 0) || (abs(dir - pi / 2) < 0.5  && dist_y < 0) || (abs(dir - 3 * pi / 2) < 0.5 && dist_y > 0)),
            right = true;
        end
        if (~right),
            % switch lanes to the left
            while (lane > -1),
                [xs, ys, tau] = switch_lane ( x(t_ms), y(t_ms), velocity, dir, right, lane_width, timestep);
                lane = lane - 1;
                t_ms = t_ms + tau;
                x = [x xs];
                y = [y ys];
                road_path = [road_path; current_road lane];
            end
        else
            % switch lanes to the right
            while (lane < 1),
                [xs, ys, tau] = switch_lane ( x(t_ms), y(t_ms), velocity, dir, right, lane_width, timestep);
                lane = lane + 1;
                t_ms = t_ms + tau;
                x = [x xs];
                y = [y ys];
                road_path = [road_path; current_road lane];
            end
        end
        % get to the spot
        [xs, ys, tau] = straight(x(t_ms), y(t_ms), xf, yf, velocity, timestep);
        t_ms = t_ms + tau;
        x = [x xs];
        y = [y ys];
        
        % park
        [xs, ys, tau] = park(x(t_ms), y(t_ms), velocity, dir, right, lane_width / 2, timestep);
        t_ms = t_ms + tau;
        x = [x xs];
        y = [y ys];
        
        valid = true;
        
    end
end
