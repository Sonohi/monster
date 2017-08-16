for l = 1:size(enbOut,1)
	for h = 1:size(enbOut, 2)
		for r = 1:size(enbOut, 3)
			utilMean(l, h, r) = mean([enbOut(l, h, r, :).util]);
			utilStd(l, h, r) = std([enbOut(l, h, r,:).util]);
		end
	end
end