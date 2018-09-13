function zi = interp( x, y, z, xc, yc )
%INTERP 2D Linear Interpolation optimized for speed
%
% Input:
%   x   The x sample points
%   y   The y sample points
%   z   The data [ ny, nx, ne ]
%       The third dimesnion can be used to interpolate several matrices at once
%   xc  The x sample points after interpolation
%   yc  The y sample points after interpolation
%   
% Output:
%   zi  The interpolated data [ nyc, nxc, ne ]
%
% You can interpolate 1D functions by:
%   zi = interp( x, 0, z, xc )
% 
% In this case z must have the size: [ 1, nx, ne ]
%
% All calculations are in single precision to increase speed by ~30%. 
% Output will be in singel precision as well.

z = single( z );
x = single( x(:).' );
y = single( y(:).' );

nx = numel(x);
ny = numel(y);
ne = size( z,3 );

if size( z,1 ) ~= ny || size( z,2 ) ~= nx
    error('Size of z does not match');
end

% Option for 1D linear interpolation
if ny == 1
    y  = 0;
    yc = 0;
    z  = z(:);
end

nxc = numel(xc);
nyc = numel(yc);
oxc = ones(1,nxc,'uint8');
oyc = ones(1,nyc,'uint8');

xi = reshape( single(xc) , 1, [] );
xi = xi( oyc,: );
xi = xi(:).';

yi = reshape( single(yc) , [] , 1 );
yi = yi( :,oxc );
yi = yi(:).';

ni = numel(xi);
ii = uint32( 1:ni );

% Determine the nearest location of xi in x and the difference to
% the next point
[tmp,b] = sort( xi );
[~,a]   = sort( [x,tmp] );
ui      = uint32( 1:(nx + ni) );
ui(a)   = ui;
ui      = ui(nx+1:end) - ii;
ui(b)   = ui;
ui( ui==nx ) = nx-1;
ui( ui==0 ) = 1;
uin     = ui+1;
u       = (xi-x(ui))./( x(uin)-x(ui) );
u       = u';

% Determine the nearest location of yi in y and the difference to
% the next point
if ny > 1
    [tmp,b] = sort( yi );
    [~,a]   = sort( [y,tmp] );
    vi      = uint32( 1:(ny + ni) );
    vi(a)   = vi;
    vi      = vi(ny+1:end) - ii;
    vi(b)   = vi;
    vi( vi==ny ) = ny-1;
    vi( vi==0 ) = 1;
    vin     = vi+1;
    v       = (yi-y(vi))./( y(vin)-y(vi) );
    v       = v';
else
    vi  = uint32( 1 );
    vin = uint32( 1 );
    v   = zeros( ni,1,'single' );
end

% Calculate the scaling coefficients
c1 = (1-v).*(1-u);
c2 = (1-v).*u;
c3 = v.*(1-u);
c4 = v.*u;

% Determine the indices of the elements
pa = vi  + ( ui  -1 )*ny;
pb = vi  + ( uin -1 )*ny;
pc = vin + ( ui  -1 )*ny;
pd = vin + ( uin -1 )*ny;

pX = [pa,pb,pc,pd].';
pY = uint32( (0:ne-1)*nx*ny );

tr = true( ni,1 );
fl = false( ni,1 );
i1 = [tr;fl;fl;fl];
i2 = [fl;tr;fl;fl];
i3 = [fl;fl;tr;fl];
i4 = [fl;fl;fl;tr];

% Interpolate
zi = zeros( ni, ne );
for n = 1 : ne
    ndx = pY(n) + pX;
    a = z( ndx );
    zi(:,n) = c1.*a(i1) + c2.*a(i2) + c3.*a(i3) + c4.*a(i4);
end

zi = reshape(zi,nyc,nxc,ne);

end
