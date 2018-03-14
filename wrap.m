parfor iUtil = 1:4
    for k = 1:3
			try
        sweep_util_users_sim(iUtil, k);
			catch ME
				sonohilog(sprintf('Error in simulate for util index %i and users index %i',iUtil, k),'WRN');
			end			
    end
end