function [] = create_data_for_various_user_locations(varargin)
%   [] = create_data_for_various_user_locations(varargin)
%
% If no arguments are provided, default values for Ns and c are used and
% everything is evaluated for dist_type = [2,3,4]. If three arguments are
% provided (dist_type, Ns, c), these override the defaults.
%
% This script determines the number of users that can be supported with FFR
% at with various locations. After setup, it loops
% over (in order) 'iteration number' and 'power
% constraint p'. In the innermost loop, it calls main_program.m.
%
% The data from this file is averaged and plotted in the figure_*.m files
% listed below.
%
% See also: main_program, get_simulation_parameter,
% figure_6a_7ab__supportable_number_of_users, figure_8__effect_of_subbands
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


%% Determine the mode of operation
if nargin == 0
    special_scheme = 0;
    Ns = 48;         % number of subbands (each has c = Nc/Ns subcarriers)
    c = get_simulation_parameter('c');         % number of subcarriers per subband
else if nargin == 3
    special_scheme = 1;
    dist_type_override = varargin{1};
    Ns = varargin{2};
    c = varargin{3};
else
    error(['Incorrect number of arguments. Provide no arguments to use ' ...
        'the default values or provide values for (dist_type, Ns, c). See ' ...
        'get_simulation_parameter.m for documentation on these values.']);
end
end

%% Set the general parameters (see get_simulation_parameter.m for more information) 
% These parameters are currently the same as in create_data_for_specific_user_location

CDR = get_simulation_parameter('CDR');    % target rate in bps

% Cells
num_cells = get_simulation_parameter('num_cells');              % number of cells
intersite_distance = get_simulation_parameter('intersite_distance');   % km

% Frequencies
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

p_array = logspace(log10(.0001), log10(.05), 16); % Watts
num_iterations = 5; % different from the other file

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
if special_scheme
    number_activated_per_cell = 0;
else
    number_activated_per_cell = 1;%floor(1/3*N_cell);
end

% Do not change below this line
if special_scheme
    reuse_scheme = ['FFR, c=' num2str(c) ', Ns=' num2str(Ns)];
else
    reuse_scheme = 'FFR';
end


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
% Loops over (in order): iteration, distance type, power
% Innermost call is to main_program.m

for iteration = 1:num_iterations
    for dist_type = 2:4
        if special_scheme && (dist_type ~= dist_type_override)
            continue;
        end
        
        filename = ['data/dist_type=' num2str(dist_type) ', reuse=' reuse_scheme ...
            ', iteration=' num2str(iteration)]
        if exist([filename '.mat'], 'file') == 2
            display(['Skipping iteration ' num2str(iteration) ': data already exists.']);
            continue;
        end

        
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
            p_filename = ['partial_data/dist_type=' num2str(dist_type) ', reuse=' reuse_scheme ...
                ', iteration=' num2str(iteration) ', p_idx=' num2str(p_idx)];
            if exist([p_filename '.mat'], 'file') == 2
                display(['Skipping p_idx=' num2str(p_idx) ': data already exists.']);
                load(p_filename);
                continue;
            end
            
            P_BS_total = p_array(p_idx);            
            display(['   Power: ' num2str(P_BS_total) ' W']);
            
            
            if (p_idx > 1 && best_N_array(p_idx-1) == N_total)
                best_N_array(p_idx) = N_total;
                display('Optimization: had enough power before => have enough power now');
            else
                run main_program;
                
                best_N_array(p_idx) = best_N;
            end
            save(p_filename);
            
        end
        
        save(filename);
    end
end
end