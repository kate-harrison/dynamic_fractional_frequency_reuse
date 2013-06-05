function [ W ] = get_dBm_to_W( dBm )
%GET_DBM_TO_W Converts dBm to Watts
%
%   [ W ] = get_dBm_to_W( dBm )


W = 1e-3*10.^(dBm./10);

end

