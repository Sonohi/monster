function gen_lsf_parameters( h_builder, force )
%GEN_LSF_PARAMETERS Generates the LSF parameters for all terminals. 
%
% Calling object:
%   Object array
%
% Description:
%   This function calculates correlated large scale parameters for each user position. Those
%   parameters are needed by the channel builder to calculate initial SSF parameters for each track
%   or segment which are then evolved into time varying channels.  By default, 'gen_lsf_parameters'
%   reads the values given in the 'qd_track' objects of the 'qd_layout'. If there are no values
%   given or if parts of the values are missing, the correlation maps are generated to extract the
%   missing parameters.
%
% Input:
%   force
%   force = 0 (default) Tries to read the parameters from 'qd_layout.track.par'. If they are not
%   provided or it they are incomplete, they are completed with values from the correlated LSP maps
%   (the qd_sos objects). If the maps are invalid (e.g. because they have not been generated yet),
%   new maps are created.
%   force = 1 Creates new maps and reads the LSP from those maps. Values from
%   'qd_layout.track.par' are ignored. Note that the parameters 'pg' and 'kf' will still be taken
%   from 'qd_layout.track.par' when generating channel coefficients.
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.


% Parse input variables.
if ~exist( 'force','var' ) || isempty( force )
    force = false;
end

% Parse Tx-Names from builder names
tx_name = {};
for i_bld1 = 1 : size(h_builder,1)
    for i_bld2 = 1 : size(h_builder,2)
        % Parse tx index
        tmp = regexp( h_builder(i_bld1,i_bld2).name , '_' );
        tx_name_local = h_builder(i_bld1,i_bld2).name( tmp+1:end );
        tx_name{ i_bld1,i_bld2 } = tx_name_local;
    end
end
no_tx = numel( tx_name );

