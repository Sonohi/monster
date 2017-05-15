function loss=calclossPS3PS4(bwidth,stwidth,nb_bx,nb_by,h_builds,res,h_floor,delta_hb,freq,MCL,wraparound,x,y)
%calclossPS3PS4 Calculate losses for the Urban macrocell scenario.
% 
%   loss=calclossPS3PS4(bwidth,stwidth,nb_bx,nb_by,h_builds,res,h_floor,delta_hb,freq,MCL,wraparound,x,y)
%   calculates the losses for the Urban Macrocell scenario when the base
%   station antenna is located in (x,y).
%
%   loss=calclossPS3PS4(bwidth,stwidth,nb_bx,nb_by,h_builds,res,h_floor,delta_hb,freq,MCL,wraparound)
%   calculates the losses for the Urban Macrocell scenario. In that case,
%   the base station is located at the center of the scenario.
%
%   where:
%       - bwidth: width of buildings [m]
%       - stwidth: width of streets [m]
%       - nb_bx: number of buildings in x-direction
%       - nb_by: number of buildings in y-direction
%       - h_builds: [nb_bx X nb_by]-matrix with the building heights [floors]
%       - res: resolution of the map [m]
%       - h_floor: height of floors 
%       - delta_hb: height of the BS relative to the building height
%       where the base station is located [m]
%       - freq: carrier frequency [Hz]
%       - MCL: minimum coupling losses [dB]
%       - wraparound: If 1, the layout is repeated in all directions. Then,
%       there are buildings at the edges. If 0, there are not buildings.       
%       - x: x-coordinate of the BS [m]
%       - y: y-coordinate of the BS [m]
%
%   For a map of (40x40) with a resolution of 3 meters, the value of 
%   loss(1,1,1) corresponds to the loss on the ground and (x,y)=(1.5,1.5) as
%   each value of the matrix corresponds to the center of the 3m x 3m square.

if (nargin == 11 || nargin == 13)
    if bwidth <= 0
        error('Invalid width of buildings: it must be greater than zero');
    end
    if stwidth <= 0
        error('Invalid width of streets: it must be greater than zero');
    end    
    if (nb_bx <= 0 || nb_by <= 0 || nb_bx ~= nb_by)
        error('Invalid number of buildings in the scenario');
    end    
    if res <= 0
        error('Invalid resolution: it must be greater than zero.');
    end 
    if (size(h_builds,1) ~= nb_bx || size(h_builds,2) ~= nb_by)
        error('Error in building heights matrix dimension: it must be [nb_bx,nb_by].');
    end
    if(sum(sum(h_builds==0))>1)
        error('Error in values of building heights matrix: it must be greater than zero.');
    end        
    if h_floor <= 0
        error('Invalid height of floors: it must be greater than zero.');
    end
    if delta_hb <= 0
        error('Invalid height of the BS relative to the building height.');
    end
else
    error('Invalid number of input arguments.')    
end

%% DEFAULT PARAMETERS
hm = 1.5;       % height of receiver

% Type of environment
t_envir = 0;    % For medium sized city and suburban centres with medium tree density 0
                % For metropolitan centres 1
                
%% LAYOUT

% Size of the map: (m x n)
m = ceil((nb_bx*(bwidth+stwidth)+stwidth)/res);
n = ceil((nb_by*(bwidth+stwidth)+stwidth)/res);
map = ones(m,n);
limit_map = [nb_bx*(bwidth+stwidth)+stwidth, nb_by*(bwidth+stwidth)+stwidth];

% BS location
if nargin~=13
    mt = ceil(m/2);
    nt = ceil(n/2);
else
    mt=round(x/res);
    nt=round(y/res);
end

% Maximum number of floors
maxnbfloors = max(max(h_builds));

% Streets in x-direction
j = 1:m;
j = (j-1)*res;
j = mod(j,bwidth+stwidth);
k = find(j<stwidth);
map(k,:) = 0;

% Streets in y-direction
j = 1:n;
j = (j-1)*res;
j = mod(j,bwidth+stwidth);
k = find(j<stwidth);
map(:,k) = 0;

