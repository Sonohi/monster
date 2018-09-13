function [ h_channel, h_builder ] = get_channels( h_layout, sampling_rate, check_parfiles, overlap )
%GET_CHANNELS Calculate the channel coefficients.
%
% Calling object:
%   Single object
%
% Description:
%   This is the most simple way to create the channel coefficients. This function executes all
%   steps that are needed to generate the channel coefficients. Hence, it is not necessary to use
%   use the 'qd_builder' objects.
%
% Input:
%   sampling_rate
%   channel update rate in [s]. This parameter is only used if a speed profile is provided in the
%   track objects. Default value: 0.01 = 10 ms
%
%   check_parfiles
%   check_parfiles = 0 / 1 (default: 1) Disables (0) or enables (1) the parsing of shortnames and
%   the validity-check for the config-files. This is useful, if you know that the parameters in the
%   files are valid. In this case, this saves execution time.
%
% Output:
%   h_channel
%   A vector channel objects.
%
%   h_builder
%   A vector of 'qd_builder' objects.
%
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel( h_layout ) > 1 
   error('QuaDRiGa:qd_layout:set_scenario','set_scenario not definded for object arrays.');
else
    h_layout = h_layout(1,1); % workaround for octave
end

% Parse input variables
if exist( 'sampling_rate','var' ) && ~isempty( sampling_rate )
    if ~( all(size(sampling_rate) == [1 1]) &&...
            isnumeric(sampling_rate) &&...
            isreal(sampling_rate) && sampling_rate > 0 )
        error('??? Invalid sampling interval. The value must be real and > 0.')
    end
else
    sampling_rate = 10e-3; % 10 ms
end

if ~exist( 'check_parfiles' , 'var' ) || isempty( check_parfiles )
    check_parfiles = true;
end

if exist( 'overlap' , 'var' ) && ~isempty( overlap )
    if ~( isnumeric(overlap) && all(size(overlap) == [1 1]) && isreal(overlap) ...
            && overlap<=1 && overlap>=0 )
        error('??? "overlap" must be scalar, and in between 0 and 1')
    end
else
    overlap = 0.5;
end

verbose = h_layout.simpar.show_progress_bars;

% Print status message
if verbose
    if ~strcmp( h_layout.name , 'Layout' )
        disp(['Layout: ',h_layout.name])
    end
    start_time_model_run = clock;
    str = num2str( h_layout.no_rx );
    if h_layout.no_rx == 1
        str = [ str, ' receiver, ' ];
    else
        str = [ str, ' receivers, ' ];
    end
    str = [ str, num2str( h_layout.no_tx ) ];
    if h_layout.no_tx == 1
        str = [ str, ' transmitter, ' ];
    else
        str = [ str, ' transmitters, ' ];
    end
    str = [ str, num2str(numel(h_layout.simpar.center_frequency)) ];
    if numel(h_layout.simpar.center_frequency) == 1
        str = [ str, ' frequency (' ];
    else
        str = [ str, ' frequencies (' ];
    end
    str = [ str, sprintf('%1.1f GHz, ', h_layout.simpar.center_frequency/1e9) ];
    str = [ str(1:end-2) , ')'];

    disp(['Starting channel generation using QuaDRiGa v',h_layout.simpar.version]);
    disp(str);
end


% Check if tracks fulfill the sampling theoreme
samling_limit = min( h_layout.simpar.wavelength / 2 );
sampling_ok = true;
has_speed_profile = false;
for i_rx = 1 : h_layout.no_rx
    if h_layout.track(1,i_rx).no_snapshots > 1
        [~,dist] = h_layout.track(1,i_rx).get_length;
        if any( diff(dist) > samling_limit )
            sampling_ok = false;
        end
        if ~isempty( h_layout.track(1,i_rx).movement_profile )
            has_speed_profile = true;
        end
    end
end

if ~sampling_ok
    warning('QuaDRiGa:layout:get_channels:sampling_ok',...
        'Sample density in tracks does not fulfill the sampling theoreme.');
    
    if has_speed_profile % Change sample density
        h_layout.simpar.sample_density = 2.5;
        for i_rx = 1 : h_layout.no_rx
            if h_layout.track(1,i_rx).no_snapshots > 1
                h_layout.track(1,i_rx).interpolate_positions( h_layout.simpar.samples_per_meter );
            end
        end
        warning('QuaDRiGa:layout:get_channels:sampling_ok',...
            'Sample density was adjustet to match the sampling theoreme.');
    end
