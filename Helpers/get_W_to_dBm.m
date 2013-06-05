function [ dBm ] = get_W_to_dBm( W )
%GET_DBM_TO_W Converts Watts to dBm
%
%   get_W_to_dBm( W )


% Need to make the inverse of this
%W = 1e-3*10.^(dBm./10);

dBm = 10*log10(1e3*W);

end

