function g = calcAntennaResponse(stations, phi, varargin)
% Calculates antenna array responses

% Copyright 2016 The MathWorks, Inc.

narginchk(2, 3);

phiSize = size(phi);

% xxx A lot more input checking is needed if we expose this function

% Sanity check. Should not be hit from our callers.
coder.internal.errorIf(length(stations) ~= phiSize(1), ...
    'winner2:calcAntennaResponse:NumStnAndPhiMismatch');    

if (nargin <= 2)
    theta = ones(phiSize) * pi/2;
else
    % Sanity check. Should not be hit from our callers.
    coder.internal.errorIf(~isequal(phiSize, size(varargin{1})), ...
        'winner2:calcAntennaResponse:PhiAndThetaMismatch');    
    theta = varargin{1};
end

phiLen = prod(phiSize(2:end));

g = cell(1,length(stations));
for idx = 1:length(stations)
    station  = stations(idx);
    stnPhi   = phi(idx, :);
    stnTheta = theta(idx,:);
    numElem  = length(station.Element);
    g{idx}   = complex(zeros(numElem, 3, phiLen));
    fp_gc    = complex(zeros(phiLen*numElem, 2));
            
    % Pol of the wave in GCS
    [i_phi, i_theta] = antenna_pol_vect(stnPhi, stnTheta);

    % DoA in GCS
    wave_dir_gc = sphToCart(stnPhi, stnTheta, ones(1, phiLen));
    % DoA in ACS
    wave_dir_ac = derotateVector(wave_dir_gc, station.Rot);
    
    if isfield(station, 'Aperture') % Preprocessing was used
        [phi_ac, theta_ac] = cartToSph(wave_dir_ac(1,:),wave_dir_ac(2,:),wave_dir_ac(3,:));
        
        if ~isempty(station.Aperture)
            fp = interpbp(station.Aperture, phi_ac, 0);
        else
            fp = ones(numElem*phiLen, 2);
        end
        
        % fp_ac now contains FP for each element and DoA (pols are VH)
        % fp_ac(1,1:2) is FP for first element/first DoA
        % fp_ac(2,1:2) is FP for first element/second DoA
        % pol vectors for each DoA in ACS
        [i_phi_ac, i_theta_ac] = antenna_pol_vect(phi_ac, theta_ac);
        
        for i = 1:numElem
            g{idx}(i,3,:) = calc_dist(station.Element(i).Pos, wave_dir_ac);
        end
        
        % i_phi_ac is the same for all elements
        i_phi_ac   = repmat(i_phi_ac,1,numElem);
        i_theta_ac = repmat(i_theta_ac,1,numElem);
    else % no preprocessing
        fp         = complex(zeros(phiLen*numElem, 2));
        i_phi_ac   = zeros(3,phiLen*numElem);
        i_theta_ac = zeros(3,phiLen*numElem);        
        elements   = station.Element;
        
        for i = 1:numElem            
            j = (i-1)*phiLen + 1:i*phiLen;
            % DoA in ECS
            wave_dir_ec = derotateVector(wave_dir_ac, elements(i).Rot);
            
            [phi_ec, theta_ec] = cartToSph(wave_dir_ec(1,:), wave_dir_ec(2,:), wave_dir_ec(3,:));
            
            % 1. phi 2. theta
            if(~isfield(elements(i),'Aperture') || isempty(elements(i).Aperture))
                fp(j,:) = interpbp(station.CommonAperture, phi_ec, theta_ec);
            else
                fp(j,:) = interpbp(elements(i).Aperture, phi_ec, theta_ec);
            end
            
            % Pol in ECS
            [i_phi_ec,i_theta_ec] = antenna_pol_vect(phi_ec, theta_ec);
            % Pol in ACS
            i_phi_ac(:,j)   = rotateVector(i_phi_ec, elements(i).Rot);
            i_theta_ac(:,j) = rotateVector(i_theta_ec, elements(i).Rot);
            g{idx}(i,3,:)   = calc_dist(elements(i).Pos, wave_dir_ac);
        end
    end
    % pol in GCS
    i_phi_gc   = rotateVector(i_phi_ac, station.Rot);
    i_theta_gc = rotateVector(i_theta_ac, station.Rot);

    % make i_phi/i_theta compatible (wrt. to dimensions) with
    % i_phi_ac/i_theta_ac
    i_phi   = repmat(i_phi,  1, numElem);
    i_theta = repmat(i_theta,1, numElem);
     
    % Project rotated pol-vectors of antenna onto pol-vectors of wave
    % calculation works like this (<,> denotes scalar product):
    % fp_gc_phi  =<i_phi_gc,i_phi>  *fp_ac_phi+<i_theta_gc,i_phi>  *fp_ac_theta
    % fp_gc_theta=<i_phi_gc,i_theta>*fp_ac_phi+<i_theta_gc,i_theta>*fp_ac_theta
    % since i_phi/i_theta are matrices the scalar product cannot be
    % computed by i_phi'*i_phi_ac instead sum() and element-wise product is
    % used
    
    i_phi_proj   = [sum(i_phi.*i_theta_gc).'   sum(i_phi.*i_phi_gc).'];
    i_theta_proj = [sum(i_theta.*i_theta_gc).' sum(i_theta.*i_phi_gc).'];
    
    % fp_gc contains V/H for all elements and all DoAs at once
    fp_gc(:,2) = sum(i_phi_proj  .* fp, 2);
    fp_gc(:,1) = sum(i_theta_proj.* fp, 2);

    g{idx}(:,1,:) = reshape(fp_gc(:,1), phiLen, numElem).';
    g{idx}(:,2,:) = reshape(fp_gc(:,2), phiLen, numElem).';

    % Reshape to fit size of input phi/theta
    g{idx} = reshape(g{idx}, [numElem, 3, phiSize(2:end)]);