for i_bld1 = 1 : size(h_builder,1)
    for i_bld2 = 1 : size(h_builder,2)
        
        no_rx   = h_builder(i_bld1,i_bld2).no_rx_positions;
        no_freq = numel( h_builder(i_bld1,i_bld2).simpar.center_frequency );
        
        if no_rx > 0
            
            % Check if LSP xcorr matrix is positive definite
            if ~h_builder(i_bld1,i_bld2).lsp_xcorr_chk
               error('QuaDRiGa:qd_builder:gen_lsf_parameters','LSP xcorr matrix is not positive definite.'); 
            end
            
            % We only need to create parameters if there are MTs in the parset
            ksi = zeros(8,no_rx,no_freq);
            
            if force
                % Ignore all other parameters from the track objects and previously generated (valid) parameters
                % Inittiaize new set of parameters
                h_builder(i_bld1,i_bld2).sos = [];
                ksi = h_builder(i_bld1,i_bld2).get_lsp_val;
                
            elseif h_builder(i_bld1,i_bld2).data_valid
                % Copy existing data from the builder object
                ksi(1,:,:) = permute( h_builder(i_bld1,i_bld2).ds , [3,2,1] );
                ksi(2,:,:) = permute( h_builder(i_bld1,i_bld2).kf , [3,2,1] );
                ksi(3,:,:) = permute( h_builder(i_bld1,i_bld2).sf , [3,2,1] );
                ksi(4,:,:) = permute( h_builder(i_bld1,i_bld2).asD , [3,2,1] );
                ksi(5,:,:) = permute( h_builder(i_bld1,i_bld2).asA , [3,2,1] );
                ksi(6,:,:) = permute( h_builder(i_bld1,i_bld2).esD , [3,2,1] );
                ksi(7,:,:) = permute( h_builder(i_bld1,i_bld2).esA , [3,2,1] );
                ksi(8,:,:) = permute( h_builder(i_bld1,i_bld2).xpr , [3,2,1] );
                
            else % Data is invalid
                
                % Inittiaize new set of parameters
                % If SOS objects are existing, we reuse them
                ksi = h_builder(i_bld1,i_bld2).get_lsp_val;
                
                % There might be parameters in the track objects. If so, the values in "ksi" are overwritten
                % Parse Tx-Number from parameter_set name
                tmp = regexp( h_builder(i_bld1,i_bld2).name , '_' );
                tx_name_local = h_builder(i_bld1,i_bld2).name( tmp+1:end );
                tx_ind = strcmp( tx_name , tx_name_local );
                
                par_fieldnames = {'ds','kf','pg','asD','asA','esD','esA','xpr'};
                
                data_complete = true;
                for n = 1 : numel( h_builder(i_bld1,i_bld2).rx_track )
                    % Temporary copy of the par struct for faster access
                    par = h_builder(i_bld1,i_bld2).rx_track(1,n).par;
                    
                    if ~isempty( par )
                        seg_ind = h_builder(i_bld1,i_bld2).rx_track(1,n).segment_index(end);
                        
                        for p = 1:8
                            % Temporarily read values
                            tmp = par.( par_fieldnames{p} );
                            
                            if size(tmp,1) == no_tx
                                t_ind = tx_ind;
                            elseif size(tmp,1) == 1
                                t_ind = 1;
                            elseif isempty( tmp )
                                % OK
                                data_complete = false;
                            else
                                error('QuaDRiGa:qd_builder:gen_lsf_parameters','Invalid dimensions of "track.par"');
                            end
                            
                            % Copy the data to the parameter matrix
                            if ~isempty( tmp )
                                if p == 2 % KF
                                    ksi( p,n,: ) = 10.^( 0.1 *tmp(t_ind,seg_ind,:) );
                                    
                                elseif p == 3 % SF
                                    % Read PG, SF, and O2I combined from track
                                    PGSF = tmp(t_ind,seg_ind,:); 
                                    
                                    % PG and O2I at initial position
                                    [ ~, ~, PG, scale_sf ] = h_builder(i_bld1,i_bld2).get_pl( h_builder(i_bld1,i_bld2).rx_track(1,n) );
                                    
                                    SF = permute(PG,[3,2,1]) + PGSF;
                                    SF = SF ./ permute(scale_sf,[3,2,1]);
                                    ksi( p,n,: ) = 10.^( 0.1 *SF );

                                elseif p == 8 % XPR
                                    ksi( p,n,: ) = 10.^( 0.1 *tmp(t_ind,end,:) );
                                    
                                else % DS, AS
                                    ksi( p,n,: ) = tmp(t_ind,end,:);
                                    
                                end
                            end
                        end
                    else
                        data_complete = false;
                    end
                end
                
                if data_complete
                    % If all data comes from the tracks, remove the SOS objects. They are note used anywehere.
                    h_builder(i_bld1,i_bld2).sos = [];
                end
            end
            
            % We set the private parameters here. If the public parameters are set, the maps are discarded. This is not
            % intended here, since the maps are needed to interpolate the PG ans SF in the channel builder.
            h_builder(i_bld1,i_bld2).ds  = permute( ksi(1,:,:) , [3,2,1] );
            h_builder(i_bld1,i_bld2).kf  = permute( ksi(2,:,:) , [3,2,1] );
            h_builder(i_bld1,i_bld2).sf  = permute( ksi(3,:,:) , [3,2,1] );
            h_builder(i_bld1,i_bld2).asD = permute( ksi(4,:,:) , [3,2,1] );
            h_builder(i_bld1,i_bld2).asA = permute( ksi(5,:,:) , [3,2,1] );
            h_builder(i_bld1,i_bld2).esD = permute( ksi(6,:,:) , [3,2,1] );
            h_builder(i_bld1,i_bld2).esA = permute( ksi(7,:,:) , [3,2,1] );
            h_builder(i_bld1,i_bld2).xpr = permute( ksi(8,:,:) , [3,2,1] );
            h_builder(i_bld1,i_bld2).data_valid = true;
        end
    end
end

end