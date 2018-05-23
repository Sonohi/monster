function [ Sh , bins , Sc , mu , sig ] = acdf( data , bins , dim , cdim  )
%ACDF Calculate the CDF of a given data set.
%
% [ Sh, bins ] = acdf( data )
% Calculates the Empirical distribution function of the data. The bins are
% chosen equidistantly at 201 positions in between the minimum and maximum
% of the range found in data. For the evaluation, the first nonsingleton
% dimension in data is used.
%
% Sh = acdf( data,bins )
% Like above, but the calculations are done for the given bins.
%
% Sh = acdf( data,bins,dim )
% [ Sh, bins ] = acdf( data,[],dim )
% Like above, but the evaluations are done on the dimension specified in dim.
%
% [ Sh, bins, Sc, mu , sig ] = acdf( data, bins, dim, cdim )
% If a multidimensional data array is given, then this function also
% calculates the statistics over the quantiles.
%
% Input values:
%
%   data  A Data tensor
%   bins  The sample points (x-axis) of the cdf
%   dim   The dimension of the data tensor, on which the cdf will be
%         calculated. (defualt = 1)
%   cdim  The dimension containing independent runs for averaging the cdfs.
%
%
% Output values:
%
%   Sh    Individual CDFs
%   bins  The sample points (x-axis) of the cdf
%   Sc    Combined CDFs.
%   mu    The median values at all 0.1 quantiles of the combined cdf.
%   sig   The std values at all 0.1 quantiles of the combined cdf.
%
% Stephan Jaeckel
% Fraunhofer Heinrich Hertz Institute
% Wireless Communications and Networks
% Einsteinufer 37, 10587 Berlin, Germany
% e-mail: stephan.jaeckel@hhi.fraunhofer.de



% Read the dimension of the input array
ns = size(data);

if ~exist('dim','var')
    dim = find(ns>1,1);
end

if ~exist('cdim','var')
    cdim = 0;
end

if isempty( data )
    Sh   = NaN;
    bins = NaN;
    Sc   = NaN;
    mu   = NaN(9,1);
    sig  = NaN(9,1);
    return
end

if iscell( data )
    dim = 1;
    cdim = 2;
end

if nargin == 1 || isempty( bins )
    if iscell( data )
        temp = cat( 1,data{:} );
    else
        temp = reshape( data , [] , 1 );
    end
    mi = min( temp( temp>-Inf ) );
    ma = max( temp( temp<Inf ) );
    if mi ~= ma
        bins = mi : ( ma-mi ) / 200 : ma;
    else
        mi = 0.9*mi;
        ma = 1.1*ma;
        bins = mi : ( ma-mi ) / 200 : ma;
    end
end

if cdim == dim
    error('Input "cdim" must be different from "dim"') ;
end

% For easy access
no_bins = numel( bins );

if iscell( data )
    
    no_seed =  numel( data );
    
    % Calculate the histograms
    Sh = zeros( no_bins , no_seed );
    for n = 1:no_seed
        tmp = data{n}(:);
        tmp = tmp(~isinf(tmp));
        tmp = tmp(~isnan(tmp));
        Sh(:,n) = hist( tmp , bins );
        Sh(:,n)  = cumsum( Sh(:,n)  ) ./  numel( tmp );
    end
    
    D = Sh;
    
    vals = 0:0.005:0.995;
    
    Sc  = zeros( numel(vals) , 1 );
    Scc = zeros( numel(vals) , no_seed );
    mu = zeros( 9 , 1 );
    sig = zeros( 9 ,1 );
    
    for i_val = 1:numel(vals)
        temp = zeros( no_seed,1 );
        for i_seed = 1:no_seed
            temp( i_seed ) = ...
                bins( find( D(:,i_seed) > vals(i_val) , 1 ) );
        end
        Sc(i_val)    = mean(temp,1);
        Scc(i_val,:) = temp;
    end
    
    for i_mu = 1:9
        ii = i_mu*20-4 : i_mu*20+6;
        tmp = Scc( ii,: );
        mu(i_mu) = mean( tmp(:) );
        sig(i_mu) = std( tmp(:)) ;
    end
    
    % Map to bins
    Sd = zeros(no_bins,1);
    for i_bins = 1:no_bins
        Sd(i_bins) = sum( Sc < bins(i_bins) );
    end
    Sc = Sd./ numel(vals);
    
