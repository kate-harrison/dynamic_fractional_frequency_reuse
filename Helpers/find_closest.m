function [idx, val] = find_closest(val, array)
% FIND_CLOSEST Find the index and value of the element in array
% which is closest (absolute distance) to val.
%   [idx, val] = find_closest(val, array)

diff = abs(array-val);
[Y, I] = min(diff);

idx = I;
val = array(I);


end