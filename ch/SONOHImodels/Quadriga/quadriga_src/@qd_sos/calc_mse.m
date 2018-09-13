function [ mse_core, mse_all, Ro, Ri ] = calc_mse( h_sos )
%CALC_MSE Calculates the approximation MSE of the ACF
%
%   This method calculates the means-square error (in dB) of the approximation of the given ACF.
%
% Output:
%   mse_core    The MSE for the range 0 to Dmax (covered by the desired ACF)
%   mse_all     The MSE for the range 0 to 2*Dmax
%   Ro          Approximated ACF from qd_sos.acf_approx
%   Ri          Interpolated ACF (from qd_sos.acf_2d in case of 2 dimensions or more)
%
% QuaDRiGa Copyright (C) 2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel( h_sos ) > 1 
   error('QuaDRiGa:qd_sos:calc_mse','calc_mse not definded for object arrays.');
else
    h_sos = h_sos(1,1); % workaround for octave
end

if h_sos.dimensions == 1
    Ri = h_sos.acf;
    N = numel(Ri);
    Ri = [ zeros(1,N-1), Ri(end:-1:2), Ri, zeros(1,N-1) ];
    Ro = h_sos.acf_approx;
    
    mse_all  = -10*log10( mean( (Ro(:)-Ri(:)).^2 ) );
    ii       = 2*N-1 : 3*N-2;
    mse_core = -10*log10( mean( (Ro(ii)-Ri(ii)).^2 ) );
    
else
    
    Ri = h_sos.acf_2d;
    Ro = h_sos.acf_approx;
    
    N = numel(h_sos.acf);
    on = ones(1,4*N-3,'uint8');
    p = (1:4*N-3)-2*N+1;
    p = p.^2;
    ii = sqrt(p(on,:) + p(on,:)') <= N;
    
    if h_sos.dimensions == 2
        mse_all = -10*log10( mean( (Ro(:)-Ri(:)).^2 ) );
        mse_core = -10*log10( mean( (Ro(ii)-Ri(ii)).^2 ) );
    else
        for n = 1:3
            R3 = Ro(:,:,n);
            mse_all(n) = mean( (R3(:)-Ri(:)).^2 );
            mse_core(n) = mean( (R3(ii)-Ri(ii)).^2 );
        end
        mse_all = -10*log10( mean( mse_all ));
        mse_core = -10*log10( mean( mse_core ));
    end
    
end

h_sos.approx_mse = [mse_core,mse_all];

end

