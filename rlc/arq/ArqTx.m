% ARQ TX defines a value class for the ARQ transmitted in the RLC

classdef ArqTx
	properties 
		sqn;
		tb;
	end

	methods
		function obj = ArqTx(Param, sqn, tb)
			obj.sqn = sqn;
			obj.tb = tb;			
		end
	end
end