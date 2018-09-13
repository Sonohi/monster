function h_builder = init_builder( h_layout, check_parfiles )
%INIT_BUILDER Creates 'qd_builder' objects based on layout specification
%
% Calling object:
%   Single object
%
% Description:
%   This function processes the data in the 'qd_layout' object. First, all tracks in the layout are
%   split into subtracks. Each subtrack corresponds to one segment. Then, then scenario names are
%   parsed. A 'qd_builder' object is created for each scenario and for each transmitter. For
%   example, if there are two BS, each having urban LOS and NLOS users, then 4 'qd_builder' objects
%   will be created (BS1-LOS, BS2-NLOS, BS2-LOS, and BS2-NLOS). The segments are then assigned to
%   the 'qd_builder' objects.
%
% Input:
%   check_parfiles
%   Enables (1, default) or disables (0) the parsing of shortnames and the validity-check for the
%   config-files. This is useful, if you know that the parameters in the files are valid. In this
%   case, this saves some execution time.
%
% Output:
%   h_builder
%   A matrix of 'qd_builder' objects. Rows correspond to the scenarios, columns correspond to the
%   transmitters.
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
   error('QuaDRiGa:qd_layout:init_builder','set_scenario not definded for object arrays.');
else
    h_layout = h_layout(1,1); % workaround for octave
end

% Parse Input variables
if exist( 'check_parfiles' , 'var' )
    if ~( all(size(check_parfiles) == [1 1]) ...
            && (isnumeric(check_parfiles) || islogical(check_parfiles)) ...
            && any( check_parfiles == [0 1] ) )
        error('??? "check_parfiles" must be 0 or 1')
    end
else
    check_parfiles = true;
end

scenarios   = h_layout.track(1,1).scenario(1,1);   % Scenario of the first segment
tracks      = cell(1,h_layout.no_tx);
rx          = cell(1,h_layout.no_tx);
tx          = cell(1,h_layout.no_tx);
position    = cell(1,h_layout.no_tx);

% The following loop parses all tracks and extracts the scenarios