% Map with heights
map_h=map;
for r=1:nb_bx
    i = 1:m;
    i = (i-1)*res;    
    i = ((i >= stwidth+(r-1)*(stwidth + bwidth)) & (i < r*(stwidth + bwidth)));    
    for s=1:nb_by
        j = 1:n;
        j = (j-1)*res;    
        j = ((j >= stwidth+(s-1)*(stwidth + bwidth)) & (j < s*(stwidth + bwidth)));            
        map_h(i,j)=h_builds(s,r)*h_floor;
    end
end

% Position of building walls in x-direction and y-direction
wp=1;
real_wall_points_x = zeros(1,nb_bx);
for r=1:nb_bx
    real_wall_points_x(wp) = (stwidth+(r-1)*(stwidth + bwidth));
    real_wall_points_x(wp+1) = (r*(stwidth + bwidth));
    wp=wp+2;
end
wp=1;
real_wall_points_y = zeros(1,nb_by);
for r=1:nb_by
    real_wall_points_y(wp) = (stwidth+(r-1)*(stwidth + bwidth));
    real_wall_points_y(wp+1) = (r*(stwidth + bwidth));
    wp=wp+2;
end

% For Urban Macrocell -> Check if the transmission antenna is located over a building
if map(mt,nt)==0
    error('The transmission antenna must be located over a rooftop');
else
    % BS height
    hs = map_h(mt,nt) + delta_hb;
    
    % BS position
    x_bs = (mt-0.5)*res;
    y_bs = (nt-0.5)*res;
    
    % Building where BS is located
    bs_build_x_1 = (real_wall_points_x(1:2:end) < x_bs);     
    bs_build_x_2 = (real_wall_points_x(2:2:end) > x_bs);     
    bs_build_y_1 = (real_wall_points_y(1:2:end) < y_bs);     
    bs_build_y_2 = (real_wall_points_y(2:2:end) > y_bs);     
    bs_build_x = find((bs_build_x_1 & bs_build_x_2) == 1);
    bs_build_y = find((bs_build_y_1 & bs_build_y_2) == 1);
end

% Initialize output variable 
loss = zeros(maxnbfloors,m,n);
loss(:,:,:) = NaN;

%% For outdoor PS#3
disp('Macro - Outdoor calculations - PS#3');

[j,k] = find (map == 0);    % Outdoor positions
  
it_current = 0;
for l = 1:length(j)    
    it_current=processingState(l,length(j),it_current);
    
    % Receiver location in map [m] (center of the corresponding res x res square)
    x_p = (j(l)-0.5)*res;
    y_p = (k(l)-0.5)*res;
    
    % Distance from BS to receiver
    dist_total = sqrt((x_bs-x_p)^2+(y_bs-y_p)^2);
    
    % Rect from BS to receiver
    if (x_p - x_bs) ~= 0
        slope = (y_p - y_bs)/(x_p - x_bs);
        ordi = (x_p*y_bs - x_bs*y_p)/(x_p-x_bs);
        normal_to_x = 0;
    else
        % Rect perpendicular to x-axis
        normal_to_x = 1;        
    end
    
    % Find crossing points within the LoS between BS and receiver
    [cross_points,dist,build_id,is_corner]=findCrossingPoints(j(l),k(l),mt,nt,x_p,y_p,x_bs,y_bs,real_wall_points_x,real_wall_points_y,slope,ordi,normal_to_x);
    
    % Compute widths of buildings and streets within the LoS between BS and
    % receiver
    [build_widths,build_heights,street_widths] = LoS_Building_and_Street_Widths(map,cross_points,dist,is_corner,dist_total,build_id,h_builds,h_floor,res);
    
    % Apply the pathloss model
    [Lfs,Lmsd,Lrts] = outdoorModel(x_p,y_p,hm,x_bs,y_bs,hs,delta_hb,h_floor,maxnbfloors,freq,build_widths,build_heights,street_widths,t_envir);   
    
    for nf=1:maxnbfloors
        if (Lmsd + Lrts(nf) <= 0)
            loss(nf,j(l),k(l)) = max(Lfs,MCL);
        else
            loss(nf,j(l),k(l)) = max(Lfs+Lmsd+Lrts(nf),MCL);
        end
    end
end

%% For indoor PS#4
disp('Macro - Indoor calculations - PS#4');

[j,k] = find (map == 1);    % Indoor positions

% The index of each vector are ordered in the following directions:
% 1 = x-positive (East)
% 2 = y-positive (North)
% 3 = x-negative (West)
% 4 = y-negative (South)

