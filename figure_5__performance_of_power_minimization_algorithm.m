%% Analyze the performance of the power minimization algorithm
% Determine the regions in which users prefer universal reuse vs. reuse-1/2
% (or don't care) when we vary the transmit power constraint and the
% distance to the users' own base stations.
%
% See also: determine_user_choices, apply_path_loss, undo_path_loss,
% get_simulation_parameter


%% Simulation parameters
% Set get_simulation_parameter.m for more details on what each of these
% mean.

% Clear the environment
clc; clear all; close all;

% Set the parameters
CDR = get_simulation_parameter('CDR');    % constant data rate, bps
intersite_distance = get_simulation_parameter('intersite_distance');   % km

BS_power = get_simulation_parameter('BS_power_array');  % in dBm 
P_BS_total = get_dBm_to_W(BS_power);   % base station power constraint (in W)
% Some values for reference:
%   BS_power = 10 -> SNR = 1 dB at d = 1.25
%   BS_power = 19 -> SNR = 10 dB at d = 1.25
%   BS_power = 28 -> SNR = 20 dB at d = 1.25
%   BS_power = 39 -> SNR = 30 dB at d = 1.25

% Slow fading!
Nc = 2;
noise_bw = get_simulation_parameter('noise_bw')/256;  % noise bandwidth in Hz
system_bw = noise_bw;
subcarrier_bw = system_bw/Nc;

% Number of timesteps
t_max = get_simulation_parameter('t_max');
% If the users' decisions haven't changed in 'happy_threshold' timesteps
% (each), exit early.
happy_threshold = get_simulation_parameter('happy_threshold');

% Calculate the thermal noise (i.e. noise floor) power in Watts
TNP = get_simulation_parameter('TNP', subcarrier_bw);


%% Display simulation parameters to the user
clc;

display('-------------------- BASIC --------------------');
display(['Constant data rate: ' num2str(CDR) ' bps']);
display(['Intersite distance: ' num2str(intersite_distance) ' km']);
display('Base station power constraint array (in dBm):');
display(['     ' num2str(BS_power)]);
display('Base station power constraint array (in W):');
display(['     ' num2str(P_BS_total,'%10.1e  ')]);
display('Path loss model can be found in apply_path_loss.m');
display(' ');

display('-------------------- SIMULATION --------------------');
display(['Number of timesteps per situation: ' num2str(t_max)]);
display(['Number of stable timesteps before early exit (see comments ']);
display(['in determine_user_choice.m for more details): ' ...
    num2str(happy_threshold)]);
display(' ');


display('-------------------- BANDWIDTH --------------------');
% display(['Number of subbands: ' num2str(Ns)]);
% display(['Number of subcarriers per subband: ' num2str(c)]);
display(['Total number of subcarriers: ' num2str(Nc)]);
display(['System bandwidth: ' num2str(system_bw/1e6) ' MHz']);
display(['Bandwidth for each subcarrier: ' num2str(subcarrier_bw/1e6) ' MHz']);
display(['Noise bandwidth: ' num2str(noise_bw/1e6) ' MHz']);
display(['Thermal noise (noise floor) power: ' num2str(TNP) ' Watts (' ...
    num2str(get_W_to_dBm(TNP)) ' dBm)']);



%% Perform the calculations


% d (in km) represents the distance between the user and its base station.
% In this simulation, we vary the value of d across all of the values in
% d_array.
d_array = linspace(.1, intersite_distance/2, 20);

% We relabel this variable to be consistent with the naming convention for
% d_array (we will iterate over both in nested for loops).
p_array = P_BS_total;



% We set up a blank matrix of the appropriate size which will contain our
% results. Preallocation is recommended in Matlab. The results will be
% coded as follows:
%   2 = out of power/time
%   1 = universal
%   .5 = confused
%   0 = half
reuse = zeros(length(d_array), length(p_array));


% Iterate over the distance between the user and his base station
for i = 1:length(d_array)
    d = d_array(i);
    
    % Iterate over the base station power limit
    for j = 1:length(p_array)
        p = p_array(j);
        
        % Run the simulation to determine the users' choices in this
        % situation.
        run determine_user_choices;
        
        
        % Determine the outcome of the simulation and store the results in
        % the 'reuse' matrix.
        if (user_choice(1) == user_choice(2))
            if (user_choice(1) == 3)
                reuse(i,j) = 1;
            else
                reuse(i,j) = .5;
                display('Both chose same subband.');
            end
        else
            if (any(user_choice == 3))
                reuse(i,j) = .5;
                display('Chose different schemes.');
            else
                reuse(i,j) = 0;
            end
        end
        
        % If we did not converge in time, overwrite the previous result.
        if (t == t_max)
            reuse(i,j) = 1.5;
            display('Out of time or power.');
            user_choice
        end
        
        % If we ran out of power, overwrite the previous result.
        if (out_of_power == 1)
            reuse(i,j) = 2;
            display('Out of power.');
            user_choice
        end
                
    end
end


%% Plot the results
figure; imagesc(reuse);

% Add tick labels for only half of the values in d_array
idx = 1:2:length(d_array);
plot_d = d_array(idx);
set(gca, 'ytick', idx, 'yticklabel', num2str(plot_d',2));
ylabel('Distance from own base station (km)');

% Add tick labels for only half of the values in p_array
idx = 1:2:length(p_array);
plot_p = p_array(idx);
set(gca, 'xtick', idx, 'xticklabel', num2str(plot_p',2));
xlabel('Power constraint (W)');

caxis([0 2]); % set the color range

% Add annotations to make the plot clearer
text(5,5,'Universal reuse', 'color', 'k', 'fontsize', 14, 'fontweight', 'bold');
text(6,18.5,'Either scheme', 'color', 'k', 'fontsize', 14, 'fontweight', 'bold');
text(1.5,12.5,' \leftarrow   Out of power', 'color', 'k', 'fontsize', 14, 'fontweight', 'bold');
text(9,20,'Reuse 1/2', 'color', 'w', 'fontsize', 14, 'fontweight', 'bold');

% Save the plot
print('-djpeg', 'Figures/ffr performance.jpeg');