count = 1;
scenario_active = zeros(1,h_layout.no_tx);
for n = 1 : h_layout.no_rx                                	% Do for each Rx
    
    % If we have less scenarios defined than transmitters in the layout
    if size( h_layout.track(1,n).scenario,1 ) == 1 && h_layout.no_tx > 1
        rx_scen = repmat( h_layout.track(1,n).scenario , h_layout.no_tx, 1 );
    else
        rx_scen = h_layout.track(1,n).scenario;
    end
    
    % We only process links where there is an enrty in the pairing matrix
    tx_selection = sort( h_layout.pairing(1, h_layout.pairing(2,:) == n ) );
    
    if isempty( tx_selection )
        warning('QuaDRiGa:qd_layout:init_builder:no_tx',['Receiver "',h_layout.rx_name{n},'" has no transmitter.']');
    end
    
    if h_layout.track(1,n).no_segments == 1    % It the current track has only one segment
        subtrack = copy( h_layout.track(1,n) );   % ... use the track.
        rename_track = false;
        
        % Check, if the initial position is on the track.
        % If it is not, set the initial position to the first snapshot of
        % the track. This is done automatically in "track.get_subtrack".
        if ~any( sum( subtrack.positions == 0 ) == 3 )
            sp = subtrack.positions( :, 1 );
            subtrack.initial_position = subtrack.initial_position + sp;
            for m=1:3
                subtrack.positions(m,:) = subtrack.positions(m,:) - sp(m);
            end
        end
    else                                % ... split the track in subtracks.
        subtrack = get_subtrack( h_layout.track(1,n) );
        rename_track = true;
    end
    
    for m = 1:h_layout.track(1,n).no_segments              % Do for each segment
        if rename_track                             % Set name for subtrack
            subtrack(1,m).name = [h_layout.rx_name{n},'_seg',num2str(m,'%04u')];
        end
        
        pos = zeros(subtrack(1,m).no_snapshots,3);  	% Get all positions from current subtrack
        pos(:,1) = subtrack(1,m).positions(1,:) + subtrack(1,m).initial_position(1);
        pos(:,2) = subtrack(1,m).positions(2,:) + subtrack(1,m).initial_position(2);
        pos(:,3) = subtrack(1,m).positions(3,:) + subtrack(1,m).initial_position(3);
        
        % Each Rx can belong to several scenarios. One for each Tx.
        % o iterates over all tx
        for o = tx_selection
            % Check, if the scenario is already listed
            [ already_there , loc] = ismember( rx_scen(o,m) , scenarios );
            
            if ~already_there
                % If scenario does not exist, create it
                count = count + 1;
                scenarios(count) = rx_scen(o,m);
                position{ count,o }(:,1) = min( pos,[],1 )';
                position{ count,o }(:,2) = max( pos,[],1 )';
                scenario_active( count , o ) = 1;
                tracks{ count,o } = subtrack(1,m);
                rx{ count,o } = h_layout.rx_array( :,n );
                tx{ count,o } = h_layout.tx_array( :,o );
            else
                % Otherwise update position of the existing scenario
                position{ loc,o }(:,1) = min( [ pos ; position{loc,o}' ],[],1 )';
                position{ loc,o }(:,2) = max( [ pos ; position{loc,o}' ],[],1 )';
                scenario_active( loc , o ) = 1;
                if isempty( tracks{ loc,o } )
                    tracks{ loc,o } = subtrack(1,m);
                    rx{ loc,o } = h_layout.rx_array(:,n);
                else
                    tracks{ loc,o }(1,end+1) = subtrack(1,m);
                    rx{ loc,o }(1,end+1) = h_layout.rx_array(:,n);
                end
                tx{ loc,o } = h_layout.tx_array( :,o );
            end
        end
    end
end

% The field names for the given parameters
par_fieldnames = {'ds','kf','pg','asD','asA','esD','esA','xpr','o2i_loss','o2i_d3din'};

% Replace the scenario shortnames with their long form
[ sup_scenarios , file_names ] = qd_builder.supported_scenarios( check_parfiles );

% Add file names to list of supported scenarios
for i_scen = 1:numel( scenarios )
    if numel(scenarios{i_scen}) > 5 && ...
            ~isempty( regexp( scenarios{i_scen}(end-4:end) , '.conf', 'once' ) ) && ...
            regexp( scenarios{i_scen}(end-4:end) , '.conf' ) == 1
        file = dir(scenarios{i_scen});
        if ~isempty(file)
            sup_scenarios{end+1} = scenarios{i_scen};
            file_names{end+1} = [scenarios{i_scen},'.conf'];
        end
    end
end


% Create list of output scenarios
for n = 1:numel(scenarios)
    
    % Replace the scenario shortnames with their long form
    ind = strcmp( scenarios{n} , sup_scenarios );
    try
    scenarios{n} = file_names{ind}(1:end-5);
    catch
        1
    end
    
    for o = 1 : h_layout.no_tx
        
        % When parameters are given in the tracks, we need to sort out, which
        % parameters belong to which transmitter. Hence, we need to split the
        % parameter-structures for different Txs here.
        
        if scenario_active(n,o)
            % Process parameters only when there are more then 2 Txs.
            
            for m = 1 : numel( tracks{n,o} )
                par_tmp = tracks{n,o}(1,m).par;             % Read par-struct
                
                if ~isempty( par_tmp )
                    % Use the row that matches the current tx-number.
                    for p = 1 : numel( par_fieldnames )
                        field_tmp = par_tmp.( par_fieldnames{p} );
                        if size( field_tmp,1 ) > 1
                             par_tmp.( par_fieldnames{p} ) = field_tmp(o,:,:);
                        end
                    end
                    
                    % Copy the track (since subtracks are only handles referring to the same object).
                    tmp_trk = qd_track([]);                 % New track
                    copy( tmp_trk, tracks{n,o}(1,m) );      % Copy data from old track
                    tmp_trk.par_nocheck = par_tmp;          % Assign new par struct
                    tracks{n,o}(1,m) = tmp_trk;             % Assign track
                end
            end
        end
        
        % Create builder boject
        if o == 1
            h_builder(n,o) = qd_builder( scenarios{n} );
        else
            h_builder(n,o) = qd_builder( scenarios{n}, false, h_builder(n,1).scenpar  );
            h_builder(n,o).plpar =  h_builder(n,1).plpar;
        end
        
        % Scenario-names should not contain underscores ('_')
        builder_name = regexprep( scenarios{n} , '_' , '-' );
        h_builder(n,o).name = [builder_name,'_',h_layout.tx_name{o}];
        
        h_builder(n,o).simpar = h_layout.simpar;
        h_builder(n,o).tx_position = h_layout.tx_position(:,o);
        
        if scenario_active(n,o)
            % Insert borders for map creation
            h_builder(n,o).rx_positions = position{n,o};
                     
            h_builder(n,o).rx_track   = tracks{n,o};
            h_builder(n,o).tx_array   = tx{ n,o };
            h_builder(n,o).rx_array   = rx{ n,o };
            
            % Insert segments for parameter generation
            h_builder(n,o).rx_positions = cat( 2 , tracks{n,o}.initial_position );
        end
    end
end

% Fix for octave
if numel( h_builder ) == 1
    h_builder = h_builder(1,1);
end

end