normal_vect = [1 0; 0 1; -1 0; 0 -1];

Lout=zeros(4,maxnbfloors);
it_current = 0;
for l = 1:length(j)    
    it_current=processingState(l,length(j),it_current); 
    
    % Receiver location in map [m] (center of the corresponding res x res square)
    x_p = (j(l)-0.5)*res;
    y_p = (k(l)-0.5)*res;
    
    % Building where receiver is located
    build_x_1 = (real_wall_points_x(1:2:end) <= x_p);
    build_x_2 = (real_wall_points_x(2:2:end) >= x_p);
    build_x = find((build_x_1 & build_x_2) == 1);
    build_y_1 = (real_wall_points_y(1:2:end) <= y_p);
    build_y_2 = (real_wall_points_y(2:2:end) >= y_p);
    build_y = find((build_y_1 & build_y_2) == 1);
    
    % Wall points in the four directions
    wall_points = [real_wall_points_x(2*build_x), y_p;
        x_p, real_wall_points_y(2*build_y);
        real_wall_points_x(2*build_x-1), y_p;
        x_p, real_wall_points_y(2*build_y-1)];
    
    % Compute the distance from the point to the walls
    dist_in(1) = abs(real_wall_points_x(2*build_x) - x_p);
    dist_in(2) = abs(real_wall_points_y(2*build_y) - y_p);
    dist_in(3) = abs(real_wall_points_x(2*build_x - 1) - x_p);
    dist_in(4) = abs(real_wall_points_y(2*build_y - 1) - y_p);    
    
    % Nearest outside point to the walls
    outside_points = [(wall_points(1,1) + res/2)/res + 0.5, k(l);
        j(l),(wall_points(2,2) + res/2)/res + 0.5;
        (wall_points(3,1) - res/2)/res + 0.5, k(l);
        j(l), (wall_points(4,2) - res/2)/res + 0.5];
        
    % 1) Lout uses the PS#3 for the nearest outdoor point to each wall
    for i=1:4
        for nf=1:maxnbfloors         
            Lout(i,nf)=loss(nf,outside_points(i,1),outside_points(i,2));
        end
    end
    
    % 2) Lin
    Lin = 0.5*dist_in;    

    % 3) Find the angle of incidence for each direction
    Lth = zeros(4,maxnbfloors);
    for i=1:4
       
        % Direction respect BS
       if(outside_points(i,1) < mt)
           is_East = 1;     % East
       elseif(outside_points(i,1) > mt)
           is_East = -1;    % West    
       else
           is_East = 0;     % Same x-coordinate
       end       
       if(outside_points(i,2) < nt)
           is_North = 1;     % North
       elseif(outside_points(i,2) > nt)
           is_North = -1;    % South
       else
           is_North = 0;     % Same y-coordinate
       end
       
       % Check if the incident ray is direct or reflected
       if map(outside_points(i,1)+is_East,outside_points(i,2)+is_North) == 0
           % The incident ray is direct
           ps_v1_v2 = ( (x_bs-wall_points(i,1))*normal_vect(i,1) + (y_bs-wall_points(i,2))*normal_vect(i,2) );           
           normv = sqrt( (x_bs-wall_points(i,1))^2 + (y_bs-wall_points(i,2))^2);           
           tetha = pi/2 - acos(ps_v1_v2/normv);           
           Lth(i,:) = 9.82 + 5.98*log10(freq/1e9) + 15*(1-sin(tetha))^2;
       else
           % The incident ray may be reflected. 
           % The ray is not reflected in the following cases:
           %    Case 1) The building is in the edge of layout and wraparound = 0
           %    Case 2) The neighbor building is smaller than the rx point 
           %    Case 3) The ray incide between two buildings
           
           reflection = ones(1,maxnbfloors);
           if map(outside_points(i,1)+is_East,outside_points(i,2)) == 1
               % The ray is reflected on a wall perpendicular to x-axis
               x_ref_wall = wall_points(i,1) - is_East*(stwidth);
               if ( ((round(x_ref_wall) == 0) || (round(x_ref_wall) == limit_map(1))) && ~wraparound )
                   % Case 1: The ray is not reflected without wraparound
                   reflection(:) = 0;
               else
                   x_shift = abs(x_bs - x_ref_wall);
                   x_bs_aux = x_bs - is_East*(2*x_shift);
                   y_bs_aux = y_bs;                   

                   min_dif_angle = 1000;
                   ref = wall_points(i,2);
                   for ip=outside_points(i,2):is_North:nt
                       y_aux = (ip - 0.5)*res;
                       
                       sp_vector1 = (x_ref_wall - wall_points(i,1))*normal_vect(1,1) + (y_aux - wall_points(i,2))*normal_vect(1,2);
                       normv1 = sqrt( (x_ref_wall - wall_points(i,1))^2 + (y_aux - wall_points(i,2))^2);
                       tetha1 = acos(sp_vector1/normv1);

                       sp_vector2 = (x_ref_wall - x_bs)*normal_vect(1,1) + (y_aux - y_bs)*normal_vect(1,2);                       
                       normv2 = sqrt( (x_ref_wall - x_bs)^2 + (y_aux - y_bs)^2);
                       tetha2 = acos(sp_vector2/normv2);

                       dif_angle = abs(tetha1 - tetha2);

                       if dif_angle < min_dif_angle
                           min_dif_angle = dif_angle;
                           ref = y_aux;
                       end
                   end
                   x_ref = x_ref_wall;
                   y_ref = ref;
                   
                   build_y_1 = (real_wall_points_y(1:2:end) <= y_ref);
                   build_y_2 = (real_wall_points_y(2:2:end) >= y_ref);
                   build_y = find((build_y_1 & build_y_2) == 1);
                   
                   if isempty(build_y)
                       % Case 3) The ray incide between two buildings
                       reflection(:) = 0;
                   else                       
                       build_x_1 = (real_wall_points_x(1:2:end) <= x_ref);
                       build_x_2 = (real_wall_points_x(2:2:end) >= x_ref);
                       build_x = find((build_x_1 & build_x_2) == 1);
                       if ~isempty(build_x)
                           h_neigh_build = h_builds(build_x,build_y)*h_floor;
                           for nf=1:maxnbfloors
                               hrx_floor = h_floor*(nf - 1) + hm;        
                               if h_neigh_build < hrx_floor
                                   % Case 2) The neighbor building is smaller than the rx point 
                                   reflection(nf) = 0;
                               end
                           end
                       end
                   end
               end               
               
           else
               % The ray is reflected on a wall perpendicular to y-axis               
               y_ref_wall = wall_points(i,2) - is_North*(stwidth);
               if ( ((round(y_ref_wall) == 0) || (round(y_ref_wall) == limit_map(2))) && ~wraparound )
                   % Case 1: The ray is not reflected without wraparound
                   reflection = 0;
               else
                   y_shift = abs(y_bs - y_ref_wall);
                   x_bs_aux = x_bs;
                   y_bs_aux = y_bs - is_North*(2*y_shift);                   

                   min_dif_angle = 1000;
                   ref = wall_points(i,1);
                   for ip=outside_points(i,1):is_East:mt
                       x_aux = (ip - 0.5)*res;
                       
                       sp_vector1 = (x_aux - wall_points(i,1))*normal_vect(2,1) + (y_ref_wall - wall_points(i,2))*normal_vect(2,2);
                       normv1 = sqrt( (x_aux - wall_points(i,1))^2 + (y_ref_wall - wall_points(i,2))^2);
                       tetha1 = acos(sp_vector1/normv1);

                       sp_vector2 = (x_aux - x_bs)*normal_vect(2,1) + (y_ref_wall - y_bs)*normal_vect(2,2);                       
                       normv2 = sqrt( (x_aux - x_bs)^2 + (y_ref_wall - y_bs)^2);
                       tetha2 = acos(sp_vector2/normv2);

                       dif_angle = abs(tetha1 - tetha2);

                       if dif_angle < min_dif_angle
                           min_dif_angle = dif_angle;
                           ref = x_aux;
                       end
                   end
                   x_ref = ref;
                   y_ref = y_ref_wall;
                   
                   build_x_1 = (real_wall_points_x(1:2:end) <= x_ref);
                   build_x_2 = (real_wall_points_x(2:2:end) >= x_ref);
                   build_x = find((build_x_1 & build_x_2) == 1);
                   
                   if isempty(build_x)
                       % Case 3) The ray incide between two buildings
                       reflection(:) = 0;
                   else                       
                       build_y_1 = (real_wall_points_y(1:2:end) <= y_ref);
                       build_y_2 = (real_wall_points_y(2:2:end) >= y_ref);
                       build_y = find((build_y_1 & build_y_2) == 1);
                       if ~isempty(build_y)
                           h_neigh_build = h_builds(build_x,build_y)*h_floor;
                           for nf=1:maxnbfloors
                               hrx_floor = h_floor*(nf - 1) + hm;        
                               if h_neigh_build < hrx_floor
                                   reflection(nf) = 0;
                                   % Case 2) The neighbor building is smaller than the rx point 
                               end
                           end
                       end
                   end 
               end
           end
           
           if sum(reflection) > 0               
               ps_v1_v2 = (x_bs_aux-wall_points(i,1))*normal_vect(i,1) + (y_bs_aux-wall_points(i,2))*normal_vect(i,2);
               normv = sqrt( (x_bs_aux-wall_points(i,1))^2 + (y_bs_aux-wall_points(i,2))^2 );
               tetha = pi/2 - acos(ps_v1_v2/normv);
               for nf=1:maxnbfloors
                  if reflection(nf) == 1
                      Lth(i,nf) = 9.82 + 5.98*log10(freq/1e9) + 15*(1-sin(tetha))^2;
                  else
                      Lth(i,nf) = 1000;
                  end 
               end
           else
               Lth(i,:) = 1000;
           end
       end
    end
    
    % Select the best option
    for nf=1:maxnbfloors
        if nf <= map_h(j(l),k(l))/h_floor
            L_total = Lout(:,nf) + Lth(:,nf) + Lin(:);
            loss(nf,j(l),k(l)) = max(min(L_total),MCL);            
        else
            loss(nf,j(l),k(l)) = NaN;
        end   
    end
