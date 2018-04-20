classdef ChBulk_v2 < SonohiChannel
	% This is the main API class for interfacing with implemented models.
	methods

		function obj = ChBulk_v2(Param)
			% See :class:`SonohiChannel` for the structure of :attr:`Param`
			obj = obj@SonohiChannel(Param);
		end
		
		
		function [Stations,Users,obj] = traverse(obj,Stations,Users,chtype,varargin)
			% This method applies the channel properties to the receiver modules. The recieved waveform and meaningful physical parameters are written to the receiver module depending on the channel type selected. Two options exist. 
			% 
			% .. warning:: 'uplink' is currently only available in B2B mode.
			% :param str chtype: the receptive Rx module is configured using 'downlink' or 'uplink', if 'downlink' Users.Rx modules are used to store the final waveforms and physical parameters.
			if ~strcmp(chtype,'downlink') && ~strcmp(chtype,'uplink')
				sonohilog('Unknown channel type selected.','ERR')
			end

			if isempty(varargin)
				obj.fieldType = 'full';
			else
				vargs = varargin;
				nVargs = length(vargs);
				
				for k = 1:nVargs
					if strcmp(vargs{k},'field')
						obj.fieldType = vargs{k+1};
					end
				end
			end
			
			if isempty(obj.DownlinkModel) && strcmp(chtype,'downlink')
				sonohilog('Hey, no downlink channel is setup. Please run Channel.setup.','ERR')
			end
			
			if isempty(obj.UplinkModel) && strcmp(chtype,'uplink')
				sonohilog('Hey, no uplink channel is setup. Please run Channel.setup.','ERR')
			end
			
			
			[stations,users] = obj.getAssociated(Stations,Users);
			
			
			if ~isempty(stations)
				[Users,obj] = obj.runModel(Stations,Users, chtype);
			else
				sonohilog('No users found for any of the stations. Is this supposed to happen?','WRN')
			end
			
		end

		function obj = resetChannelModels(obj)
            % Resets any channel setup
            obj.DownlinkModel = [];
            obj.UplinkModel = [];
        end
        
        function obj = setupChannelDL(obj,Stations,Users)
            % Setup channel given the DL schedule, e.g. the association to simulate when traversed.
            [stations, users] = obj.getAssociated(Stations, Users);
            obj.DownlinkModel = obj.setupChannel(stations,users,'downlink');
        end
        
        function obj = setupChannelUL(obj, Stations, Users,varargin)
            % Setup channel given the DL schedule, e.g. the association to simulate when traversed.
             if ~isempty(varargin)
                vargs = varargin;
                nVargs = length(vargs);
                
                for k = 1:nVargs
                    if strcmp(vargs{k},'compoundWaveform')
                        compoundWaveform = vargs{k+1};
                    end
                end
            end
            [stations, users] = obj.getAssociated(Stations, Users);
            obj.UplinkModel = obj.setupChannel(stations,users,'uplink');
            obj.UplinkModel.CompoundWaveform = compoundWaveform;
        end
        
                    
        function chModel = setupChannel(obj,Stations,Users,chtype)
            % Setup association to traverse
            switch chtype
                case 'downlink'
                    mode = obj.DLMode;
                case 'uplink'
                    mode = obj.ULMode;
            end
            
            if strcmp(mode,'winner')
                WINNER = sonohiWINNERv2(Stations,Users, obj,chtype);
                chModel = WINNER.setup();
            elseif strcmp(mode,'eHATA')
                chModel = sonohieHATA(obj, chtype);
            elseif strcmp(mode,'ITU1546')
                chModel = sonohiITU(obj, chtype);
            elseif strcmp(mode, 'B2B')
                chModel = sonohiB2B(obj, chtype);
            else
                sonohilog(sprintf('Channel mode: %s not supported. Choose [eHATA, ITU1546, winner]',mode),'ERR')
            end
            
            
            
        end
		
	
		
	end
end
