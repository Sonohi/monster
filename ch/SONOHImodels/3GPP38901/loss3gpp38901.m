function lossdB = loss3gpp38901(Scenario, d_2d, d_3d, f_c, h_bs, h_ut, h, W, LOS)
% http://www.etsi.org/deliver/etsi_tr/138900_138999/138901/14.03.00_60/tr_138901v140300p.pdf
% V1 - implemeted base RMa, UMa, and UMi 
%
% by Jakob Thrane, DTU Fotonik, 2018
%
% Scenario =
% RMa - Rural macro
% UMa - Urban macro
% UMi - Urban micro

% d_2d = 2d distance in meters
% d_3d = 3d_distance in meters
% f_c = carrier frequency in GHz
% h_bs = height of tx in meters
% h_ut = height of rx in meters
% h = average height of buildings
% W = average width of roads
% LOS = LOS or not.
% shadowing = boolean for deciding if shadowing should be included.
% base seed for shadowing

c = physconst('LightSpeed');
d_bp = 4*h_bs*h_ut*(f_c*10e9)/c;
%% Scenario RMa
switch Scenario
	case 'RMa'
		%%
		if (h < 5) || (h > 50)
			error('Average building height not within range [5m, 50m]')
		end
		
		if (W < 5) || (W > 50)
			error('Average street width not within range [5m, 50m]')
		end
		
		if (h_bs < 10) || (h_bs > 150)
			error('Base station height not within range [5m, 150m]')
		end
		
		if (h_ut < 1) || (h_ut > 10)
			error('UE height not within range [1m, 10m]')
		end
		
		PL1 = 20*log10(40*pi*d_3d*f_c/3)+min(0.03*h^(1.72),10)*log10(d_3d)-min(0.044*h^(1.72),14.77) + 0.002*log10(h)*d_3d;
		
		if (10 <= d_2d) && (d_2d <= d_bp)
			PL_RMA_LOS = PL1;
		elseif (d_bp <= d_2d) && (d_2d <= 10000)
			PL2 = PL1+40*log10(d_3d/d_bp);
			PL_RMA_LOS = PL2;
		else
			error('2D distance not within ranges of [10m, %i m] or [%i m, 10km]',floor(d_bp))
		end
		
		% NLOS
		if LOS
			std_sf_vals = [4, 6];
			std_sf = std_sf_vals(randi([1, 2], 1));
			lossdB = PL_RMA_LOS;
		else
			std_sf = 8;
			if (10 <= d_2d) && (d_2d <= 5000)
				PL_RMA_NLOS = 161.04-7.1*log10(W) + 7.5*log10(h)-(24.37-3.7*(h/h_bs)^2)*log10(h_bs)+(43.42-3.1*log10(h_bs))*(log10(d_3d)-3)+20*log10(f_c)-(3.2*(log10(11.75*h_ut))^2-4.97);
				lossdB = max(PL_RMA_LOS, PL_RMA_NLOS);
			end
		end
		
		
		
	case 'UMa'
		%%
		if (h_ut < 1.5) || (h_ut > 22.5)
			error('UE height not within range [1.5m, 22.5m]')
		end
		
		
		PL1 = 28+22*log10(d_3d) + 20*log10(f_c);
		
		if (10 <= d_2d) && (d_2d <= d_bp)
			PL_UMA_LOS = PL1;
		elseif (d_bp <= d_2d) && (d_2d <= 5000)
			PL2 = 28+40*log10(d_3d) + 20*log10(f_c)-9*log10((d_bp)^2+(h_bs-h_ut)^2);
			PL_UMA_LOS = PL2;
		else
			error('2D distance not within ranges of [10m, %i m] or [%i m, 5km]',floor(d_bp))
		end
		
		
		if LOS
			std_sf = 4;
			lossdB = PL_UMA_LOS;
		else
			std_sf = 6;
			if (10 <= d_2d) && (d_2d <= 5000)
				PL_UMA_NLOS = 13.54+39.08*log10(d_3d) + 20*log10(f_c) - 0.6*(h_ut-1.5);
				lossdB = max(PL_UMA_LOS, PL_UMA_NLOS);
			else
				error('2D distance not within ranges of [10m, 5km]')
			end
		end
		
		
	case 'UMi'
		%%
		if (h_ut < 1.5) || (h_ut > 22.5)
			error('UE height not within range [1.5m, 22.5m]')
		end
		
		
		PL1 = 32.4 + 21*log10(d_3d)+20*log10(f_c);
		
		if (10 <= d_2d) && (d_2d <= d_bp)
			PL_UMI_LOS = PL1;
		elseif (d_bp <= d_2d) && (d_2d <= 5000)
			PL2 = 32.4+40*log10(d_3d)+20*log10(f_c)-9.5*log10((d_bp)^2+(h_bs-h_ut)^2);
			PL_UMI_LOS = PL2;
		else
			error('2D distance not within ranges of [10m, %i m] or [%i m, 5km]',floor(d_bp))
		end
		
		if LOS
			std_sf = 4;
			lossdB = PL_UMI_LOS;
		else
			std_sf = 7.82;
			if (10 <= d_2d) && (d_2d <= 5000)
				PL_UMI_NLOS = 35.3*log10(d_3d) + 22.4 + 21.3*log10(f_c) - 0.3*(h_ut -1.5);
				lossdB = max(PL_UMI_LOS, PL_UMI_NLOS);
			else
				error('2D distance not within ranges of [10m, 5km]')
			end
		end
	otherwise
		error('Scenario not recognized.')
		
		
		
end

end

