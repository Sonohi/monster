function res = recordUEResults(Users, Stations, res, ix)

%   RECORD UE RESULTS records UE-space results
%
%   Function fingerprint
%   Users		->  UEs list
%   res			->  results data structure
%   ix			->  index of scheduling round

% 	res			-> updeted results

for iUser = 1:length(Users)
	rx = Users(iUser).Rx;
	iServingStation = find([Stations.NCellID] == Users(iUser).ENodeB);
	resM = struct(...
		'blocks', rx.Blocks,...
		'cqi', rx.WCQI, ...
		'preEvm', rx.PreEvm, ...
		'postEvm', rx.PostEvm, ...
		'bits', rx.Bits,...
		'sinr', rx.SINRdB, ...
		'snr', rx.SNRdB, ...
		'rxPosition', Users(iUser).Position, ...
		'txPosition', Stations(iServingStation).Position);
      user = Users(iUser);

    % Check if user is scheduled.
    station = Stations(iServingStation);
    scheduled = checkUserSchedule(user,station);
    if ~scheduled
      res(ix + 1, iUser) = resultHook(resM);
    else
      res(ix + 1, iUser) = resM;
    end
      
end


  function userresM = resultHook(userres)
    % Hook for adjusting saved results. 
    % Removal of reception metrics (e.g. demodulated statistics) if not
    % scheduled given the round
    % 
    %   Function fingerprint
    %   userres    ->  results related to single user
    
    %   userresM   ->  Mutated results returned 
    userres.blocks = NaN;
    userres.cqi = NaN;
    userres.preEvm = NaN;
    userres.postEvm = NaN;
    userres.bits = NaN;
    userresM = userres;
  end


end