end

idx=(map==0);
for nf=2:maxnbfloors
    loss(nf,idx)=NaN;
end

end

%% FUNCTION TO FIND THE CROSSING WALLS WITHIN THE LoS
function [cross_points,dist,build_id,is_corner]=findCrossingPoints(j,k,mt,nt,x_p,y_p,x_bs,y_bs,wall_p_x,wall_p_y,slope,ordi,normal_to_x)

    % Find crossing walls
    if(j < mt)
        % East
        wall_sighted_in_x = ((wall_p_x < x_bs & wall_p_x > x_p));        
    elseif(j > mt)
        % West    
        wall_sighted_in_x = ((wall_p_x > x_bs & wall_p_x < x_p));        
    else
        % Same x-coordinate
        wall_sighted_in_x = (wall_p_x == x_bs);
    end    
    if(k < nt)
        % North
        wall_sighted_in_y = ((wall_p_y < y_bs & wall_p_y > y_p));        
    elseif(k > nt)
        % South
        wall_sighted_in_y = ((wall_p_y > y_bs & wall_p_y < y_p));        
    else
        % Same y-coordinate
        wall_sighted_in_y = (wall_p_y == y_bs);
    end
    
    cp=1;    
    for w=1:length(wall_p_x)
        if wall_sighted_in_x(w)
            x_wall_x = wall_p_x(w);
            y_wall_x = slope*x_wall_x + ordi;
            build_x = ceil(w/2);
            build_y_1 = (wall_p_y(1:2:end) <= y_wall_x);     
            build_y_2 = (wall_p_y(2:2:end) >= y_wall_x);
            build_y = (build_y_1 & build_y_2);
            if sum(build_y)==0
                wall_sighted_in_x(w)=0;
            else
                build_y = find(build_y==1);
                cross_points(cp,:)=[x_wall_x y_wall_x];
                build_id(cp,:)=[build_x build_y];
                cp=cp+1;
            end                
        end
    end
    for w=1:length(wall_p_y)
        if wall_sighted_in_y(w)
            y_wall_y = wall_p_y(w);
            if ~normal_to_x
                x_wall_y = (y_wall_y - ordi)/slope;
            else
                x_wall_y = x_p;
            end            
            build_x_1 = (wall_p_x(1:2:end) <= x_wall_y);     
            build_x_2 = (wall_p_x(2:2:end) >= x_wall_y);
            build_x = (build_x_1 & build_x_2);
            build_y = ceil(w/2);
            if sum(build_x)==0
                wall_sighted_in_y(w)=0;
            else
                build_x = find(build_x==1);
                cross_points(cp,:)=[x_wall_y y_wall_y];
                build_id(cp,:)=[build_x build_y];
                cp=cp+1;
            end            
        end
    end
    
    cp=cp-1;    
    dist=sqrt((cross_points(:,1)-x_bs).^2+(cross_points(:,2)-y_bs).^2);    
    is_corner = zeros(1,length(cross_points));
    rep=0;
    idx=0;
    for w1=1:cp
        for w2=w1+1:cp            
            if abs(dist(w1) - dist(w2)) < 1e-6
                rep=rep+1;
                idx(rep)=w2;
                is_corner(w1)=1;
                break;
            end
        end
    end
    if idx~=0
        dist(idx)=0;
    end
    cross_points = cross_points(dist ~= 0,:);
    build_id = build_id(dist ~= 0,:);
    is_corner = is_corner(dist ~= 0);
    dist = dist(dist ~= 0);
