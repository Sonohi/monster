function color = colorHex2Rgb(str)
%COLORHEX2RGB Summary of this function goes here
% Convert color code to 1-by-3 RGB array (0~1 each)
color = sscanf(str(2:end),'%2x%2x%2x',[1 3])/255;
end

