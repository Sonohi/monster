function validateEmptyUsers(Users)

	%   VALIDATE EMPTY USERS is used to check that the eNodeB UE list is empty
	%
	%   Function fingerprint
	%   Users		->  test

	validateattributes([Users.UeId],{'numeric'},{'<=',-1})
end
