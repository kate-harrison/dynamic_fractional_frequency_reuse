%% Comparison of capacity with reuse-one vs. reuse-half schemes
% The comparison is done using a two-cell toy example. The results from
% this script are shown in Figure 3 of the paper.
%
% See also: apply_path_loss, get_simulation_parameter

%% Simulation parameters

% Clear the environment
clc; clear all; close all;

% Set the parameters
CDR = get_simulation_parameter('CDR');    % constant data rate, bps
num_cells = 2;  % number of cells
intersite_distance = get_simulation_parameter('intersite_distance');   % km

BS_power = get_simulation_parameter('BS_power_array');  % in dBm 
P_BS_total = get_dBm_to_W(BS_power);   % base station power constraint (in W)
% Some values for reference:
%   BS_power = 10 -> SNR = 1 dB at d = 1.25
%   BS_power = 19 -> SNR = 10 dB at d = 1.25
%   BS_power = 28 -> SNR = 20 dB at d = 1.25
%   BS_power = 39 -> SNR = 30 dB at d = 1.25

% Slow fading!
Ns = get_simulation_parameter('Ns');     % number of subbands (each has Nc/Ns subcarriers)
c = get_simulation_parameter('c');  % number of subcarriers per subband
Nc = Ns*c;    % number of subcarriers
N_cell = get_simulation_parameter('N_cell');    % number of users per cell
N_total = N_cell * num_cells;   % total number of users
system_bw = get_simulation_parameter('system_bw'); % Hz
subcarrier_bw = system_bw/Nc;
noise_bw = get_simulation_parameter('noise_bw');  % noise bandwidth in Hz

% Calculate the thermal noise (i.e. noise floor) power in Watts
TNP = get_simulation_parameter('TNP', subcarrier_bw);


%% Display simulation parameters to the user
clc;

display('-------------------- BASIC --------------------');
display(['Constant data rate: ' num2str(CDR) ' bps']);
display(['Number of cells: ' num2str(num_cells)]);
display(['Intersite distance: ' num2str(intersite_distance) ' km']);
display('Base station power constraint array (in dBm):');
display(['     ' num2str(BS_power)]);
display('Base station power constraint array (in W):');
display(['     ' num2str(P_BS_total,'%10.1e  ')]);
display('Path loss model can be found in apply_path_loss.m');
display(' ');

display('-------------------- CELLS AND USERS --------------------');
display(['Number of cells: ' num2str(num_cells)]);
display(['Number of users per cell: ' num2str(N_cell)]);
display(['Total number of users: ' num2str(N_total)]);
display(' ');


display('-------------------- BANDWIDTH --------------------');
display(['Number of subbands: ' num2str(Ns)]);
display(['Number of subcarriers per subband: ' num2str(c)]);
display(['Total number of subcarriers: ' num2str(Nc)]);
display(['System bandwidth: ' num2str(system_bw/1e6) ' MHz']);
display(['Bandwidth for each subcarrier: ' num2str(subcarrier_bw/1e6) ' MHz']);
display(['Noise bandwidth: ' num2str(noise_bw/1e6) ' MHz']);
display(['Thermal noise (noise floor) power: ' num2str(TNP) ' Watts (' ...
    num2str(get_W_to_dBm(TNP)) ' dBm)']);


%% Perform the calculations

% Generic SNR formula:
% SNR = 10* log10(apply_path_loss(P_BS_total, d)./TNP) % SNR in dB 

% d (in km) represents the distance between the user and its base station.
% In this simulation, we vary the value of d across all of the values in
% d_array.
d_array = [.1:.1:intersite_distance/2];

% We set up blank arrays of the appropriate size which will contain our
% results. Preallocation is recommended in Matlab.
blank_array = zeros(length(d_array), length(BS_power));
reuse_one_SNR = blank_array;
reuse_half_SNR = blank_array;
reuse_one_capacity = blank_array;
reuse_half_capacity = blank_array;

% Iterate over the various base-station-to-user distances.
for i = 1:length(d_array)
    d = d_array(i);

    % Calculate the resulting SNR for two scenarios: reuse-one vs. reuse-half..
    reuse_one_SNR(i,:) = (apply_path_loss(P_BS_total, d, 1)/Nc)./(TNP + apply_path_loss(P_BS_total,intersite_distance-d, 1)/Nc);
    reuse_half_SNR(i,:) = apply_path_loss(P_BS_total, d, 1)./(TNP);
    
    % Using the SNR values from above, calculate the resulting capacities
    % using Shannon's capacity formula.
    reuse_one_capacity(i,:) = N_total * Nc .* subcarrier_bw .* log2(1 + reuse_one_SNR(i,:));
    reuse_half_capacity(i,:) = N_total * (Nc/N_total) .* subcarrier_bw .* log2(1 + reuse_half_SNR(i,:));

end


%% Plot the results
figure;
p_array = P_BS_total;
surf(p_array, d_array, reuse_one_capacity/1e6, ones(size(reuse_one_capacity))*.5); hold on;
surf(p_array, d_array, reuse_half_capacity/1e6, ones(size(reuse_half_capacity))*.25);
shading interp;
xlabel('Base station power (Watts)');
ylabel('Distance from own base station (km)');
zlabel('Capacity');
caxis([0 1]);   % set the color range
view(121, 35);  % set the viewing angle

% Save the plot
print('-djpeg', 'Figures/reuse one vs reuse half in capacity.jpeg');


