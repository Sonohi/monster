function Cc = correction_function( L,K )
%CORRECTION_FUNCTION Corrects the initial RMS Angular spread
%
% The correction function C takes the influence of the K-Factor and the
% varying number of clusters on the angular spreads into account. To
% approximate the function, we generated the angles as implemented in
% 'generate_initial_angles' with C set to one. Then we calculated the
% angular spread from the simulated data and compare the output of the
% procedure with the given value.
%
% Stephan Jaeckel
% Fraunhofer Heinrich Hertz Institute
% Wireless Communication and Networks
% Einsteinufer 37, 10587 Berlin, Germany
% e-mail: stephan.jaeckel@hhi.fraunhofer.de

N = numel(K);
if numel(L) == 1
    L = ones(1,N)*L;
end

% Set maximum range
L( L<3 ) = 3;
L( L>42 ) = 42;
K( K<-20) = -20;
K( K>20) = 20;

% The correction function at some initial values
cL = [ 3, 6, 9,12,15,18,21,24,27,30,33,36,39,42];
cK = [-20,-18,-16,-14,-12,-10,-8,-6,-4,-2, 0, 2, 4, 6, 8,10,12,14,16,18,20];
C = [0.54,0.81,0.89,0.92,0.94,0.95,0.96,0.97,0.97,0.98,0.98,0.98,0.98,0.99;...
    0.58,0.82,0.90,0.93,0.95,0.96,0.97,0.97,0.98,0.98,0.98,0.98,0.99,0.99;...
    0.62,0.84,0.91,0.94,0.96,0.97,0.97,0.97,0.97,0.98,0.98,0.98,0.98,0.98;...
    0.66,0.86,0.92,0.94,0.95,0.96,0.96,0.96,0.97,0.96,0.96,0.97,0.96,0.96;...
    0.70,0.88,0.92,0.94,0.94,0.94,0.94,0.94,0.94,0.96,1.00,1.07,1.14,1.20;...
    0.74,0.88,0.90,0.91,0.91,0.92,0.98,1.08,1.18,1.26,1.34,1.39,1.45,1.49;...
    0.76,0.85,0.86,0.89,1.02,1.17,1.29,1.38,1.46,1.52,1.58,1.63,1.66,1.71;...
    0.74,0.77,0.91,1.14,1.30,1.41,1.50,1.57,1.64,1.69,1.75,1.78,1.83,1.85;...
    0.65,0.84,1.15,1.34,1.47,1.56,1.64,1.70,1.75,1.79,1.83,1.87,1.90,1.94;...
    0.52,1.05,1.30,1.44,1.55,1.62,1.68,1.74,1.79,1.82,1.85,1.89,1.91,1.93;...
    0.67,1.15,1.34,1.46,1.55,1.61,1.65,1.70,1.73,1.77,1.80,1.82,1.85,1.87;...
    0.80,1.16,1.31,1.41,1.47,1.53,1.57,1.60,1.63,1.66,1.68,1.70,1.72,1.74;...
    0.84,1.11,1.23,1.31,1.36,1.40,1.43,1.47,1.49,1.51,1.53,1.55,1.56,1.57;...
    0.82,1.03,1.12,1.18,1.22,1.25,1.28,1.31,1.32,1.34,1.35,1.37,1.38,1.39;...
    0.77,0.92,0.99,1.03,1.07,1.09,1.11,1.13,1.15,1.16,1.17,1.18,1.18,1.19;...
    0.69,0.80,0.85,0.89,0.91,0.93,0.94,0.96,0.97,0.98,0.99,0.99,1.01,1.01;...
    0.60,0.68,0.72,0.74,0.77,0.78,0.80,0.80,0.81,0.82,0.82,0.84,0.84,0.84;...
    0.51,0.57,0.60,0.62,0.63,0.64,0.66,0.66,0.67,0.67,0.67,0.69,0.69,0.69;...
    0.43,0.47,0.50,0.51,0.52,0.53,0.54,0.54,0.55,0.55,0.55,0.55,0.57,0.57;...
    0.36,0.39,0.41,0.41,0.42,0.43,0.43,0.44,0.44,0.45,0.45,0.45,0.45,0.45;...
    0.29,0.32,0.32,0.33,0.34,0.35,0.35,0.35,0.35,0.35,0.35,0.36,0.36,0.37];

noL = numel(cL);
noK = numel(cK);

% THe linear interpolation for intermediate values
[tmp,b] = sort( L );
[~,a]   = sort( [cL,tmp] );
ui      = 1:(noL + N);
ui(a)   = ui;
ui      = ui(noL+1:end) - (1:N);
ui(b)   = ui;
ui( ui==noL ) = noL-1;
uin     = ui+1;
u       = (L-cL(ui))./( cL(uin)-cL(ui) );
u       = u';

[tmp,b] = sort( K );
[~,a]   = sort( [cK,tmp] );
vi      = 1:(noK + N);
vi(a)   = vi;
vi      = vi(noK+1:end) - (1:N);
vi(b)   = vi;
vi( vi==noK ) = noK-1;
vin     = vi+1;
v       = (K-cK(vi))./( cK(vin)-cK(vi) );
v       = v';

c1 = (1-v).*(1-u);
c2 = (1-v).*u;
c3 = v.*(1-u);
c4 = v.*u;

pa = vi  + ( ui  -1 )*noK;
pb = vi  + ( uin -1 )*noK;
pc = vin + ( ui  -1 )*noK;
pd = vin + ( uin -1 )*noK;

ndx = [pa,pb,pc,pd];
a = C( ndx );
a = reshape( a,N,4 );

% The output
Cc = c1.*a(:,1) + c2.*a(:,2) + c3.*a(:,3) + c4.*a(:,4);

