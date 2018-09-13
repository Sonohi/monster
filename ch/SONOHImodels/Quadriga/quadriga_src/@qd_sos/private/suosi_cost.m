function [ cst, Rh  ] = suosi_cost( R, D, fr, phi, theta )

N = numel(R);
L = numel(fr);

if ~exist( 'phi','var' )
    phi = [];
end

if ~exist( 'theta','var' )
    theta = [];
end

if ~isempty( phi ) && isempty( theta ) % 2D
    tmp = fr .* exp( 1j*phi(1:L) );
    fr(:,1) = real( tmp );
    fr(:,2) = imag( tmp );
    fr(:,3) = (fr(:,1) + fr(:,2))/sqrt(2); % Diagonals
    fr(:,4) = (fr(:,1) - fr(:,2))/sqrt(2);
    
elseif ~isempty( phi ) && ~isempty( theta ) % 3D
    tmp = fr;
    fr(:,1) = tmp .* cos(phi(1:L)) .* cos(theta(1:L));
    fr(:,2) = tmp .* sin(phi(1:L)) .* cos(theta(1:L));
    fr(:,3) = tmp .* sin(theta(1:L));

    fr(:,4) = (fr(:,1) + fr(:,2))/sqrt(2); % Diagonals x-y
    fr(:,5) = (fr(:,1) - fr(:,2))/sqrt(2);
    
    fr(:,6) = (fr(:,1) + fr(:,3))/sqrt(2); % Diagonals x-z
    fr(:,7) = (fr(:,1) - fr(:,3))/sqrt(2);
    
    fr(:,8) = (fr(:,2) + fr(:,3))/sqrt(2); % Diagonals y-z
    fr(:,9) = (fr(:,2) - fr(:,3))/sqrt(2);
end

dim = size( fr,2 );
odim = ones( 1,dim,'uint8' );

PG = 2*pi*1j*D;
Rh = exp( fr(:) * PG );

Rh = reshape( Rh , L , dim, N );
Rh = abs( sum( Rh,1 ) )/L;
Rh = permute( Rh, [2,3,1] );

cst = sum( (R(odim,:)-Rh).^2 ,2 ).' / N;
cst = sum( cst ) / dim;

end
