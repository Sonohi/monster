function PL_tw = buildingloss3gpp38901(materials, freq)
% Defined in accordance to 7.4.3. This function offers PL_tw, which is the building penetration loss through the external wall.
% materials must be a Nx2 matrix consisting of materials and the proportion.
lossMaterial = zeros(length(materials),1);
for iMaterial = 1:length(materials)

    switch materials{1,iMaterial}

    case 'StandardGlass'
        lossMaterial(iMaterial) = 2+0.2*freq;
    case 'IRRGlass'
        lossMaterial(iMaterial) = 23+0.3*freq;
    case 'Concrete'
        lossMaterial(iMaterial) = 5+4*freq;
    case 'Wood'
        lossMaterial(iMaterial) = 4.85+0.12*freq;
    otherwise
        lossMaterial(iMaterial) = NaN;
    end

end

% Summarize loss per material and the proportion of such.
sumMaterialLoss = 0;
for iMaterial = 1:length(materials)
    proportion = materials{2,iMaterial};
    loss = lossMaterial(iMaterial);
    sumMaterialLoss = sumMaterialLoss + (proportion * 10^((loss/-10)));
end

% Compute combined loss
PL_npi = 5; 
PL_tw = PL_npi - 10*log10(sumMaterialLoss);

end