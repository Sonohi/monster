classdef AntennaElement < handle
    % Implementation of single antenna element pr.  pr. ITU M.2412/3GPP 38.901
    % Copyright Jakob Thrane/DTU 2018
    % 
    properties
        tilt; % tilt angle
        theta3db; % vertical 3 dB beamwidth 
        phi3db; % horizontal 3 dB beamwidth 
        SLAv;  % maximum side lobe level attenuation
        Amax; % maximum side lobe level attenuation
    end
    
    methods
        function obj = AntennaElement(tilt, scenario)
            % Construct single antenna element pr. ITU M.2412/3GPP 38.901
            %
            % TRxP BS antenna radiation pattern given by table 9 in ITU
            % M.2412
            %
            % Indoor BS antenna radiation pattern given by table 10 in ITU
            % M.2412
            obj.tilt = tilt;
            switch scenario
                case 'indoor'
                    obj.setIndoorConfigITU();
                otherwise
                    obj.setOutdoorConfig3GPP();
            end
            
        end
        
        function plotPattern(obj)
            % Plot of radiation pattern
            theta_h = 0:180;
            phi_h = -180:1:180;
            A3 = obj.get3DGain(theta_h,phi_h);
            patternCustom(A3',theta_h,phi_h);
        end
        
        function gain = get3DGain(obj, theta, phi)
            % Compute 3D radiation pattern given vertical and horizontal
            % Defined as $A(\theta,\phi) = - \min \{-\left[A_V(\theta) + A_H(\phi)\right], SLA\}$
            % Outputs matrix of size len(theta) x len(phi)
            gain = zeros(length(theta),length(phi));
            for itheta = 1:length(theta)
                for iphi = 1:length(phi)
                    gain(itheta, iphi) = -1*(min([-1*(obj.Avertical(theta(itheta))+obj.Ahorizontal(phi(iphi))),obj.Amax]));
                end
            end

        end
        
    end
    
    methods (Access = private)
        function obj = setOutdoorConfig3GPP(obj)
            % Corresponds to parameters in table 9
            obj.theta3db = 65; %Degrees
            obj.phi3db = 65; %Degrees
            obj.Amax = 30; %dB
            obj.SLAv = 30; %dB
        end
        
        function obj = setIndoorConfigITU(obj)
            % Corresponds to parameters in table 10
            obj.theta3db = 90; %Degrees
            obj.phi3db = 90; %Degrees
            obj.Amax = 25; %dB
            obj.SLAv = 25; %dB
        end
        
        function Av = Avertical(obj,theta)
            % Compute vertical radiation pattern
						if theta < 0 || theta > 180
							sonohilog('Theta is out of range [0:180]','ERR')
						end
						
            Av = -1*(min([12*((theta-(obj.tilt))/obj.theta3db).^2,obj.SLAv]));
        end
        
        function Ah = Ahorizontal(obj,phi)
            % Compute horizontal radiation pattern
						if phi < -180 || phi > 180
							sonohilog('Phi is out of range [-180:180]','ERR')
						end
            Ah = -1*(min([12*(phi/obj.phi3db).^2,obj.Amax]));
        end
        
        
    end
    
    
    
end