end

end

function [i_phi, i_theta] = antenna_pol_vect(phi, theta)
% Returns the polarization vectors of an antenna for azimuth/elevation
% phi/theta

i_theta = [cos(theta) .* cos(phi);
            cos(theta) .* sin(phi);
           -sin(theta)];
      
% Normalize theta
i_theta = i_theta ./ sqrt(sum(i_theta.^2));

i_phi = [-sin(theta) .* sin(phi);
          sin(theta) .* cos(phi);
          zeros(1, length(phi))];

% At the poles where phi is zero, but we know that it can be created by the
% cross product of i_theta and the DoA/DoD
power = sqrt(sum(i_phi.^2));
idx = find(power == 0);
if ~isempty(idx)
    i_phi(:, idx) = cross(sphToCart(phi(idx), ...
        theta(idx), ones(1, length(idx))), i_theta(:,idx));
    power(idx) = sqrt(sum(i_phi(:, idx).^2)); 
end

% Normalize phi
i_phi = i_phi ./ power;

end

function cart = sphToCart(az, elev, r)
% Convert spherical to cartesian coordinates, where elev is the angle
% from positive z-axis and az the angle from the positive x-axis

[x, y, z] = sph2cart(az, pi/2 - elev, r);

cart = [x; y; z];

end

function [az, elev, r] = cartToSph(x, y, z)
% Convert cartesian to spherical coordinates, , where elev is the angle
% from positive z-axis and az the angle from the positive x-axis

[az, elev, r] = cart2sph(x, y, z);
elev = pi/2 - elev;
    
end

function mtx = getRotationMatrix(b)
% M is 3x3 unitary, i.e., M'*M = eye(3)

mtx = [cos(b(2))*cos(b(3)), ...
       (-cos(b(1))*sin(b(3))+sin(b(1))*sin(b(2))*cos(b(3))), ...
       (sin(b(1))*sin(b(3))+cos(b(1))*sin(b(2))*cos(b(3))); ...
       cos(b(2))*sin(b(3)), ...
       (cos(b(1))*cos(b(3))+prod(sin(b))), ...
       (-sin(b(1))*cos(b(3))+cos(b(1))*sin(b(2))*sin(b(3)));
       -sin(b(2)), ...
       sin(b(1))*cos(b(2)), ...
       cos(b(1))*cos(b(2))];
end

function y = derotateVector(x, rot)

y = getRotationMatrix(rot)' * x; 

end

function y = rotateVector(x, rot)

y = getRotationMatrix(rot) * x; 

end

function g = interpbp(apertur, Az, ~)
% Interpolates 2D-beampattern (azimuth-only) of EADF given in 'apertur' at
% azimuth angles and given in 'Az'. Parameter 'Ele' is ignored for now
% 'Az' must contain azimuth angles in radians and has to be a column vector

[~, L13] = size(apertur.G13);
[~, L24] = size(apertur.G24);

daz = apertur.saz; 
elements = apertur.elements; 

pol = apertur.pol;
nrsAz = (daz-1);
apaz13 = L13/pol/elements;

mueAz = (-nrsAz:0);

faz = exp(1i*(mueAz'*Az));
refaz = real(faz);
imfaz = imag(faz);

g = complex( refaz.'*real(reshape(apertur.G13,[apaz13 L13/apaz13])) + ...
             imfaz.'*real(reshape(apertur.G24,[apaz13 L24/apaz13])), ...
             refaz.'*imag(reshape(apertur.G13,[apaz13 L13/apaz13])) + ...
             imfaz.'*imag(reshape(apertur.G24,[apaz13 L24/apaz13])));
         
g = reshape(g(:), [], 2);

end

function dist = calc_dist(a, b)
% Calculates the projection of a to b, where b is normalized to have
% unit length

dist = a.' * (b./sqrt(sum(b.^2))); % Normalization

end