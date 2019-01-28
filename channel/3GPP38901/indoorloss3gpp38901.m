function PL_in = indoorloss3gpp38901(scenario, d2_in)
% Defined in accordance to 7.4.3. This function offers PL_in, which is the loss inside dependent on the depth of the building.
% Depth inside of the building can be defined by 2d_in, or compute with the use of two generated uniformly distributed variables.
switch scenario
case 'UMa'
 PL_in = 0.5*min(randi([0,25],1,2));
case 'UMi'
 PL_in = 0.5*min(randi([0,25],1,2));
case 'RMa'
 PL_in = 0.5*min(randi([0,10],1,2));
otherwise
 PL_in = 0.5*d2_in;
end

end