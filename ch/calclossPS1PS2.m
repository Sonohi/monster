function loss=calclossPS1PS2(bwidth,stwidth,nb_bx,nb_by,res,h_builds,h_floor,htx,freq,MCL,x,y)
% calclossPS1PS2 Calculate losses for the Urban microcell scenario (based
% on the ITU-R U;i path loss model)
% 
%   loss=calclossPS1PS2(bwidth,stwidth,nb_bx,nb_by,res,h_builds,h_floor,hs,freq,MCL,x,y)
%   calculates the losses for the Urban Microcell scenario when the antenna
%   transmitter is located in (x,y).
%
%   loss=calclossPS1PS2(bwidth,stwidth,nb_bx,nb_by,res,h_builds,h_floor,hs,freq,MCL)
%   calculates the losses for the Urban Microcell scenario. In that case,
%   the antenna transmitter is located at the center of the scenario.
%
%   where:
%       - bwidth: width of buildings [m]
%       - stwidth: width of streets [m]
%       - nb_bx: number of buildings in x-direction
%       - nb_by: number of buildings in y-direction
%       - res: resolution of the map [m]
%       - h_builds: [nb_bx X nb_by]-matrix with the building heights [floors]
%       - h_floor: height of floors 
%       - htx: height of the BS above the ground [m]
%       - freq: carrier frequency [Hz]
%       - MCL: minimum coupling losses [dB]
%       - x: the x-coordinate of the BS [m]
%       - y: the y-coordinate of the BS [m]
%
%   For a map of (40x40) with a resolution of 3 meters, the value of 
%   loss(1,1,1) corresponds to the loss on the ground and (x,y)=(1.5,1.5) as
%   each value of the matrix corresponds to the center of the 3m x 3m square.

if (nargin == 10 || nargin == 12)
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
    if h_floor <= 0
        error('Invalid height of floors: it must be greater than zero.');
    end
    if htx <= 0
        error('Invalid height of the transmitter.');
    end
else
    error('Invalid number of input arguments.')    
end

%% DEFAULT PARAMETERS
hm = 1.5;
htx_eff = htx - 1.0;
hrx_eff = hm - 1.0;

%% LAYOUT

% Size of the map: (m x n)
m = ceil((nb_bx*(bwidth+stwidth)+stwidth)/res);
n = ceil((nb_by*(bwidth+stwidth)+stwidth)/res);
map = ones(m,n);
limit_map = [nb_bx*(bwidth+stwidth)+stwidth, nb_by*(bwidth+stwidth)+stwidth];

% Antenna transmitter location
if nargin~=12
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

street_limits_x = [0 real_wall_points_x limit_map(1)];
street_limits_y = [0 real_wall_points_y limit_map(2)];

% 1) UMi: check if the transmission antenna is located in the street
if map(mt,nt)==1
    error('The transmission antenna must be located in the street');  
end

% Initialize output variable 
loss = zeros(maxnbfloors,m,n);
loss(:,:,:) = NaN;

%% OUTDOOR PS#1: 
disp('Micro - Outdoor calculations - PS#1');

% The index of each vector are ordered in the following directions:
% 1 = x-positive (East)
% 2 = y-positive (North)
% 3 = x-negative (West)
% 4 = y-negative (South)

% This model ditinguishes the main street, perpedicular streets 
% and parallel streets
[j,k] = find (map == 0);

x_bs = (mt - 0.5)*res;
y_bs = (nt - 0.5)*res;

% Find direction and center of the street where the BS is located
bs_street_x_1 = (street_limits_x(1:2:end) <= x_bs);
bs_street_x_2 = (street_limits_x(2:2:end) >= x_bs);
bs_street_x = find((bs_street_x_1 & bs_street_x_2) == 1);
bs_street_y_1 = (street_limits_y(1:2:end) <= y_bs);
bs_street_y_2 = (street_limits_y(2:2:end) >= y_bs);
bs_street_y = find((bs_street_y_1 & bs_street_y_2) == 1);

if ~isempty(bs_street_x)
    if ~isempty(bs_street_y)
        % The transmitter is located in a intersection of perpendicular
        % streets
        bs_str = 2;
        bs_str_centre(1) = (street_limits_x(2*bs_street_x) + street_limits_x(2*bs_street_x-1))/2;
        bs_str_centre(2) = (street_limits_y(2*bs_street_y) + street_limits_y(2*bs_street_y-1))/2;        
    else
        % The transmitter is located in a street in y-direction
        bs_str = 1;
        bs_str_centre(1) = (street_limits_x(2*bs_street_x) + street_limits_x(2*bs_street_x-1))/2;
        bs_str_centre(2) = -1;        
    end
else
    % The transmitter is located in a street in x-direction
    bs_str = 0;
    bs_str_centre(1) = -1;
    bs_str_centre(2) = (street_limits_y(2*bs_street_y) + street_limits_y(2*bs_street_y-1))/2;        
