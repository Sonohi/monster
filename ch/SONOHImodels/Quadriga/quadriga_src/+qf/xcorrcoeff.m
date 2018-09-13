function c = xcorrcoeff (a,b)
%XCORRCOEFF Calculates the correlation coefficient of two vectors
%
% Stephan Jaeckel
% Fraunhofer Heinrich Hertz Institute
% Wireless Communication and Networks
% Einsteinufer 37, 10587 Berlin, Germany
% e-mail: stephan.jaeckel@hhi.fraunhofer.de

if size(a,1) == 1
    a = a.';
    b = b.';
    turn = true;
else
    turn = false;
end

s = numel(a);
c =( (b'*a)/s - sum(a)*sum(b',2)/s^2 ) ./...
    sqrt( (sum(abs(a).^2)/s - abs(sum(a)/s).^2) * (sum(abs(b).^2)/s - abs(sum(b)/s).^2)' ) ;

if turn
    c = c.';
end