%% Collate the results from create_data_for_various_user_locations
% This file plots the results from create_data_for_various_user_locations
% (dist_type=3). Distance types are defined in
% create_data_for_various_user_locations.m.
%
% This file averages across iterations but otherwise does
% no calculations prior to plotting.
%
% This file generates Figure 6b in the paper.
%
% See also: create_data_for_various_user_locations



%% Set up some basic parameters
clc; clear all; close all;

num_iterations = 5; % each data set must have at least this many iterations
dist_type = 3; % we only use dist_type = 3 for this file


%% Compute the data if it hasn't been computed already
for scheme_type = [1 4 48]
    c = scheme_type;
    Ns = 48/c;
    create_data_for_various_user_locations(dist_type, Ns, c);
end


%% Load the pre-computed data
% Pre-allocate the arrays which will old the data
FFR1 = zeros([1 16]);
FFR4 = zeros([1 16]);
FFR48 = zeros([1 16]);


for iteration = 1:num_iterations
    for scheme_type = [1 4 48]
        c = scheme_type;
        Ns = 48/c;
        reuse_scheme = ['FFR, c=' num2str(c) ', Ns=' num2str(Ns)];

        % Load the appropriate file
        file = load(['data/dist_type=' num2str(dist_type) ', reuse=' reuse_scheme ...
            ', iteration=' num2str(iteration)]);
        
        % Assign the data from the file to a local variable
        power = file.p_array;
        switch(scheme_type)
            case 1, % FFR1
                FFR1 = FFR1 + file.best_N_array;
            case 4, % FFR4
                FFR4 = FFR4 + file.best_N_array;
            case 48, % FFR48
                FFR48 = FFR48 + file.best_N_array;
            otherwise,
                error('Unsupported scheme type');
        end
        
    end
end

% Perform the averaging
FFR1 = FFR1/num_iterations;
FFR4 = FFR4/num_iterations;
FFR48 = FFR48/num_iterations;



%% Figure 8
% Effect of subbands on the number of users the system can support

% Define some colors for plotting
color1 = [.75 .5 .5];
color2 = [.5 .75 .5];
color3 = [.5 .5 .75];

% Create a new figure
figure; 

% Plot FFR with 1 subcarrier per subband
loglog(power, FFR1, 'color', color1);

% Prevent the next call to loglog() from clearing the plot
hold on;

% Plot FFR with 4 and 48 subcarrier per subband, respectively
loglog(power, FFR4, 'color', color2);
loglog(power, FFR48, 'color', color3);

% Add text to the plot near the line we plotted earlier
% FFR1
idx = 3;
text(power(idx), FFR1(idx), '1 subcarrier per subband', 'color', color1, ...
    'fontweight', 'bold', 'horizontalalignment', 'left', ...
    'verticalalignment', 'bottom', 'rotation', 0, 'fontsize', 12);
% FFR4
idx = 6;
text(power(idx), FFR4(idx), '4 subcarriers per subband', 'color', color2, ...
    'fontweight', 'bold', 'horizontalalignment', 'left', ...
    'verticalalignment', 'top', 'rotation', 0, 'fontsize', 12);
% FFR48
idx = 10;
text(power(idx), FFR48(idx), '48 subcarriers per subband', 'color', color3, ...
    'fontweight', 'bold', 'horizontalalignment', 'left', ...
    'verticalalignment', 'top', 'rotation', 0, 'fontsize', 12);


% Label the axes
xlabel('Base station power constraint');
ylabel('Users supported');

% Add a grid to the plot and set the locations of the tick labels
grid on;
set(gca, 'ytick', [1:5 10:10:50 100]);
set(gca, 'xtick', [1:5 10:10:50 100]);

% Save the figure
print('-djpeg', 'Figures/effect of number of subbands.jpeg');
