%% Determine user choices
% Given the variables below, run an algorithm which will determine the
% users' preferences.
%
% Expects the following variables to be defined:
%   CDR = target constant data rate (bps)
%   p = maximum transmit power (Watts)
%   d = distance from a user to his own base station (km)
%   intersite_distance = distance between base stations (km)
%   t_max = maximum number of timesteps
%   happy_threshold = if the users' decisions haven't changed in 
%       'happy_threshold' timesteps (each), exit early
%   subcarrier_bw = bandwidth of each subcarrier/band
%   TNP = thermal noise (noise floor) power in Watts
%
% We hard-code to have only two users and two bands.
%
% The intitial condition is for user 2 to always start on band 2 only and
% use enough power to achieve his target rate in a clean channel.


%% Initialization
% Create generic arrays for holding various types of data
blank_user_array = zeros(1, 2); % generic array for holding user-related data
blank_subband_array = zeros(1, 2); % generic array for holding subband-related data
blank_user_and_subband_array = zeros(2,2); % generic array for holding user-and-subband-related data
blank_choice_array = zeros(1, 3); % generic array for holding choice-related data

% This array holds the choice of each of the two users, encoded in the
% following way:
%   1 = band 1 only
%   2 = band 2 only
%   3 = both bands
user_choice = blank_user_array;

% This array holds the power allocation for each user and each subband,
% arranged in the following way:
%   user_power(i,j) = user i's power in subband j
user_power = blank_user_and_subband_array;

% This array holds the number of timesteps that have elapsed since the user
% last changed its choice. 
user_last_switched = blank_user_array;

shout_count = 0;

% Calculate the distance from each user to the *other* base station (will
% be used later).
distance_to_other_BS = intersite_distance - d;

    
    
%% Set starting conditions
% User #2 always starts by using only band 2
user_choice(2) = 2;
% User #2 always starts by putting enough power on band 2 to achieve his
% target rate (CDR) in the clean channel case.
user_power(2, 2) = undo_path_loss((2^(CDR/subcarrier_bw)-1)*(100*TNP), d, 1);



%% Calculation

% Iterate over timesteps
for t = 1:t_max
    out_of_power = 0;   % boolean flag
    
    % For each user...
    for user_index = 1:2
        noise = blank_subband_array;    % originally noise-less
        other_user_index = 3-user_index; % index of the other user
        
        % % % Determine the noise level in each band
        % How noisy is the band?
        switch(user_choice(other_user_index))
            case 1, % other user is on band 1 only
                noise(1) = apply_path_loss(user_power(other_user_index, 1), ...
                    distance_to_other_BS, 1);
            case 2, % other user is on band 2 only
                noise(2) = apply_path_loss(user_power(other_user_index, 2), ...
                    distance_to_other_BS, 1);
            case 3, % other user is on both bands
                noise(1) = apply_path_loss(user_power(other_user_index, 1), ...
                    distance_to_other_BS, 1);
                noise(2) = apply_path_loss(user_power(other_user_index, 2), ...
                    distance_to_other_BS, 1);
        end
        
        % Add in the noise floor
        noise = noise + TNP;
        
        
        % Initialize the power levels (taking the noise levels into
        % account)
        power = blank_choice_array;
        % If we take choice number 1 or number 2, that means we are
        % operating on a single band and need to achieve our target data
        % rate (CDR) using only that band. The following line assigns the
        % power necessary to achieve this to the first two entries of the
        % 'power' array, thus indicating the amount of power we'd need for
        % each of the first two choices.
        %
        % Note that the third choice (i.e. third entry in 'power') is to
        % use both subbands. For now, we leave that entry at 0.
        power(1:2) = (2^(CDR/subcarrier_bw)-1)*noise(1:2);
        
        
        % P1 is the array of received power levels given a varying level of
        % input power (input power ranges on a log scale from eps (roughly
        % 2.2e-16) and 1).
        P1 = apply_path_loss(logspace(log10(eps), log10(1), 1000)*p,d,1);
        
        % For these various received power levels, determine how far we are
        % from our target rate (CDR) if we use only band 1.
        rate_still_needed = CDR-subcarrier_bw*log2(1+P1/noise(1));
        
        % If we overshot our rate (i.e. rate_still_needed < 0), set the
        % corresponding power level to a very large number as a flag. Then
        % set the corresponding entries in 'rate_still_needed' to 0 so the
        % values in the array are strictly nonnegative.
        P1(rate_still_needed < 0) = 1e100;
        rate_still_needed = max(rate_still_needed, 0);
        
        % Figure out the required power on band 2 in order to achieve the
        % target rate using both bands.
        P2 = (2.^(rate_still_needed/subcarrier_bw)-1)*noise(2);
        
        % Find the total (received) power and find the minimum. This
        % represents the total (received) power for choice 3.
        total_p = P1+P2;
        [val idx] = min(total_p);
        power(3) = val;
        % Record the best power balance between the two bands.
        P1_best = P1(idx);
        P2_best = P2(idx);

        % Undo the pathloss calculation in order to obtain the total
        % transmitted power and then find the minimum.
        %
        % Note that the minimizing index ('choice_idx') represents the choice that
        % this user will make.
        total_power_needed = undo_path_loss(power, d, 1);
        [best_power choice_idx] = min(total_power_needed);

        % Make the power assignments according to the user's choice.
        switch(choice_idx)
            case 1, % use band 1 only
                user_power(user_index, 1) = total_power_needed(1);
                user_power(user_index, 2) = 0;
            case 2, % use band 2 only
                user_power(user_index, 1) = 0;
                user_power(user_index, 2) = total_power_needed(2);
            case 3, % use both bands with the best power balance
                user_power(user_index, 1) = undo_path_loss(P1_best, d, 1);
                user_power(user_index, 2) = undo_path_loss(P2_best, d, 1);
        end
                

        % If the new choice is the same as the choice made by this user in
        % the last time step, increment the 'user_last_switched' counter.
        % Otherwise, reset it.
        if (choice_idx == user_choice(user_index))
            user_last_switched(user_index) = user_last_switched(user_index) + 1;
        else
            user_last_switched(user_index) = 0;
        end
        
        
        % Record the user's choice
        user_choice(user_index) = choice_idx;

        % Check to make sure that the user was within his transmit power
        % constraint. If he was not, ...
        if (best_power > p)
            
            % Reset his 'user_last_switched' counter.
            user_last_switched(user_index) = 0;
            
            % If both users chose choice 3 (use both bands), increase the
            % 'shout_count'. We will later use this value to bump ourselves
            % out of undesirable situations if needed.
            if all(user_choice == 3) % both universal
                shout_count = shout_count + 1;
            end
            
            
            % If the user could not achieve his target rate even in a clean
            % channel, exit the simulation with a notification that the
            % power limit is unrealistically low.
            needed_power = undo_path_loss((2^(CDR/subcarrier_bw)-1)*TNP,d,1);
            if (needed_power > p)
                out_of_power = 1;
                warning('Out of power');
                return;
            end
            
            
            % If the users get locked into choosing choice 3 over and over
            % again, separate them. In other words, put user 1 on band 1
            % only and user 2 on band 2 only. Give them each the power that
            % would be needed in a clean channel to achieve their target
            % data rates. Then reset the shout count.
            if (shout_count > 20)
                % separate them
                user_choice = 1:2;
                user_power = [1 0; 0 1]*needed_power;
                shout_count = 0;
            end
        end

    end
    
    % If the users go more than 'happy_threshold' iterations (each) without
    % switching their choice, exit now since they will not change their
    % minds in future iterations anyway.
    if (all(user_last_switched > happy_threshold))
        return;
    end
    
end