end

%% FUNCTION TO FIND THE WIDTHS OF STREETS AND BUILDINGS WITHIN THE LoS
function [build_widths,build_heights,street_widths] = LoS_Building_and_Street_Widths(map,cross_points,dist,is_corner,dist_total,build_id,h_builds,h_floor,res)
    
    % Number of crossing points
    cp = size(cross_points,1);
    
    % Sort distances
    [sort_dist,idx]=sort(dist,'ascend');
    
    b=1;
    s=1;
    is_str = 0;   % to know if the strength is part of a building or street
    street_widths = 0;
    build_widths = 0;
    build_heights = 0;
    for w=1:cp
        if w==1
            build_widths(b) = sort_dist(w);
            build_heights(b) = h_builds(build_id(idx(w),1),build_id(idx(w),2))*h_floor;
            b=b+1;
            is_str = 1;
        elseif w<cp
            dist = sort_dist(w) - sort_dist(w-1);
            if is_str
                street_widths(s) = dist;
                s=s+1;
                is_str = 0;
                if is_corner(idx(w))
                    % Check if the next portion of a building is only the
                    % corner
                    aux_x = (cross_points(idx(w),1) + cross_points(idx(w+1),1))/2;
                    aux_y = (cross_points(idx(w),2) + cross_points(idx(w+1),2))/2;
                    if map(round(aux_x/res),round(aux_y/res)) == 0
                        build_widths(b) = 0;
                        build_heights(b) = h_builds(build_id(idx(w),1),build_id(idx(w),2))*h_floor;
                        b=b+1;
                        is_str = 1;
                    end 
                end
            else
                build_widths(b) = dist;
                build_heights(b) = h_builds(build_id(idx(w),1),build_id(idx(w),2))*h_floor;
                b=b+1;
                is_str = 1;                
            end
        else
            dist = sort_dist(w) - sort_dist(w-1);
            if is_str
                street_widths(s) = dist;
                s=s+1;
                is_str = 0;
                if is_corner(idx(w))
                    build_widths(b) = 0;
                    build_heights(b) = h_builds(build_id(idx(w),1),build_id(idx(w),2))*h_floor;
                    b=b+1;
                    is_str = 1;
                end
            else
                build_widths(b) = dist;
                build_heights(b) = h_builds(build_id(idx(w),1),build_id(idx(w),2))*h_floor; 
                b=b+1;
                is_str = 1;
            end            
        end
    end
    street_widths(s) = dist_total - sort_dist(end);
