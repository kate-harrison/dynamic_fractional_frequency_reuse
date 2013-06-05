%% Demo
% This is really just a specific case of
% create_data_for_various_user_locations.m.




%% Number of users that can be supported with FFR with various location configurations
% This script determines the number of users that can be supported with FFR
% at with various locations. After setup, it loops
% over (in order) 'iteration number' and 'power
% constraint p'. In the innermost loop, it calls main_program.m.
%
% The data from this file is averaged and plotted in
% figure_6a_7ab__supportable_number_of_users.m.
%
% This file was previously called run_all_dist_type.m
%
% See also: main_program, get_simulation_parameter,
% figure_6a_7ab__supportable_number_of_users
%
% The different configurations:
%     1 = user at a specific (fixed) distance (not used in this file)
%         (this is done in create_data_for_specific_user_location.m)
%     2 = four blobs total; in each cell, half are at 0.5 km and half are
%         at 1.25 km (introduced in random order)
%     3 = in each cell, users uniformly placed between 0.1km and 1.25 km
%     4 = in each cell, users randomly placed between 0.1km and 1.25km
%         *from their base station* (not necessarily closer to the other base
%         station)



clc; clear all; close all;


dist_type = 3;

%% Set the general parameters (see get_simulation_parameter.m for more information) 
% These parameters are currently the same as in create_data_for_specific_user_location

CDR = get_simulation_parameter('CDR');    % target rate in bps

% Cells
num_cells = get_simulation_parameter('num_cells');              % number of cells
intersite_distance = get_simulation_parameter('intersite_distance');   % km

% Frequencies
Ns = 16;         % number of subbands (each has c = Nc/Ns subcarriers)
c = 1;         % number of subcarriers per subband
Nc = Ns*c;      % number of subcarriers
system_bw = get_simulation_parameter('system_bw');     % system bandwidth in Hz
subcarrier_bw = system_bw/Nc;   % bandwidth of each subcarrier

% Users
N_total = Nc*2;
N_cell = N_total/num_cells;

% Noise floor
TNP = get_simulation_parameter('TNP', subcarrier_bw);



%% Set the specific parameters for this simulation
% These parameters are currently the same as in
% create_data_for_specific_user_location except for the number of
% iterations (also, d_array is not needed here and dist_type is set elsewhere).

p_array = .0015;    % Watts
num_iterations = 5; % different from the other file

% Control verbosity
output = 0; % 1 = display all figures; 0 = display no figures
output2 = 1;


% Simulation
t_max = 20*N_total;                  % maximum number of steps in the simulation
a = 1;              % Assume a = 1 in the shadow algorithm
beta = 1e-6;
delta = .5;         % (0 = change "all the time"; 1 = never change)
rayleigh_param = 1;   % parameter to the Rayleigh random variable
wait_time = 0.5;    % time between iterations in seconds
grace_period = 5;   % number of steps we allow the algorithm to converge
number_activated_per_cell = 1;%floor(1/3*N_cell);

% Do not change below this line
reuse_scheme = 'FFR';


%% Create dummy arrays

% Create generic arrays (of different sizes) for holding various types of datablank_one_cell_user_array = ones(N_cell,1);
blank_one_cell_user_array = ones(N_cell,1);
blank_user_array = ones(N_total, 1);
blank_user_and_subband_array = repmat(blank_user_array, [1 Ns]);    % array(i,j) = value for user i, subband j
blank_BS_and_subband_array = ones(num_cells, Ns);   % array(i,j) = value for BS i in subband j
blank_BS_array = ones(num_cells, 1);

blank_activated_array = blank_user_array*0;   % 1 = awake; 0 = asleep
blank_activated_array([1:number_activated_per_cell (N_cell + 1):(N_cell + number_activated_per_cell)]) = ones(1, 2*number_activated_per_cell);

cell_array = [blank_one_cell_user_array*1; blank_one_cell_user_array*2];



%% Execute the simulation

best_N_array = zeros(1, length(p_array));

% Set up the distance array based on the distance type (see the top
% of this file for documentation)
switch(dist_type)
    case 2,
        % TYPE 2
        % Four blobs - half at 0.5km and half at 1.25 km (add randomly)
        blank_half_user_array = ones(N_cell/2, 1);
        d = [.5*blank_half_user_array; 1.25*blank_half_user_array];
        d1 = shuffle(d);
        d2 = shuffle(d);
        
    case 3,
        % TYPE 3
        % Two masses - users between .1km and 1.25km away (uniformly)
        d1 = rand_unif(.1, 1.25, [N_cell 1]);
        d2 = rand_unif(.1, 1.25, [N_cell 1]);
        
    case 4,
        % TYPE 4
        % Two masses - users [-1.25,.1], [.1, 1.25] km away (uniformly)
        d1 = zeros(N_cell, 1);
        d1a = rand_unif(.1, 1.25, [N_cell 1]);
        d1b = rand_unif(-1.25, -.1, [N_cell 1]);
        idx = ((randi(2, [N_cell 1])-1) == 1);
        d1(idx) = d1a(idx);
        d1(~idx) = d1b(~idx);
        
        d2 = zeros(N_cell, 1);
        d2a = rand_unif(.1, 1.25, [N_cell 1]);
        d2b = rand_unif(-1.25, -.1, [N_cell 1]);
        idx = ((randi(2, [N_cell 1])-1) == 1);
        d2(idx) = d2a(idx);
        d2(~idx) = d2b(~idx);
    otherwise
        error('Unknown dist type');
end

dist_array = [d1 (intersite_distance-d1); (intersite_distance-d2) d2];



% Iterate over the power constraint (p)
for p_idx = 1:length(p_array)
    P_BS_total = p_array(p_idx);
    display(['Power: ' num2str(P_BS_total) ' W']);
    if (p_idx > 1 && best_N_array(p_idx-1) == N_total)
        best_N_array(p_idx) = N_total;
        display('Optimization: had enough power before => have enough power now');
    else
        run main_program;
        best_N_array(p_idx) = best_N;
    end
end

%% Show the allocation
allocation = histc(user_subband.*user_activated, 1:Ns)'



%% Show the user locations
figure; hold on;
pl = d1(user_activated(1:length(d1))==1);
plot(pl, zeros(size(pl)), '.');
pl = intersite_distance-d2(user_activated(length(d1)+1:length(user_activated))==1);
plot(pl, zeros(size(pl)), '.');
line([intersite_distance/2 intersite_distance/2], [-1 1]);
text(0.05,0, 'BS1');
text(2.35,0, 'BS2');
        