end

it_current = 0;
for l = 1:length(j)    
    it_current=processingState(l,length(j),it_current);
    
    x_p = (j(l) - 0.5)*res;
    y_p = (k(l) - 0.5)*res;
    
    % Find the street where the rx is located
    rx_street_x_1 = (street_limits_x(1:2:end) <= x_p);
    rx_street_x_2 = (street_limits_x(2:2:end) >= x_p);
    rx_street_x = find((rx_street_x_1 & rx_street_x_2) == 1);
    rx_street_y_1 = (street_limits_y(1:2:end) <= y_p);
    rx_street_y_2 = (street_limits_y(2:2:end) >= y_p);
    rx_street_y = find((rx_street_y_1 & rx_street_y_2) == 1);
    
    if ~isempty(rx_street_x)
        if ~isempty(rx_street_y)
            % The receiver is located in perpendicular street            
            rx_str = 2;  
            rx_str_centre(1) = (street_limits_x(2*rx_street_x) + street_limits_x(2*rx_street_x-1))/2;
            rx_str_centre(2) = (street_limits_y(2*rx_street_y) + street_limits_y(2*rx_street_y-1))/2;        
        else
            % The receiver is located in a street in y-direction
            rx_str = 1;
            rx_str_centre(1) = (street_limits_x(2*rx_street_x) + street_limits_x(2*rx_street_x-1))/2;
            rx_str_centre(2) = -1;        
        end
    else
        % The receiver is located in a street in y-direction
        rx_str = 0;
        rx_str_centre(1) = -1;
        rx_str_centre(2) = (street_limits_y(2*rx_street_y) + street_limits_y(2*rx_street_y-1))/2;        
    end
    
    % Rect from BS to point
    if (x_p - x_bs) ~= 0
        slope = (y_p - y_bs)/(x_p - x_bs);
        ordi = (x_p*y_bs - x_bs*y_p)/(x_p-x_bs);
        normal_to_x = 0;
    else
        % Rect perpendicular to x-axis
        normal_to_x = 1;        
    end
    
    % Check if the receiver is in LoS
    isInLoS = isLoS(j(l),k(l),mt,nt,x_p,y_p,x_bs,y_bs,real_wall_points_x,real_wall_points_y,slope,ordi,normal_to_x);
    
    if isInLoS
        % Receiver in the main street (LoS)
        d1 = sqrt((x_p-x_bs)^2 + (y_p-y_bs)^2);
        Llos = 40*log10(d1) + 7.8 - 18*log10(htx_eff) - 18*log10(hrx_eff) + 2*log10(freq/1e9);
        loss(1,j(l),k(l)) = max(Llos,MCL);        
    else
        % Check if the receiver is either in a perpendicular or a paralel
        % street
        parallel = false;
        if ((rx_str == bs_str) && (rx_str < 2))
            parallel = true;      
        end
        
        if parallel
            loss(1,j(l),k(l)) = NaN;
        else            
            if rx_str * bs_str < 4
                switch bs_str
                    case 0
                        d1 = abs(x_bs-rx_str_centre(1));
                        d2 = abs(y_p-bs_str_centre(2));
                    case 1
                        d1 = abs(y_bs-rx_str_centre(2));
                        d2 = abs(x_p-bs_str_centre(1));
                    case 2
                        if rx_str == 0
                            d1 = abs(y_bs-rx_str_centre(2));
                            d2 = abs(x_p-bs_str_centre(1));
                        else
                            d1 = abs(x_bs-rx_str_centre(1));
                            d2 = abs(y_p-bs_str_centre(2));
                        end
                end
                Llos1 = 40*log10(d1) + 7.8 - 18*log10(htx_eff) - 18*log10(hrx_eff) + 2*log10(freq/1e9);
                Llos2 = 40*log10(d2) + 7.8 - 18*log10(hrx_eff) - 18*log10(hrx_eff) + 2*log10(freq/1e9);
                nj1 = max(2.8-0.0024*d1,1.84);
                nj2 = max(2.8-0.0024*d2,1.84);
                PL1 = Llos1 + 17.9 - 12.5*nj1 + 10*nj1*log10(d2) + 3*log10(freq/1e9);
                PL2 = Llos2 + 17.9 - 12.5*nj2 + 10*nj2*log10(d1) + 3*log10(freq/1e9);
                PL = min(PL1,PL2);                  
            else
                d1_1 = abs(x_bs-rx_str_centre(1));
                d2_1 = abs(y_p-bs_str_centre(2));
                Llos1_1 = 40*log10(d1_1) + 7.8 - 18*log10(htx_eff) - 18*log10(hrx_eff) + 2*log10(freq/1e9);
                Llos2_1 = 40*log10(d2_1) + 7.8 - 18*log10(hrx_eff) - 18*log10(hrx_eff) + 2*log10(freq/1e9);
                nj1_1 = max(2.8-0.0024*d1_1,1.84);
                nj2_1 = max(2.8-0.0024*d2_1,1.84);
                PL1_1 = Llos1_1 + 17.9 - 12.5*nj1_1 + 10*nj1_1*log10(d2_1) + 3*log10(freq/1e9);
                PL2_1 = Llos2_1 + 17.9 - 12.5*nj2_1 + 10*nj2_1*log10(d1_1) + 3*log10(freq/1e9);
                PL_1 = min(PL1_1,PL2_1);

                d1_2 = abs(y_bs-rx_str_centre(2));
                d2_2 = abs(x_p-bs_str_centre(1));
                Llos1_2 = 40*log10(d1_2) + 7.8 - 18*log10(htx_eff) - 18*log10(hrx_eff) + 2*log10(freq/1e9);
                Llos2_2 = 40*log10(d2_2) + 7.8 - 18*log10(hrx_eff) - 18*log10(hrx_eff) + 2*log10(freq/1e9);
                nj1_2 = max(2.8-0.0024*d1_2,1.84);
                nj2_2 = max(2.8-0.0024*d2_1,1.84);
                PL1_2 = Llos1_2 + 17.9 - 12.5*nj1_2 + 10*nj1_2*log10(d2_2) + 3*log10(freq/1e9);
                PL2_2 = Llos2_2 + 17.9 - 12.5*nj2_2 + 10*nj2_2*log10(d1_2) + 3*log10(freq/1e9);
                PL_2 = min(PL1_2,PL2_2);

                PL = min(PL_1,PL_2);
            end
            loss(1,j(l),k(l)) = max(PL,MCL);        
        end
    end    
