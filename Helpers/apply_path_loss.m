function [ P_rx_W ] = apply_path_loss( P_tx_W, dist, fade )
%APPLY_PATH_LOSS Calculates the received power given the transmit power
%   P_tx_W = transmitted power in Watts
%   dist = distance between tx and rx
%   P_rx_W = received power in Watts

% This is the slow way to do this!
% load('simulation_parameters.mat');

% pl = inline('133.6+35*log10(d)', 'd');  % path loss model

P_tx_dBm = get_W_to_dBm(P_tx_W);
% P_rx_dBm = P_tx_dBm - pl(dist);
P_rx_dBm = P_tx_dBm - (133.6+35*log10(dist));
P_rx_W = get_dBm_to_W(P_rx_dBm)*fade;

