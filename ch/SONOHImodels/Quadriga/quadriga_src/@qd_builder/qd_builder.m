classdef qd_builder < handle
    %QD_BUILDER Class for generating the channel coefficients and the model pareters
    
    properties
        name = '';                  % Name of the parameter set object
    end
    
    properties(Dependent)
        scenario                    % The name of the scenario (text string)
        scenpar                     % The parameter table
    end
    
    properties
        plpar = [];                 % Parameters for the path loss (scenario-dependent)
        
        simpar = qd_simulation_parameters;      % Object of class qd_simulation_parameters
        tx_array = qd_arrayant([]);             % Handles of qd_arrayant objects for each Tx
        rx_array = qd_arrayant([]);             % Handles of qd_arrayant objects for each Rx
        rx_track = qd_track([]);                % Handles of Track objects for each Rx
        sos = [];                               % The seven large-scale parameter SOS generators
        
        % The transmitter position obtained from the corresponding 'layout.tx_position'
        tx_position = [0;0;0];
        
        % The list of initial positions for which LSPs are generated
        %   This variable is obtained from 'track.initial_position' and 'layout.rx_position'
        rx_positions = [];
        
        ds = [];                    % The RMS delay spread in [s] for each receiver position
        kf = [];                    % The Rician K-Factor [linear scale] for each receiver position
        sf = [];                    % The shadow fading [linear scale] for each receiver position
        asD = [];                   % The azimuth spread of departure in [deg] for each receiver position
        asA = [];                   % The azimuth spread of arrival in [deg] for each receiver position
        esD = [];                   % The elevation spread of departure in [deg] for each receiver position
        esA = [];                   % The elevation spread of arrival in [deg] for each receiver position
        xpr  = [];                  % The cross polarization ratio [linear scale] for each receiver position
        
        NumClusters                 % The number of clusters. 
        NumSubPaths                 % The number of sub-paths per cluster 
        
        % The initial delays for each path in [s]. Rows correspond to the
        % MTs, columns to the paths. 
        taus
        
        % The normalized initial power (squared average amplitude) for each
        % path. Rows correspond to the MT, columns to the paths. The sum
        % over all columns must be 1.   
        pow
        
        AoD                         % The initial azimuth of departure angles for each path in [rad].
        AoA                         % The initial azimuth of arrival angles for each path in [rad].
        EoD                         % The initial elevation of departure angles for each path in [rad].
        EoA                         % The initial elevation of departure angles for each path in [rad].
        
        % The initial cross polarization power ratio in [dB] for each
        % sub-path. The dimensions correspond to the MT, the path number,
        % and the sub-path number.   
        xpr_path
        
        pin                   	% The initial phases in [rad] for each sub-path.
        
        % The phase offset angle for the circular XPR in [rad]. The
        % dimensions correspond to the MT, the path number, and the
        % sub-path number.   
        kappa
        
        % Random phasors for the WINNER polarization coupling method.
        % The dimensions correspond to polarization matrix index
        % '[ 1 3 ; 2 4 ]}', the subpath number and the MT.
        random_pol            	% Random Polarization matrix
        
        % The relative permittivity for the ground reflection
        gr_epsilon_r
        
        % A random index list for the mutual coupling of subpaths at the Tx
        % and Rx. The dimensions correspond to the subpath index (1-20),
        % the angle (AoD, AoA, EoD, EoA), the path number and the MT.
        subpath_coupling
        
        data_valid = false;         % Indicates if the data is valid
    end
    
    properties(Dependent,SetAccess=protected)
        map_valid                   % Indicates if the SOS objects have been correctly initialized
        
        % Number of receiver positions associated to this 'parameter_set' object
        %   Note that each segment in longer tracks is considered a new Rx
        %   position.
        no_rx_positions
        
        lsp_vals                    % The distribution values of the LSPs
        lsp_xcorr_chk               % Indicator if cross-correlation matrix is positive definite
    end
    
    properties(Dependent)
        lsp_xcorr                   % The cross-correlation matrix for the LSPs
    end
    
    properties(Dependent,Hidden)
        scenpar_nocheck
    end
    
    % Data storage
    properties(Access=private)
        Pscenario               = '';
        Pscenpar                = [];
        pow_wo_kf
    end
    
    properties(Hidden)
        OctEq = false; % For qf.eq_octave
    end
    
    methods
        
        % Constructor
        function h_builder = qd_builder( scenario, check_parfiles, scenpar )
            if exist( 'scenpar' , 'var' ) && ~isempty( scenpar )
                % If scenpar is give, we skip all checks, assuming that the values are correct
                h_builder.Pscenario = scenario;
                h_builder.Pscenpar = scenpar;
            else
                % I scenar par is not given, we check the scenario name
                if exist( 'scenario' , 'var' ) && ~isempty( scenario )
                    if exist( 'check_parfiles' , 'var' )
                        if ~( all(size(check_parfiles) == [1 1]) ...
                                && (isnumeric(check_parfiles) || islogical(check_parfiles)) ...
                                && any( check_parfiles == [0 1] ) )
                            error('QuaDRiGa:qd_builder:WrongInput','??? "check_parfiles" must be 0 or 1')
                        end
                    else
                        check_parfiles = true;
                    end
                    set_scenario_table( h_builder, scenario, check_parfiles );
                end
            end
            h_builder.simpar = qd_simulation_parameters;
            h_builder.rx_track = qd_track([]);
            h_builder.tx_array = qd_arrayant([]);
            h_builder.rx_array = qd_arrayant([]);
        end
        
        % Get functions
        function out = get.scenario(h_builder)
            out = h_builder.Pscenario;
        end
        function out = get.scenpar(h_builder)
            out = h_builder.Pscenpar;
        end
        function out = get.scenpar_nocheck(h_builder)
            out = h_builder.Pscenpar;
        end
        function out = get.map_valid(h_builder)
            out = ~isempty( h_builder.sos ) & isa(h_builder.sos, 'qd_sos') & numel( h_builder.sos ) == 8;
        end
        function out = get.no_rx_positions(h_builder)
            out = size( h_builder.rx_positions,2 );
        end
        function out = get.lsp_vals(h_builder)
            if isempty( h_builder.Pscenpar )
                out = [];
            else
                % Carrier frequency in GHz
                f_GHz = h_builder.simpar.center_frequency / 1e9;
                oF = ones( 1,numel( f_GHz ));
                
                % Get the average LSPs
                mu = [ h_builder.scenpar.DS_mu; h_builder.scenpar.KF_mu; 0; h_builder.scenpar.AS_D_mu; h_builder.scenpar.AS_A_mu;...
                    h_builder.scenpar.ES_D_mu; h_builder.scenpar.ES_A_mu; h_builder.scenpar.XPR_mu ];
                gamma = [ h_builder.scenpar.DS_gamma;h_builder.scenpar.KF_gamma;0; h_builder.scenpar.AS_D_gamma; ...
                    h_builder.scenpar.AS_A_gamma ;h_builder.scenpar.ES_D_gamma ;h_builder.scenpar.ES_A_gamma; h_builder.scenpar.XPR_gamma];
                mu = mu( :,oF ) + gamma * log10( f_GHz );
               
                % Get the std. of the LSPs
                sigma = [ h_builder.scenpar.DS_sigma;h_builder.scenpar.KF_sigma;h_builder.scenpar.SF_sigma; h_builder.scenpar.AS_D_sigma;...
                    h_builder.scenpar.AS_A_sigma;h_builder.scenpar.ES_D_sigma;h_builder.scenpar.ES_A_sigma; h_builder.scenpar.XPR_sigma ];
                delta = [ h_builder.scenpar.DS_delta;h_builder.scenpar.KF_delta;h_builder.scenpar.SF_delta; h_builder.scenpar.AS_D_delta;...
                    h_builder.scenpar.AS_A_delta;h_builder.scenpar.ES_D_delta;h_builder.scenpar.ES_A_delta; h_builder.scenpar.XPR_delta];
                sigma = sigma( :,oF ) + delta * log10( f_GHz );
                sigma( sigma<0 ) = 0;
                
                % Let the decorr dist
                lambda = [ h_builder.scenpar.DS_lambda;h_builder.scenpar.KF_lambda;h_builder.scenpar.SF_lambda;...
                    h_builder.scenpar.AS_D_lambda;h_builder.scenpar.AS_A_lambda;h_builder.scenpar.ES_D_lambda;...
                    h_builder.scenpar.ES_A_lambda; h_builder.scenpar.XPR_lambda];
                lambda = lambda( :,oF );
                
                % Assemble output
                out = [mu(:),sigma(:),lambda(:)];
                out = permute( reshape( out, [],numel( f_GHz ),3 ),[1,3,2] );
            end
        end
        function out = get.lsp_xcorr(h_builder)
            if isempty( h_builder.Pscenpar )
                out = [];
            else
                value = h_builder.Pscenpar;
                a = value.ds_kf;          % delay spread vs k-factor
                b = value.ds_sf;          % delay spread vs shadowing std
                c = value.asD_ds;         % departure AS vs delay spread
                d = value.asA_ds;         % arrival AS vs delay spread
                e = value.esD_ds;         % departure ES vs delay spread
                f = value.esA_ds;         % arrival ES vs delay spread
                g = value.sf_kf;          % shadowing std vs k-factor
                h = value.asD_kf;         % departure AS vs k-factor
                k = value.asA_kf;         % arrival AS vs k-factor
                l = value.esD_kf;         % departure DS vs k-factor
                m = value.esA_kf;         % arrival DS vs k-factor
                n = value.asD_sf;         % departure AS vs shadowing std
                o = value.asA_sf;         % arrival AS vs shadowing std
                p = value.esD_sf;         % departure ES vs shadowing std
                q = value.esA_sf;         % arrival ES vs shadowing std
                r = value.asD_asA;        % departure AS vs arrival AS
                s = value.esD_asD;        % departure ES vs departure AS
                t = value.esA_asD;        % arrival ES vs departure AS
                u = value.esD_asA;        % departure ES vs arrival AS
                v = value.esA_asA;        % arrival ES vs arrival AS
                w = value.esD_esA;        % departure ES vs arrival ES
                out = [ 1  a  b  c  d  e  f 0;...
                    a  1  g  h  k  l  m 0;...
                    b  g  1  n  o  p  q 0;...
                    c  h  n  1  r  s  t 0;...
                    d  k  o  r  1  u  v 0;...
                    e  l  p  s  u  1  w 0;...
                    f  m  q  t  v  w  1 0;...
                    0  0  0  0  0  0  0 1];
            end
        end
        function out = get.lsp_xcorr_chk(h_builder)
            out = false;
            if ~isempty( h_builder.Pscenpar )
                [~,p] = chol( h_builder.lsp_xcorr, 'lower');
                if p <= 0
                    out = true;
                end
            end
        end
        
        % Set functions
        function set.scenario(h_builder,value)
            if ~( ischar(value) )
                error('QuaDRiGa:qd_builder:WrongInput','??? "scenario" must be a string.')
            end
            set_scenario_table( h_builder, value);
            h_builder.data_valid = false;
        end
        
        function set.scenpar(h_builder,value)
            if ~( isstruct(value) )
                error('QuaDRiGa:qd_builder:WrongInput','??? "scenpar" must be a structure.')
            end
            set_scenario_table( h_builder, value );
        end
        
        function set.scenpar_nocheck(h_builder,value)
            % Faster when we know that "scenpar" is correct
            h_builder.Pscenpar = value;
        end
        
        function set.lsp_xcorr(h_builder,value)
            if size( value ) ~= [8,8]
                error('QuaDRiGa:qd_builder:WrongInput','??? "lsp_xcorr" must be a 8x8 matrix.')
            end
            sp = h_builder.Pscenpar;
            sp.ds_kf = value( 1,2 ) ;
            sp.ds_sf = value( 1,3 ) ;
            sp.asD_ds = value( 1,4 ) ;
            sp.asA_ds = value( 1,5 ) ;
            sp.esD_ds = value( 1,6 ) ;
            sp.esA_ds = value( 1,7 ) ;
            sp.sf_kf = value( 2,3 ) ;
            sp.asD_kf = value( 2,4 ) ;
            sp.asA_kf = value( 2,5 ) ;
            sp.esD_kf = value( 2,6 ) ;
            sp.esA_kf = value( 2,7 ) ;
            sp.asD_sf = value( 3,4 ) ;
            sp.asA_sf = value( 3,5 ) ;
            sp.esD_sf = value( 3,6 ) ;
            sp.esA_sf = value( 3,7 ) ;
            sp.asD_asA = value( 4,5 ) ;
            sp.esD_asD = value( 4,6 ) ;
            sp.esA_asD = value( 4,7 ) ;
            sp.esD_asA = value( 5,6 ) ;
            sp.esA_asA = value( 5,7 ) ;
            sp.esD_esA = value( 6,7 ) ;
            h_builder.Pscenpar = sp;
        end
    end
    
    methods(Static)
        [ scenarios , config_folder , file_names ] = supported_scenarios( parse_shortnames )
    end
end