end

%% FUNCTION TO CALCULATE THE PATHLOSS FOR OUTDOOR POINTS
function [Lfs,Lmsd,Lrts] = outdoorModel(x_p,y_p,hm,x_bs,y_bs,hs,delta_hb,h_floor,maxnbfloors,freq,build_widths,build_heights,street_widths,t_envir)

    lambda = 3e8/freq;  % Wavelength

    % 1) Free space loss calculation (Lfs)
    R = sqrt((x_bs-x_p)^2+(y_bs-y_p)^2);
    Lfs = -20 * log10(lambda/(4*pi*R)); 
    
    % 2) Multiple screen diffraction loss (Lmsd)
    if length(build_widths) > 1
        if(length(street_widths)>1)
            mean_s = mean(street_widths(1:end-1));
        else
            mean_s = 0;
        end
        mean_b = mean(build_widths(2:end));
        if sum(build_widths(2:end)) > 0
            mean_h = (build_heights(2:end)*build_widths(2:end)')/(sum(build_widths(2:end)));
        else
            mean_h = sum(build_heights(2:end))/length(build_heights(2:end));
        end
        
        d_hb = hs-mean_h;
        mean_d = mean_b+mean_s;
        ds = (lambda*R^2)/(d_hb^2);
        l_total = sum(street_widths(2:end-1)) + sum(build_widths(2:end));

        if l_total > ds            
            if hs > mean_h
                Lbsh = -18*log10(1+d_hb);
                ka = 54;
                kd = 18;
            else
                Lbsh = 0;                    
                if R >= 500
                    ka = 54 - 0.8*d_hb;
                else
                    ka = 54 - 1.6*d_hb;                        
                end
                kd = 18 - 15*(d_hb/mean_h);
            end
            if t_envir == 0
                kf = 0.7*((freq/1e6)/925 - 1);
            else
                kf = 1.5*((freq/1e6)/925 - 1);
            end                
            Lmsd = Lbsh + ka + kd*log10(R/1000) + kf*log10(freq/1e6) - 9*log10(mean_d);
        else
            if hs - mean_h > 0.5
                Qm = 2.35*(d_hb/R*sqrt((mean_d)/lambda))^0.9;                    
            elseif abs(hs - mean_h) <= 0.5
                Qm = mean_d/R;                    
            else
                ro = sqrt(d_hb^2+mean_d^2);
                theta = atan(d_hb/mean_d);
                Qm = (mean_d/(2*pi*R))*sqrt(lambda/ro)*((1/theta)-(1/(2*pi+theta)));
            end
            Lmsd = -10*log10(Qm^2);     
        end        
    else
        Lmsd = 0;
    end
    
    % 3) Diffraction from the rootop down to the street level (Lrts)    
    obstr_building = 0;
    if sum(hs - build_heights(2:end-1) <= 0) > 0
        obstr_building = 1;
    end 
    last_s = street_widths(end);
    last_h = build_heights(end);
    dist_to_last_s = R - last_s;
    alpha = atan(delta_hb/dist_to_last_s);
    for nf=1:maxnbfloors
        hrx_floor = h_floor*(nf - 1) + hm;                
        % Check if we are in LoS
        alpha_to_UE = atan((hs-hrx_floor)/(R));
        if (alpha_to_UE > alpha) || obstr_building
            % NLoS
            theta = atan((last_h-hrx_floor)/last_s);
            last_r = sqrt((last_h-hrx_floor)^2+last_s^2);
            Lrts(nf) = -20*log10(0.5-(1/pi)*atan(sign(theta)*sqrt((pi^3)/(4*lambda)*last_r*(1-cos(theta)))));
        else
            % LoS
            Lrts(nf) = 0;
        end
    end
