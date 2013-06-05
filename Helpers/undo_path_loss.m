function [ P_tx_W ] = undo_path_loss( P_rx_W, dist, fade )
%UNDO_PATH_LOSS Calculates the required transmit power for a given
%received power.
%   P_tx_W = transmitted power in Watts
%   dist = distance between tx and rx
%   P_rx_W = received power in Watts

% This is the slow way to do this!
% load('simulation_parameters.mat');

% pl = inline('133.6+35*log10(d)', 'd');  % path loss model
% 
% P_tx_dBm = get_W_to_dBm(P_tx_W);
% P_rx_dBm = P_tx_dBm - pl(dist);
% P_rx_W = get_dBm_to_W(P_rx_dBm);

P_rx_dBm = get_W_to_dBm(P_rx_W);
% P_tx_dBm = P_rx_dBm + pl(dist);
P_tx_dBm = P_rx_dBm + (133.6+35*log10(dist));
P_tx_W = get_dBm_to_W(P_tx_dBm)/fade;


