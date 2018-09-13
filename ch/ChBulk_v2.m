classdef ChBulk_v2 < SonohiChannel
	% This is the main API class for interfacing with implemented models.
	methods
		
		function obj = ChBulk_v2(Stations, Users, Param)
			% See :class:`SonohiChannel` for the structure of :attr:`Param`
			obj = obj@SonohiChannel(Stations, Users, Param);
		end
		
		
		function [Stations,Users,obj] = traverse(obj,Stations,Users,chtype,varargin)
			% This method applies the channel properties to the receiver modules. The recieved waveform and meaningful physical parameters are written to the receiver module depending on the channel type selected. Two options exist.
			%
			% :param Stations: Station objects with a transmitter and receiver module.
			% :type Stations: :class:`enb.EvolvedNodeB`
			% :param Users: UE objects with a transmitter and receiver module
			% :type Users: :class:`ue.UserEquipment`
			% :param str chtype: the receptive Rx module is configured using 'downlink' or 'uplink', if 'downlink' Users.Rx modules are used to store the final waveforms and physical parameters.
			% :param varargin: ('fieldType','field') can be given to bypass fading and interference, 'full is default'
			%
			% :attr:`Stations` needs the following fields:
			%  * :attr:`Stations.Users`: needed for getting link association between stations and users
			%  * :attr:`Stations.NCellID`: Identifier to link association
			%  * :attr:`Stations.Tx`: Transmitter module
			%  * :attr:`Stations.Rx`: Receiver module
			% :attr:`Users` needs the following fields:
			%  1. :attr:`Users.NCellID`: Identifier to link association
			%  2. :attr:`Users.ENodeBID`: Identifier to link association
			%  3. :attr:`Users.Tx`: Transmitter module
			%  4. :attr:`Users.Rx`: Receiver module
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
				sonohilog('Hey, no downlink channel is defined.','ERR')
			end
			
			if isempty(obj.UplinkModel) && strcmp(chtype,'uplink')
				sonohilog('Hey, no uplink channel is defined.','ERR')
			end
			
			
			[stations,users] = obj.getAssociated(Stations,Users);
			
			
			if ~isempty(stations)
				[stations,users,obj] = obj.runModel(stations,users, chtype);
				% Overwrite in input struct
				for iUser = 1:length(users)
					ueId = users(iUser).NCellID;
					Users([Users.NCellID] == ueId) = users(iUser);
				end
				for iStations = 1:length(stations)
					enbId = stations(iStations).NCellID;
					Stations([Stations.NCellID] == enbId) = stations(iStations);
				end
				
			else
				sonohilog('No users found for any of the stations. Is this supposed to happen?','WRN')
			end
			
		end
		
		function obj = setupChannelUL(obj, Stations, Users,varargin)
			% Setup channel given the UL schedule, e.g. the association to simulate when traversed.
			%
			% :param Stations:
			% :type Stations: :class:`enb.EvolvedNodeB`
			% :param Users:
			% :type Users: :class:`ue.UserEquipment`
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
			obj.UplinkModel.CompoundWaveform = compoundWaveform;
		end
		
		
		
		
		
	end
end
