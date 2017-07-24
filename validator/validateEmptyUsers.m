function validateEmptyUsers(Users)

	%   VALIDATE EMPTY USERS is used to check that the eNodeB UE list is empty
	%
	%   Function fingerprint
	%   Users		->  test

	validateattributes([Users],{'numeric'},{'<=',0})
end