end

%% FUNCTION TO KNOW THE STATE OF THE PROCESS
function it_current=processingState(l,j,it_current)

    if l==1
        disp('0 %');
        it_current = 0;
    else
        iter = l/j;
        switch(it_current)
            case 0
                if(iter >= 0.1)
                    it_current = 10;
                    disp('10 %');
                end      
            case 10
                if(iter >= 0.2)
                    it_current = 20;
                    disp('20 %');
                end                
            case 20
                if(iter >= 0.3)
                    it_current = 30;
                    disp('30 %');
                end                
            case 30
                if(iter >= 0.4)
                    it_current = 40;
                    disp('40 %');
                end               
            case 40
                if(iter >= 0.5)
                    it_current = 50;
                    disp('50 %');
                end                    
            case 50
                if(iter >= 0.6)
                    it_current = 60;
                    disp('60 %');
                end                   
            case 60
                if(iter >= 0.7)
                    it_current = 70;
                    disp('70 %');
                end                       
            case 70
                if(iter >= 0.8)
                    it_current = 80;
                    disp('80 %');
                end                     
            case 80
                if(iter >= 0.9)
                    it_current = 90;
                    disp('90 %');
                end                       
            case 90
                if(iter >= 1.0)
                    it_current = 100;
                    disp('100 %');
                end
        end
    end
end