else
    no_values = ns(dim);
    
    % Reshape the input data
    order = [ dim , setdiff( 1:numel(ns) , dim ) ];
    D = permute( data , order );
    D = reshape(  D , no_values , [] );
    
    % Calculate the histograms
    
    % hist dies not work with Inf values
    ii = find( isinf(D) );
    sgn = sign( D(ii) );
    D( ii(sgn<0) ) = -3.4e38;
    D( ii(sgn>0) ) = 3.4e38;
    
    Sh = hist( D , bins );
    if numel( size(D) ) == 2 && size(D,2) == 1
        Sh = Sh.';
    end
    Sh = cumsum( Sh ) ./ no_values;
    
    % Reshape the output to match input and remove singletons
    nsn = ns( order( 2:end ) );
    if ~(numel(nsn) == 1 && nsn == 1)
        nsn = nsn( nsn~=1 );
    end
    
    % Calculate mu
    if cdim == 0
        vals = 0.1:0.1:0.9;
        mu = zeros( 9 , size(Sh,2) );
        for i_mu = 1:9;
            for i_data  = 1:size(Sh,2)
                mu( i_mu,i_data ) = bins( find( Sh(:,i_data) >= vals(i_mu) , 1) );
            end
        end
        mu  = reshape( mu  , [ 9 , nsn ] );
    end
    
    Sh = reshape( Sh , [ no_bins , nsn ] );
    
    if cdim
        % Reorder to accout for singletons
        temp = find( ns==1 );
        if isempty( temp )
            temp = order;
        else
            temp = order( order ~= temp );
        end
        ncdim = find( temp == cdim );
        
        if isempty( ncdim )
            % Here, cdim is a singleton dimension
            Sc = Sh;
            mu = [];
            sig = [];
        else
            ns = size(Sh);
            order = [ 1 , ncdim , setdiff( 2:numel(ns) , ncdim ) ];
            
            D = permute( Sh , order );
            D = reshape( D , ns(1) , ns(ncdim) , [] );
            
            no_data = size(D,3);
            no_seed = size(D,2);
            
            vals = 0:0.005:0.995;
            
            Sc = zeros( numel(vals) , size(D,3) );
            mu = zeros( 9 , size(D,3) );
            sig = zeros( 9 , size(D,3) );
            
            clear Sc
            i_mu = 1;
            for i_val = 1:numel(vals)
                temp = zeros( no_seed, no_data );
                for i_seed = 1:no_seed
                    for i_data = 1:no_data
                        temp( i_seed,i_data ) = ...
                            bins( find( D(:,i_seed,i_data) > vals(i_val) , 1 ) );
                    end
                end
                Sc(i_val,:) = mean(temp,1);
                
                if any( i_val == 21:20:181 )
                    mu(i_mu,:) = mean(temp,1);
                    sig(i_mu,:) = std( temp) ;
                    i_mu = i_mu + 1;
                end
            end
            
            % Map to bins
            Sd = zeros(no_bins,1);
            for i_bins = 1:no_bins
                Sd(i_bins) = sum( Sc < bins(i_bins) );
            end
            Sc = Sd./ numel(vals);
            
            % Reorder to match initial grid
            if numel( order )>2
                Sc = reshape( Sc  , [ no_bins , ns( order(3:end) ) ] );
                mu  = reshape( mu  , [ 9 , ns( order(3:end) ) ] );
                sig = reshape( sig  , [ 9 , ns( order(3:end) ) ] );
            end
        end
    else
        Sc = Sh;
        sig = zeros( size(mu) );
    end
    
end

end



