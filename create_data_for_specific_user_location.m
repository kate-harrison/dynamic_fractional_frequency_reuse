function [] = create_data_for_specific_user_location(reuse_scheme)
%   [] = create_data_for_specific_user_location(reuse_scheme)
%
% Specify the reuse scheme ('half' or 'FFR') as the only argument to this
% function.
%
% This script determines the number of users that can be supported at a
% fixed distance d (also called dist_type = 1). After setup, it loops over
% (in order) 'iteration number', 'fixed distance d', and 'power constraint
% p'. In the innermost loop, it calls main_program.m.
%
% The data from this file is averaged and plotted in the figure_*.m files
% listed below.
%
% See also: main_program, get_simulation_parameter,
% figure_6a_7ab__supportable_number_of_users,
% figure_6b__comparison_of_DFFR_and_reuse_half




%% Set the general parameters (see get_simulation_parameter.m for more information) 

CDR = get_simulation_parameter('CDR');    % target rate in bps

% Cells
num_cells = get_simulation_parameter('num_cells');              % number of cells
intersite_distance = get_simulation_parameter('intersite_distance');   % km

% Frequencies
Ns = 48;         % number of subbands (each has c = Nc/Ns subcarriers)
c = get_simulation_parameter('c');         % number of subcarriers per subband
Nc = Ns*c;      % number of subcarriers
system_bw = get_simulation_parameter('system_bw');     % system bandwidth in Hz
subcarrier_bw = system_bw/Nc;   % bandwidth of each subcarrier

% Users
switch(reuse_scheme)
    case 'FFR',
        N_total = Nc*2;
    case 'half',
        N_total = Nc;
    otherwise,
        error(['Unrecognized reuse scheme: ' reuse_scheme ...
            '. Valid options are ''FFR'' and ''half''.']);
end
N_cell = N_total/num_cells;

% Noise floor
TNP = get_simulation_parameter('TNP', subcarrier_bw);


%% Set the specific parameters for this simulation

d_array = logspace(log10(.25), log10(1.25), 8);
p_array = logspace(log10(.0001), log10(.05), 16); % Watts
num_iterations = 3;

% Control verbosity
output = 0; % 1 = display all figures; 0 = display no figures
output2 = 0;


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
dist_type = 1;  % users are all at the specified distance d from their base station


%% Create dummy arrays

% Create generic arrays (of different sizes) for holding various types of data
blank_one_cell_user_array = ones(N_cell,1);
blank_user_array = ones(N_total, 1);
blank_user_and_subband_array = repmat(blank_user_array, [1 Ns]);    % array(i,j) = value for user i, subband j
blank_BS_and_subband_array = ones(num_cells, Ns);   % array(i,j) = value for BS i in subband j
blank_BS_array = ones(num_cells, 1);

blank_activated_array = blank_user_array*0;   % 1 = awake; 0 = asleep
blank_activated_array([1:number_activated_per_cell (N_cell + 1):(N_cell + number_activated_per_cell)]) = ones(1, 2*number_activated_per_cell);

%% Execute the simulation
% Loops over (in order): iteration, distance, power
% Innermost call is to main_program.m


for iteration = 1:num_iterations
    
    filename = ['data/dist_type=' num2str(dist_type) ', reuse=' reuse_scheme ...
        ', iteration=' num2str(iteration)]
    if exist([filename '.mat'], 'file') == 2
        display(['Skipping iteration ' num2str(iteration) ': data already exists.']);
        continue;
    end
    
    % Pre-allocate and clear arrays
    cell_array = [blank_one_cell_user_array*1; blank_one_cell_user_array*2];
    best_N_array = zeros(length(d_array), length(p_array));
    
    
    
    % Iterate over the list of fixed distances (d_array)
    for d_idx = 1:length(d_array)
        d = d_array(d_idx);
        display(['Distance: ' num2str(d) ' km']);
        
        
        % Set up the distance array
        % Each user is d km away from their own base station and
        % (intersite_distance - d) km away from the other base station
        dist_array = [blank_one_cell_user_array*d blank_one_cell_user_array*(intersite_distance-d); ...
            blank_one_cell_user_array*(intersite_distance-d) blank_one_cell_user_array*d];
        
        
        % Iterate over the power constraint (p_array)
        for p_idx = 1:length(p_array)
            P_BS_total = p_array(p_idx);
            display(['   Power: ' num2str(P_BS_total) ' W']);
            
            pd_filename = ['partial_data/dist_type=' num2str(dist_type) ', reuse=' reuse_scheme ...
                ', iteration=' num2str(iteration) ', (d_idx, p_idx)=(' num2str(d_idx) ...
                ',' num2str(p_idx) ')'];
            if exist([pd_filename '.mat'], 'file') == 2
                display(['Skipping (d_idx, p_idx)=(' num2str(d_idx) ...
                ',' num2str(p_idx) '): data already exists.']);
                load(pd_filename);
                continue;
            end
            
            % Allow for optimization to cut down the run-time
            if (p_idx > 1 && best_N_array(d_idx, p_idx-1) == N_total)
                best_N_array(d_idx, p_idx) = N_total;
                display('Optimization: had enough power before => have enough power now');
            else
                % Run the simulation for these values of d and p and save the
                % results.
                switch(reuse_scheme)
                    case 'FFR',
                        MAIN_PROGRAM_USES_REUSE_HALF = 0;
                    case 'half',
                        MAIN_PROGRAM_USES_REUSE_HALF = 1;
                    otherwise,
                        error(['Unrecognized reuse scheme: ' reuse_scheme]);
                end
                
                run main_program;
                
                best_N_array(d_idx, p_idx) = best_N;
            end
            
            % Save step-by-step data in case we have to stop the simulation
            % partway through.
            save(pd_filename);
            
        end
    end
    
    
    % Save the final result
    save(filename);
    
    % Display the final result
    if (length(d_array) > 1 & length(p_array) > 1)
        figure; surf(p_array, d_array, best_N_array);
        ylabel('Distance from own base station (km)');
        xlabel('Base station power (Watts)');
        zlabel('Number of users supported');
        axis([-inf inf -inf inf 0 N_total])
    end
    
end

% best_N_array

