%% Collate the results from create_data_for_specific_user_location
% This file plots the results from create_data_for_specific_user_location
% (dist_type=1). Distance types are defined in
% create_data_for_various_user_locations.m.
%
% Make sure you set reuse_scheme = 'FFR' AND reuse_scheme = 'half' in
% create_data_for_specific_user_location to generate the correct data (i.e.
% run with one value, then run again with the other). If you do not, data
% which is needed below will not be created.
%
% For each distance type, it averages across iterations but otherwise does
% no calculations prior to plotting.
%
% This file generates Figures 6a, 7a, and 7b in the paper.
%
% See also: create_data_for_specific_user_location,
% create_data_for_various_user_locations


%% Set up some basic parameters
clc; clear all; close all;

% We use only dist_type = 1 for this file.
dist_type = 1;  % do not change

% We have 3 iterations for each type (FFR vs. half)
num_type_1 = 3;


%% Load and average pre-computed data for two cases: FFR and reuse-half.
for s = 1:2
    switch(s)
        case 1,
            reuse_scheme = 'half';
%             num_type_1 = 3;
        case 2,
            reuse_scheme = 'FFR';
%             num_type_1 = 2;
    end
    
    N = zeros([8 16]);
    
    for iteration = 1:num_type_1
        load(['data/dist_type=' num2str(dist_type) ', reuse=' reuse_scheme ...
            ', iteration=' num2str(iteration)], 'best_N_array', 'p_array', ...
            'd_array', 'N_total');
        N = N + best_N_array;
    end
    
    N = N/num_type_1;
    
    switch(s)
        case 1,
            N_half = N;
        case 2,
            N_FFR = N;
    end
    
end


%% Figure 6b
% Effect of location and power constraint on the supportable number of
% users under DFFR nad reuse-half (dist_type = 1).

% Create a new figure
figure;

% Plot the FFR data
surf(p_array, d_array, N_FFR, ones(size(N_FFR))*.5);

% Prevent the next call to surf() from clearing the plot
hold on;

% Plot the reuse-half data
surf(p_array, d_array, N_half, ones(size(N_FFR))*.25);

% Set the shading
shading interp

% Label the axes
xlabel('Base station power (Watts)');
ylabel('Distance from own base station (km)');
zlabel('Number of users supported');

% Set the axis limits
axis([-inf inf -inf inf 0 N_total]);
caxis([0 1]); % adjusts the coloring

% Save the figure
print('-djpeg', 'Figures/FFR vs reuse-half.jpeg');
