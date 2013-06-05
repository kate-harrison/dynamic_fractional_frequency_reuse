%% Collate the results from create_data_for_{specific_user_location,various_user_locations}
% This file plots the results from create_data_for_specific_user_location
% (dist_type=1) and create_data_for_various_user_locations
% (dist_type=[2,3,4]). Distance types are defined in
% create_data_for_various_user_locations.m.
%
% Make sure you set reuse_scheme = 'FFR' in
% create_data_for_specific_user_location to generate the correct data. If
% you do not, data which is needed below will not be created.
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

reuse_scheme = 'FFR';
num_type_1 = 3; % number of iterations for dist_type = 1
num_other_types = 5;    % number of iterations for dist_type = [2,3,4]


%% Load up all of the pre-computed data
% Averages across iterations (number of iterations defined above) for all
% four distance types. Distance types are defined in
% create_data_for_various_user_locations.m.

% Initialize the arrays
N_1 = zeros([8 16]);
N_2 = zeros([1 16]);
N_3 = zeros([1 16]);
N_4 = zeros([1 16]);
        
for dist_type = 1:4
    
    % If distance type == 1, load pre-computed data and average across
    % num_type_1 iterations.
    if (dist_type == 1)
        
        for iteration = 1:num_type_1
            load(['data/dist_type=' num2str(dist_type) ', reuse=' reuse_scheme ...
                ', iteration=' num2str(iteration)], 'best_N_array', 'p_array', ...
                'd_array', 'N_total');
            N_1 = N_1 + best_N_array;
        end
        
        N_1 = N_1/num_type_1;
        
        continue;
    end

    % If distance type != 1, load pre-computed data and average across
    % num_other_types iterations.
    for iteration = 1:num_other_types
        load(['data/dist_type=' num2str(dist_type) ', reuse=' reuse_scheme ...
            ', iteration=' num2str(iteration)], 'best_N_array', 'p_array', ...
            'N_total');

        switch(dist_type)
            case 2,
                N_2 = N_2 + best_N_array;
            case 3,
                N_3 = N_3 + best_N_array;
            case 4,
                N_4 = N_4 + best_N_array;
        end
    end
end

% Perform the averaging for the other types
N_2 = N_2/num_other_types;
N_3 = N_3/num_other_types;
N_4 = N_4/num_other_types;



%% Figure 6a
% Effect of location and power constraint on the supportable number of
% users under DFFR (dist_type = 1).

% Create the figure and plot
figure;
surf(p_array, d_array, N_1);

% Set the shading
shading interp;

% Label the axes
xlabel('Base station power (Watts)');
ylabel('Distance from own base station (km)');
zlabel('Number of users supported');

% Set the axis limits
axis([-inf inf -inf inf 0 N_total]);

% Save the figure
print('-djpeg', 'Figures/Two blobs of users (dist type = 1)');




%% Figure 7a
% Slices of Figure 6a (each represents a different distance, dist_type = 1).

% Create a new figure
figure;

% We will plot four slices
for i = 1:4
    % Set the target distance
    switch(i)
        case 1, target = 0.25; yl = 'Number of users';
        case 2, target = 0.5; yl = '';
        case 3, target = 1; yl = '';
        case 4, target = 1.25; yl = '';
    end
    
    % Find the entry in d_array which most closely matches our target
    [I Y] = find_closest(target, d_array);
    
    % Plot the slice then add a title and (if applicable) the y-axis label
    subplot(4,1,i); semilogx(p_array, squeeze(N_1(I, :)), '--.'); grid on;
    title(['Distance = ' num2str(target)]);
    ylabel(yl);
end

% Add a label to the x-axis of the last subpot
xlabel('Base station power (Watts)');

% Save the figure
print('-djpeg', 'Figures/dist type = 1 for different distances');




%% Figure 7b
% Effect of user distribution within the cell and total power constraint on
% the number of users the system can support.

% Create a new figure
figure;

% Define the linewidth to be used for the plots
lw = 1.0001;

% Define some colors to be used for the plots
blue = [.5 .5 .75];
red = [.75 .5 .5];
green = [.5 .75 .5];
black = [0 0 0];
redgreen = [.75 .75 .5];

% Plot dist_type = 2 (inner and outer)
semilogx(p_array, N_2, '-*', 'color', redgreen, 'linewidth', lw);
% Add text to the plot near the line we just plotted
idx = 12;
text(p_array(idx), N_2(idx), 'Inner and outer', 'color', redgreen-.2, ...
    'fontweight', 'bold', 'horizontalalignment', 'right', ...
    'verticalalignment', 'bottom', 'rotation', 67, 'fontsize', 12);

% Add a grid to the plot. Don't erase previous data when we plot again.
hold on; grid on;


% Plot dist_type = 3 (uniform)
semilogx(p_array, N_3, '-*', 'color', blue, 'linewidth', lw);
% Add text to the plot near the line we just plotted
idx = 10;
text(p_array(idx), N_3(idx), 'Uniform', 'color', blue-.2, ...
    'fontweight', 'bold', 'horizontalalignment', 'right', ...
    'verticalalignment', 'bottom', 'rotation', 67, 'fontsize', 12);


% Plot dist_type = 1 for two different fixed distances
for i = [2 4]
    % Each distance ("target") will have a different color and label.
    % Additional appearance-only label parameters are defined ('idx',
    % 'rotation') for each distance.
    switch(i)
        case 2, target = 0.5; c = green; label='Inner'; idx = 5; rotation = 67;
        case 4, target = 1.25; c = red; label = 'Outer'; idx = 14; rotation = 70;
    end
    
    % Find the entry in d_array which most closely matches our target, then
    % plot along that slice.
    [I Y] = find_closest(target, d_array);
    semilogx(p_array, squeeze(N_1(I, :)), '-*', 'color', c, 'linewidth', lw);

    % Add text to the plot near the line we just plotted
    text(p_array(idx), N_1(I,idx), label, 'color', c-.2, ...
        'fontweight', 'bold', 'horizontalalignment', 'right', ...
        'verticalalignment', 'bottom', 'rotation', rotation, 'fontsize', 12); 
end

% Label the axes
xlabel('Base station power (Watts)');
ylabel('Number of users');

% Save the figure
print('-djpeg', 'Figures/different distance types.jpeg');