end

% Create builder objects
if verbose
    fprintf('Generating channel builder objects')
end
h_builder = h_layout.init_builder( check_parfiles );
if verbose
    if numel( h_builder ) == 1;
        fprintf(' - 1 builder, ')
    else
        fprintf([' - ',num2str(numel( h_builder )),' builders, '])
    end
    cnt = 0;
    sic = size( h_builder );
    for i_cb = 1 : numel(h_builder)
        [ i1,i2 ] = qf.qind2sub( sic, i_cb );
        cnt = cnt + h_builder(i1,i2).no_rx_positions;
    end
    cnt = cnt * numel(h_layout.simpar.center_frequency);
    if cnt == 1
        fprintf('1 channel segment\n')
    else
        fprintf([num2str(cnt),' channel segments\n'])
    end
end

% Generate LSF parameters
if verbose
    disp('Generating LSF parameters')
end
gen_lsf_parameters( h_builder);

% Generate SSF parameters
if verbose
    disp('Generating SSF parameters')
end
gen_ssf_parameters( h_builder );

% Split builder object for multi-frequency simulations
n_freq = numel( h_layout.simpar.center_frequency );
if n_freq > 1
    if verbose
        fprintf('Preparing multi-frequency simulations')
    end
    h_builder = split_multi_freq( h_builder );
    if verbose
        fprintf([' - ',num2str(numel( h_builder )),' builders\n'])
    end
end

% Generate channel coefficients
h_channel = get_channels( h_builder );

% Merge channel coefficients
h_channel = merge( h_channel, overlap, verbose);

% Get names
n_channel = numel(h_channel);
names = {};
for i_channel = 1:n_channel
    names{i_channel} = h_channel(1,i_channel).name;
end

% Determine, if channel interpolation is needed
values = h_layout.no_rx;
tmp = { h_layout.track.movement_profile };
need_to_interpolate = false;
i_trk = 1;
while ~need_to_interpolate && i_trk <= values
    if ~isempty( tmp{i_trk} )
        need_to_interpolate = true;
    end
    i_trk = i_trk + 1;
end

if need_to_interpolate
    tStart = clock;
    if verbose; fprintf('Interpolate  ['); end; m0=0;
    
    % Apply speed profile, if provided
    channels_done = false(1,n_channel);
    for i_trk = 1 : h_layout.no_rx
        if verbose; m1=ceil(i_trk/values*50); if m1>m0; for m2=1:m1-m0; fprintf('o'); end; m0=m1; end; end;
        
        trk = h_layout.track(1,i_trk);
        
        if ~isempty( trk.movement_profile )
            pos_snap = [0,cumsum(abs(diff( trk.positions(1,:) + 1j*trk.positions(2,:) )))];
            dist = trk.interpolate_movement( sampling_rate );
            length = trk.get_length;
            
            for i_channel = 1 : n_channel
                if ~channels_done( i_channel )
                    if ~isempty( regexp( names{i_channel} ,  trk.name, 'once' ) )
                        par = h_channel(1,i_channel).par;
                        
                        % Interpolate path gain
                        if isfield( par,'pg' ) && size(par.pg,2) == h_channel(1,i_channel).no_snap
                            par.pg = spline( pos_snap , par.pg , dist );
                        end
                        
                        h_channel(1,i_channel) = interpolate( h_channel(1,i_channel), dist, 'spline' );
                        h_channel(1,i_channel).par = par;
                        channels_done( i_channel ) = true;
                    end
                end
            end
        end
    end
    
    if verbose
        fprintf('] %5.0f seconds\n',round( etime(clock, tStart) ));
    end
end

% Reshape the channel object to the form [ Rx , Tx , Freq ]
if verbose
    fprintf('Formatting outout channels')
end
if numel(h_channel) == h_layout.no_rx * h_layout.no_tx * n_freq
    h_channel = qf.reshapeo( h_channel, [ h_layout.no_rx, h_layout.no_tx, n_freq ] );
end
if verbose
    if numel( h_channel ) == 1
        fprintf([' - 1 channel object\n'])
    else
        fprintf([' - ',num2str(numel( h_channel )),' channel objects\n'])
    end
end
if verbose
    disp(['Total runtime: ', num2str(round( etime(clock, start_time_model_run))),' seconds']);
end

end
