function file_name = set_scenario_table( h_builder, scenario, check )
%SET_SCENARIO_TABLE Parse conf files and load values into matlab
%
% QuaDRiGa Copyright (C) 2011-2017 Fraunhofer Heinrich Hertz Institute
% e-mail: quadriga@hhi.fraunhofer.de
%
% QuaDRiGa is free software: you can redistribute it and/or modify
% it under the terms of the GNU Lesser General Public License as published
% by the Free Software Foundation, either version 3 of the License, or
% (at your option) any later version.

if numel( h_builder ) > 1
    error('QuaDRiGa:qd_builder:ObjectArray','??? "calc_scatter_positions" is only defined for scalar objects.')
else
    h_builder = h_builder(1,1); % workaround for octave
end

% We can optionally disable the validity check for speedup.
if nargin == 3 && numel( check ) == 1
    check = logical( check );
else
    check = true;
end

if ischar(scenario)
    
    % Get the list of conf-files
    [ sup_scenarios , file_names , file_dirs ] = qd_builder.supported_scenarios(0);
    
    % Parse all shortnames inside the conf-files
    if ~any( logical( strcmp(scenario,sup_scenarios) ) )
        [ sup_scenarios , file_names , file_dirs ] = qd_builder.supported_scenarios(1);
    end
    
    if ~any( logical( strcmp(scenario,sup_scenarios) ) )
        str = ['??? Scenario "',scenario,'" not found; supported are: '];
        no = numel(sup_scenarios);
        for n = 1:no
            str = [str,sup_scenarios{n}];
            if n<no
                str = [str,', '];
            end
        end
        error('QuaDRiGa:qd_builder:WrongInput',str);
    end
    
    % Initialize the structs with some default values
    scen = struct( ...
        'NumClusters' , 6 , ...            % Number of Paths
        'NumSubPaths' , 20 , ...           % Sub-paths per cluster
        'DS_mu' , -6 , ...                 % delay spread, mean [log10(s)]
        'DS_gamma' , 0 , ...               % Freq.-dep. of DS [log10(s)/log10(GHz)]
        'DS_sigma' , 0.5 , ...             % delay spread, std [log10(s)]
        'DS_delta' , 0 , ...               % Freq.-dep. of DS std. [log10(s)/log10(GHz)]
        'DS_lambda' , 20 , ...             % Decorrelation distance [m], delay spread
        'AS_D_mu' ,  1 , ...               % departure azimuth spread, mean [log10(deg)]
        'AS_D_gamma' , 0 , ...             % Freq.-dep. of ASD [log10(deg)/log10(GHz)]
        'AS_D_sigma' , 0.2 , ...           % departure azimuth spread, std [log10(deg)]
        'AS_D_delta' , 0 , ...             % Freq.-dep. of ASD std. [log10(deg)/log10(GHz)]
        'AS_D_lambda' , 20 , ...           % Decorrelation distance [m], departure azimuth spread
        'AS_A_mu' , 1 , ...                % arrival azimuth spread, mean [log10(deg)]
        'AS_A_gamma' , 0 , ...             % Freq.-dep. of ASA [log10(deg)/log10(GHz)]
        'AS_A_sigma' , 0.2 , ...           % arrival azimuth spread, std [log10(deg)]
        'AS_A_delta' , 0 , ...             % Freq.-dep. of ASA std. [log10(deg)/log10(GHz)]
        'AS_A_lambda' , 20 , ...           % Decorrelation distance [m], arrival azimuth spread
        'ES_D_mu' , 0.3 , ...              % departure elevation spread, mean [log10(deg)]
        'ES_D_gamma' , 0 , ...             % Freq.-dep. of ESD [log10(deg)/log10(GHz)]
        'ES_D_mu_A' , 0 , ...              % departure elevation spread distance dependency
        'ES_D_mu_min' , -Inf , ...         % departure elevation spread minimum value
        'ES_D_sigma' , 0.2 , ...           % departure elevation spread, std [log10(deg)]
        'ES_D_delta' , 0 , ...             % Freq.-dep. of ESD std. [log10(deg)/log10(GHz)]
        'ES_D_lambda' , 20 , ...           % Decorrelation distance [m], departure elevation spread
        'ES_A_mu' , 0.3 , ...              % arrival elevation spread, mean [log10(deg)]
        'ES_A_gamma' , 0 , ...             % Freq.-dep. of ESA [log10(deg)/log10(GHz)]
        'ES_A_sigma' , 0.2 , ...           % arrival elevation spread, std [log10(deg)]
        'ES_A_delta' , 0 , ...             % Freq.-dep. of ESA std. [log10(deg)/log10(GHz)]
        'ES_A_lambda' , 20 , ...           % Decorrelation distance [m], arrival elevation spread
        'SF_sigma' , 8 , ...               % shadowing std [dB] (zero mean)
        'SF_delta' , 0 , ...               % Freq.-dep. of SF [dB/log10(GHz)]
        'SF_lambda' , 20 , ...             % Decorrelation distance [m], shadowing
        'KF_mu' , 0 , ...                  % K-factor mean [dB]
        'KF_gamma' , 0 , ...               % Freq.-dep. of KF [dB/log10(GHz)]
        'KF_sigma' , 0 , ...               % K-factor std [dB]
        'KF_delta' , 0 , ...               % Freq.-dep. of KF std. [dB/log10(GHz)]
        'KF_lambda' , 20 , ...             % Decorrelation distance [m], k-factor
        'XPR_mu' , 0 , ...                 % XPR mean [dB]
        'XPR_gamma' , 0 , ...              % Freq.-dep. of XPR [dB/log10(GHz)]
        'XPR_sigma' , 10 , ...             % XPR std [dB]
        'XPR_delta' , 0 , ...              % Freq.-dep. of XPR std. [dB/log10(GHz)]
        'XPR_lambda', 20 , ...             % Decorrelation distance [m], XPR
        'r_DS' , 2 , ...                   % Delays spread proportionality factor
        'PerClusterDS', 0 , ...            % Cluster Delay Spread factor cDS in [ns]
        'PerClusterDS_gamma', 0 , ...      % Freq.-dep. of Cluster DS [ns/log10(GHz)]
        'PerClusterDS_min', 0 , ...        % Minimum Cluster Delay Spread in [ns]
        'PerClusterAS_D' , 0 , ...         % Per cluster BS azimuth spread [deg]
        'PerClusterAS_A' , 0 , ...         % Per cluster MS azimuth spread [deg]
        'PerClusterES_D' , 0 , ...         % Per cluster BS elevation spread [deg]
        'PerClusterES_A' , 0 , ...         % Per cluster MS elevation spread [deg]
        'SubpathMethod', 'legacy', ...     % Subpath-generation method
        'LOS_scatter_radius', 0, ...       % Scattering around the LOS cluster
        'SC_lambda', 0 ,...                % Decorrelation distance [m] for spatial consistency
        'LNS_ksi' , 3 , ...                % ZDSC LNS ksi [dB], per cluster shadowing
        'GR_enabled' , 0 , ...             % Enable (1) or disable (0) Ground Reflection
        'GR_epsilon' , 0 , ...             % Manual value for the relative permittivity, 0 = auto
        'asD_ds' , 0 , ...                 % departure AS vs delay spread
        'asA_ds' , 0 , ...                 % arrival AS vs delay spread
        'asA_sf' , 0 , ...                 % arrival AS vs shadowing std
        'asD_sf' , 0 , ...                 % departure AS vs shadowing std
        'ds_sf' , 0 , ...                  % delay spread vs shadowing std
        'asD_asA' , 0 , ...                % departure AS vs arrival AS
        'asD_kf' , 0 , ...                 % departure AS vs k-factor
        'asA_kf' , 0 , ...                 % arrival AS vs k-factor
        'ds_kf' , 0 , ...                  % delay spread vs k-factor
        'sf_kf' , 0 , ...                  % shadowing std vs k-factor
        'esD_ds' , 0 , ...                 % departure ES vs delay spread
        'esA_ds' , 0 , ...                 % arrival ES vs delay spread
        'esA_sf' , 0 , ...                 % arrival ES vs shadowing std
        'esD_sf' , 0 , ...                 % departure ES vs shadowing std
        'esD_esA' , 0 , ...                % departure ES vs arrival ES
        'esD_asD' , 0 , ...                % departure ES vs departure AS
        'esD_asA' , 0 , ...                % departure ES vs arrival AS
        'esA_asD' , 0 , ...                % arrival ES vs departure AS
        'esA_asA' , 0 , ...                % arrival ES vs arrival AS
        'esD_kf' , 0 , ...                 % departure ES vs k-factor
        'esA_kf' , 0 );                    % arrival ES vs k-factor
    
    names = fieldnames(scen);
    
    % Open config file for reading the parameters
    ind = find( strcmp( scenario , sup_scenarios ),1 );
    file_name = file_names{ind};
    file_dir  = file_dirs{ind};
    
    file = fopen([ file_dir , file_name ],'r');
    
    % Read file line by line and parse the data of scenpar
    lin = fgetl(file);
    while ischar(lin)
        
        p1 = regexp(lin,'=');                           % Check if there is an equal sign
        if ~isempty(p1)                                 % If there is a "=" sign
            p2 = regexp(lin(1:p1(1)-1),'%', 'once');    % Check if the line is commented
            if isempty(p2)                              % If the line is not commented
                name = regexp( lin(1:p1(1)-1) ,'[A-Za-z0-9_]+','match');           % Read name
                if ~isempty(name)                       % If there is a name
                    
                    % Here we have two options. Either the current parameter is
                    % for "scenpar" or for "plpar". Parameters for the
                    % path-loss model start with "PL_". We check first, if the
                    % current line is a PL-parameter.
                    
                    p0 = regexp(name{1},'PL_', 'once');
                    if isempty(p0)                      % If it is not a plpar
                        ind = strcmp(name,names);       % Get the index in the parameter list
                        if any(ind)                     % If the index exists
                            tmp = lin(p1(1)+1:end);     % Copy line
                            p2 = regexp(tmp,'%');       % Check for comment
                            if ~isempty( p2 )
                                tmp = tmp(1:p2(1)-1 );      % Remove commented part
                            end
                            p3 = regexp( tmp,'[0-9.-]+','match');         % Check for numbers
                            if ~isempty( p3 )
                                p3 = regexp( tmp,'[0-9Eej.-]+','match'); % Include exponenetials and comlex numbers
                                scen.( names{ind} ) = str2double( p3{1} );
                            else
                                p3 = regexp( tmp,'[A-Za-z]+' ,'match');   % Check for strings
                                if ~isempty( p3 )
                                    scen.( names{ind} ) = p3{1};
                                else
                                    error('QuaDRiGa:qd_builder:WrongInput',...
                                        ['Could not understand value of "',name{1},'" in file "',scenario,'.conf"']);
                                end
                            end
                        end
                    else
                        PLname = name{1}(4:end);        % Parse the name of the field in PLPAR
                        if strcmp(PLname,'model')       % If it is the model name
                            p3 = regexp( lin(p1(1)+1:end)  ,'[A-Za-z0-9_]+','match');
                            if isempty( p3 )            % If no value is given or wrongly formatted
                                error('QuaDRiGa:qd_builder:WrongInput',...
                                    ['Could not understand value of "',name{1},'" in file "',scenario,'.conf"']);
                            else
                                Lpl.model = p3{1};      % Set the model name
                            end
                        else
                            p4 = regexp( lin, '%' );    % Determine the beginning of the comment
                            if isempty( p4 )            % If there is no comment
                                p4 = numel(lin);        % Set the position to endline
                            end
                            p3 = regexp( lin(p1(1)+1:p4)  ,'[0-9e.-]+','match');
                            Lpl.( PLname ) = str2double(p3);
                        end
                    end
                end
            end
        end
        lin = fgetl(file);          % Get next line
    end
    fclose(file);
    
    % If we have a PLPAR, write it to data object
    if exist('Lpl','var')
        h_builder.plpar = Lpl;
    else
        h_builder.plpar = [];
    end
    
    % Check the scenpar and determine the LSP correlation matrix
    check_scenario_parameter_table( scen , check );
    
    h_builder.Pscenpar = scen;
    h_builder.Pscenario = scenario;
    
elseif isstruct( scenario )
    check_scenario_parameter_table( scenario , check );
    if ~isempty( h_builder.scenpar )
        h_builder.data_valid = h_builder.data_valid && check_if_map_is_valid( h_builder.scenpar , scenario );
    end
    h_builder.Pscenario = 'Custom';
    h_builder.Pscenpar = scenario;
    
else
    error('QuaDRiGa:qd_builder:WrongInput','Scenpar has wrong format');
end

end