end
loss(2:end,:,:) = NaN;

%% INDOOR: only for buiding in LoS
disp('Micro - Indoor calculations - PS#2');

% The index of each vector are ordered in the following directions:
% 1 = x-positive (East)
% 2 = y-positive (North)
% 3 = x-negative (West)
% 4 = y-negative (South)

[j,k] = find (map == 1);

normal_vect = [1 0; 0 1; -1 0; 0 -1];

it_current = 0;
for l = 1:length(j)    
    it_current=processingState(l,length(j),it_current);    

    
    x_p = (j(l) - 0.5)*res;
    y_p = (k(l) - 0.5)*res;

    % Find the build where the rx is located
    rx_build_x_1 = (real_wall_points_x(1:2:end) <= x_p);
    rx_build_x_2 = (real_wall_points_x(2:2:end) >= x_p);
    rx_build_x = find((rx_build_x_1 & rx_build_x_2) == 1);
    rx_build_y_1 = (real_wall_points_y(1:2:end) <= y_p);
    rx_build_y_2 = (real_wall_points_y(2:2:end) >= y_p);
    rx_build_y = find((rx_build_y_1 & rx_build_y_2) == 1);
    
    % Check if this building is in the street of the transmitter
    isInLoS = 0;
    wall_sighted = zeros(4,1);
    wall_points = -1*ones(4,2);
    d_to_wall = -1*ones(4,1);
    if (~isempty(bs_street_x))
        if (rx_build_x == bs_street_x) || (rx_build_x == bs_street_x - 1)
            isInLoS = 1;            
            if (rx_build_x + 1 == bs_street_x)
                wall_sighted(1) = 1;
                wall_points(1,:) = [real_wall_points_x(2*rx_build_x), y_p];
                d_to_wall(1) = abs(x_p - real_wall_points_x(2*rx_build_x));
            else
                wall_sighted(3) = 1;
                wall_points(3,:) = [real_wall_points_x(2*rx_build_x - 1), y_p];
                d_to_wall(3) = abs(x_p - real_wall_points_x(2*rx_build_x - 1));
            end
        end        
    end
    if (~isempty(bs_street_y))
        if (rx_build_y == bs_street_y) || (rx_build_y == bs_street_y - 1)
            isInLoS = 1;            
            if (rx_build_y + 1 == bs_street_y)
                wall_sighted(2) = 1;
                wall_points(2,:) = [x_p real_wall_points_y(2*rx_build_y)];
                d_to_wall(2) = abs(y_p - real_wall_points_y(2*rx_build_y));
            else
                wall_sighted(4) = 1;
                wall_points(4,:) = [x_p real_wall_points_y(2*rx_build_y - 1)];
                d_to_wall(4) = abs(y_p - real_wall_points_y(2*rx_build_y - 1));
            end
        end        
    end
    
    if isInLoS
        if sum(wall_sighted) < 2
            num_opt = 1;
        else
            % Two options because the transmitter is in a intersection
            num_opt = 2;
        end
        
        if num_opt == 1
            idx = find(wall_sighted);
            d_in = d_to_wall(idx);           
            d_out = sqrt( (x_bs - wall_points(idx,1))^2 + (y_bs - wall_points(idx,2))^2 );
            
            ps_v1_v2 = ( (x_bs-wall_points(idx,1))*normal_vect(idx,1) + (y_bs-wall_points(idx,2))*normal_vect(idx,2) );           
            normv = sqrt( (x_bs-wall_points(idx,1))^2 + (y_bs-wall_points(idx,2))^2);           
            tetha = pi/2 - acos(ps_v1_v2/normv);
            
            Lth = 9.82 + 5.98*log10(freq/1e9) + 15*(1-sin(tetha))^2;
            Lin = 0.5*d_in;
            
            for nf=1:maxnbfloors
                if nf <= map_h(j(l),k(l))/h_floor
                    hrx_floor = h_floor*(nf - 1) + hrx_eff;
                    Lout = 40*log10(d_out + d_in) + 7.8 - 18*log10(htx_eff) - 18*log10(hrx_floor) + 2*log10(freq/1e9); 
                    Lout = max(Lout,MCL);      
                    PL = Lout + Lth + Lin;
                    loss(nf,j(l),k(l))=max(PL,MCL);
                else
                    loss(nf,j(l),k(l))=NaN;
                end
            end
        else
            
            % First option
            idx = find(wall_sighted,1,'first');
            
            d_in1 = d_to_wall(idx);           
            d_out1 = sqrt( (x_bs - wall_points(idx,1))^2 + (y_bs - wall_points(idx,2))^2 );
            
            ps_v1_v2 = ( (x_bs-wall_points(idx,1))*normal_vect(idx,1) + (y_bs-wall_points(idx,2))*normal_vect(idx,2) );           
            normv = sqrt( (x_bs-wall_points(idx,1))^2 + (y_bs-wall_points(idx,2))^2);           
            tetha = pi/2 - acos(ps_v1_v2/normv);
            
            Lth1 = 9.82 + 5.98*log10(freq/1e9) + 15*(1-sin(tetha))^2;
            Lin1 = 0.5*d_in1;
            
            % Second option
            idx = find(wall_sighted,1,'last');
            
            d_in2 = d_to_wall(idx);           
            d_out2 = sqrt( (x_bs - wall_points(idx,1))^2 + (y_bs - wall_points(idx,2))^2 );
            
            ps_v1_v2 = ( (x_bs-wall_points(idx,1))*normal_vect(idx,1) + (y_bs-wall_points(idx,2))*normal_vect(idx,2) );           
            normv = sqrt( (x_bs-wall_points(idx,1))^2 + (y_bs-wall_points(idx,2))^2);           
            tetha = pi/2 - acos(ps_v1_v2/normv);
            
            Lth2 = 9.82 + 5.98*log10(freq/1e9) + 15*(1-sin(tetha))^2;
            Lin2 = 0.5*d_in2;
            
            for nf=1:maxnbfloors
                if nf <= map_h(j(l),k(l))/h_floor
                    hrx_floor = h_floor*(nf - 1) + hrx_eff;
                    
                    Lout1 = 40*log10(d_out1 + d_in1) + 7.8 - 18*log10(htx_eff) - 18*log10(hrx_floor) + 2*log10(freq/1e9); 
                    Lout1 = max(Lout1,MCL);               
                    PL1 = Lout1 + Lth1 + Lin1;
                    
                    Lout2 = 40*log10(d_out2 + d_in2) + 7.8 - 18*log10(htx_eff) - 18*log10(hrx_floor) + 2*log10(freq/1e9); 
                    Lout2 = max(Lout2,MCL);
                    PL2 = Lout2 + Lth2 + Lin2;                    
                    
                    PL = min(PL1,PL2);
                    
                    loss(nf,j(l),k(l))=max(PL,MCL);
                else
                    loss(nf,j(l),k(l))=NaN;
                end
            end            
        end
    else
        loss(:,j(l),k(l))=NaN;
    end
end
end

%% FUNCTION TO KNOW IF THE RECEIVER IS IN LoS
function LoS = isLoS(j,k,mt,nt,x_p,y_p,x_bs,y_bs,wall_p_x,wall_p_y,slope,ordi,normal_to_x)

    LoS=1;

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
    
    for w=1:length(wall_p_x)
        if wall_sighted_in_x(w)
            x_wall_x = wall_p_x(w);
            y_wall_x = slope*x_wall_x + ordi;            
            build_y_1 = (wall_p_y(1:2:end) <= y_wall_x);     
            build_y_2 = (wall_p_y(2:2:end) >= y_wall_x);
            build_y = (build_y_1 & build_y_2);
            if sum(build_y)~=0
                LoS = 0;
                break;
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
            if sum(build_x)~=0
                LoS = 0;
                break;
            end            
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