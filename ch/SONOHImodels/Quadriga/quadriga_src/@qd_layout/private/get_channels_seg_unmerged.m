function  chan = get_channels_seg_unmerged( h_cb, is, ip )
%GET_CHANELS_SEG_UNMERGES Extracts a single chanel segment from a builder object
%
% Input:
%   is      MT number
%   ip      Linear builder index

% Linear indexing is broken in Octave
sic = size( h_cb );
[ i1,i2 ] = qf.qind2sub( sic, ip );

% Create temporary builder object for the current channel
h_builder               = qd_builder;
h_builder.name          = h_cb( i1,i2 ).name;
h_builder.scenpar       = h_cb( i1,i2 ).scenpar;
h_builder.plpar         = h_cb( i1,i2 ).plpar;

h_builder.simpar        = h_cb( i1,i2 ).simpar;
h_builder.tx_array      = h_cb( i1,i2 ).tx_array;
h_builder.rx_array      = h_cb( i1,i2 ).rx_array( is );
h_builder.rx_track      = h_cb( i1,i2 ).rx_track( is );
h_builder.sos           = h_cb( i1,i2 ).sos;

h_builder.tx_position   = h_cb( i1,i2 ).tx_position;
h_builder.rx_positions  = h_cb( i1,i2 ).rx_positions(:,is);

h_builder.ds            = h_cb( i1,i2 ).ds( is );
h_builder.kf            = h_cb( i1,i2 ).kf( is );
h_builder.sf            = h_cb( i1,i2 ).sf( is );
h_builder.asD           = h_cb( i1,i2 ).asD( is );
h_builder.asA           = h_cb( i1,i2 ).asA( is );
h_builder.esD           = h_cb( i1,i2 ).esD( is );
h_builder.esA           = h_cb( i1,i2 ).esA( is );
h_builder.xpr           = h_cb( i1,i2 ).xpr( is );

h_builder.NumClusters   = h_cb( i1,i2 ).NumClusters;
h_builder.NumSubPaths   = h_cb( i1,i2 ).NumSubPaths;

h_builder.taus          = h_cb( i1,i2 ).taus( is,: );
h_builder.pow           = h_cb( i1,i2 ).pow( is,: );
h_builder.AoD           = h_cb( i1,i2 ).AoD( is,: );
h_builder.AoA           = h_cb( i1,i2 ).AoA( is,: );
h_builder.EoD           = h_cb( i1,i2 ).EoD( is,: );
h_builder.EoA           = h_cb( i1,i2 ).EoA( is,: );
h_builder.xpr_path      = h_cb( i1,i2 ).xpr_path( is,: );
h_builder.pin           = h_cb( i1,i2 ).pin( is,: );

if ~isempty( h_cb( i1,i2 ).kappa )
    h_builder.kappa         = h_cb( i1,i2 ).kappa( is,: );
end

if ~isempty( h_cb( i1,i2 ).random_pol )
    h_builder.random_pol    = h_cb( i1,i2 ).random_pol( is,:,: );
end

h_builder.subpath_coupling = h_cb( i1,i2 ).subpath_coupling( is,:,: );
h_builder.data_valid    = true;

if ~isempty( h_cb( i1,i2 ).gr_epsilon_r ) 
    h_builder.gr_epsilon_r = h_cb( i1,i2 ).gr_epsilon_r( is );
end

chan = h_builder.get_channels;

end
