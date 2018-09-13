function [ i1,i2,i3,i4 ] = qind2sub( sic, ndx )
%IND2SUB Subscripts from linear index.

sic = [ sic, ones(1,4-numel(sic)) ];
sik = [ 1, cumprod( sic(1:3) ) ];

vi = rem(ndx-1, sik(4)) + 1;
i4 = (ndx - vi)/sik(4) + 1;
ndx = vi;
vi = rem(ndx-1, sik(3)) + 1;
i3 = (ndx - vi)/sik(3) + 1;
ndx = vi;
vi = rem(ndx-1, sik(2)) + 1;
i2 = (ndx - vi)/sik(2) + 1;
ndx = vi;
vi = rem(ndx-1, sik(1)) + 1;
i1 = (ndx - vi)/sik(1) + 1;

end

