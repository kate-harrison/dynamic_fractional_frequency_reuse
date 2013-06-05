% This is my version of the simulation described in "Self-organizing
% Dynamic Fractional Frequency Reuse in OFDMA Systems" by Alexander Stolyar
% and Harish Viswanathan (June 18, 2007).

% Unless this variable is defined, we will use FFR instead of reuse half.
if ~exist('MAIN_PROGRAM_USES_REUSE_HALF')
    MAIN_PROGRAM_USES_REUSE_HALF = 0;
end


% Power constraint
p_threshold = P_BS_total;   % maximum power for any given user (in Watts)

% Counters
stop_count = 0;
stable_count = 0;


%% Initialize the users
% Activate some
user_activated = blank_activated_array;
% Place them in cells
user_cell = cell_array; % cell/BS user i belongs to
% Place them into subbands
user_subband = randi([1 Ns], [N_total 1]);  % subband user i is transmitting in (initialized randomly)
% Give them all their fair share of the total power to start with
user_power = blank_user_array*(P_BS_total/N_cell);  % power user i is using in their subband
% Put them at the distances in dist_array
user_distance = dist_array; % user_distance(i,j) = distance user i is from BS in cell j
% Generate Rayleigh fades
fades = raylrnd(rayleigh_param, [N_total num_cells Ns]);

%% Pre-allocate arrays
user_interference_level = blank_user_array * TNP; % interference from other base stations (array(i,j) = int. for user i on subband j)
user_m = blank_user_and_subband_array;
user_p = blank_user_and_subband_array;

Q = blank_BS_and_subband_array*0;
Z = blank_BS_array*0;
band_changes = zeros(1, t_max);


%% Check for verbose mode; if on, initialize figures
% If verbose mode, create and initialize figures
if (output == 1)
    NOISE = figure; set(NOISE, 'OuterPosition', [12   503   424   343]);
    SUBBANDS = figure; set(SUBBANDS, 'OuterPosition', [875   501   424   343]);
    for i = 1:num_cells
        subplot(num_cells, 1, i); hist(user_subband(user_cell == i),1:Ns);
        axis([-inf inf 0 N_cell]); t = 0;
        title(['Subband distribution in cell ' num2str(i) ' at time step t = ' num2str(t)]);
    end
    pause(wait_time);
    POWER = figure; set(POWER, 'OuterPosition', [443   154   424   343]);
    Q_GRAPH = figure; set(Q_GRAPH, 'OuterPosition', [12   156   424   343]);
    BAND_CHANGE_GRAPH = figure; set(BAND_CHANGE_GRAPH, 'OuterPosition', [442   501   424   343]);
    PAPER_GRAPHS = figure; set(PAPER_GRAPHS, 'OuterPosition', [875   156   424   343]);
end

% Second level of verbosity (first is 'output')
if (output2 == 1)
    S = figure;
end


%% Run the simulation
% Iterate over timesteps
for t = 1:t_max
    problem = 0;
    
    % RESET
    % Reset some of the variables
    user_interference_level = blank_user_and_subband_array * 0;   % intialize interference with thermal noise
    count = blank_user_and_subband_array;
    
    % iterate over the cells
    for k = 1:num_cells

        % UPDATE
        % Update the needs of each user
        for i = 1:N_total   % for each user
            if (user_cell(i) ~= k || user_activated(i) == 0)
                % Not in this subband or not activated
                continue;
            end
            
            % Update noise levels
            % count: to count the number of users in each subband
            
            for j = 1:N_total   % for all other users...
                % (If it's in i's cell or inactivated, skip it)
                if (user_cell(i) == user_cell(j) || user_activated(j) == 0)
                    continue;
                end
                sb = user_subband(j);
                
                count(i,sb) = count(i,sb) + 1;
                
                user_interference_level(i,sb) = user_interference_level(i,sb) + ...
                    apply_path_loss(user_power(j), user_distance(i,user_cell(j)), fades(i, user_cell(j), sb));
                
                %*(user_m(j,sb)/c);
                % multiply by fade to user i (the one who is being interfered with) by the fade from teh interferers base station
                
            end
            user_interference_level(i,:) = user_interference_level(i,:)./count(i,:) ;
            
            
            % Find m_ij and p_ij for each user
            for j = 1:Ns    % for each subband
                % Allocate more carriers for as long as we're over our power limit
                % per subcarrier
                for m = 1:c     % for m up to the number of subcarriers per subband
                    p_rx = (2^(CDR/(m*subcarrier_bw))-1)*(user_interference_level(i,j)+TNP*m)*m;
                    p_tx = undo_path_loss(p_rx, user_distance(i, user_cell(i)), fades(i,k,j));
                    if (p_tx < p_threshold)
                        break;
                    end
                end
                % If we're still over the threshold, just scale it back and
                % produce a warning
                if (p_tx >= p_threshold)
                    p_tx = p_threshold;
                    %                 warning(['Need more power for user ' num2str(i) ' on subband ' num2str(j)]);
                end
                
                % Store the values
                user_m(i,j) = m;
                user_p(i,j) = p_tx;
                
            end
            
        end
        
%         if (any(any(user_m > 1)))
%             display('Someone required more than one subcarrier in some subband.');
%         end
        
        % ALLOCATE
        for i = 1:N_total   % for each user
            if (user_activated(i) == 0 || user_cell(i) ~= k)
                % If the user is inactivated, skip him
                continue;
            end
            
            cell = k;
            B = min_fcn(a, beta, Q(cell,:), Z(cell), user_m(i,:), user_p(i,:), [c P_BS_total]);
            
            if MAIN_PROGRAM_USES_REUSE_HALF
                % REUSE HALF
                % Force users into only half of the bands
                % Cell 2 uses first half of subcarriers, cell 1 uses second
                % half
                B( (k-1)*length(B)/2 + (1:length(B)/2) ) = inf;
            end
            
            
            [min_val,J] = min(B);   % J = potential future subband
%             j = user_subband(i);    % current subband
            
            % If the gain is not significant, stay where we are
            if ~( min_val < (1-delta) * B(j) )
                J = j;
            else
                band_changes(t) = band_changes(t) + 1;
            end
            
            if (length(J) > 1)
                display('J has too many entries');
            end
            
            % Update the virtual queue and virtual power counter
            Q(cell,J) = Q(cell,J) + user_m(i,J);
            
            Z(cell) = Z(cell) + user_p(i,J);
            user_subband(i) = J;
            user_power(i) = user_p(i,J);
        end
        
    end
    
    % DO WORK for all cells, subbands at once
    
    Q = max(Q-c, 0);
    Z = max(Z - P_BS_total, 0);
    
    % Verbose level 1
    if (output == 1)
        if (mod(t, 5) ~= 0)
            continue;
        end
        % SHOW RESULTS
        figure(NOISE);
        imagesc(user_interference_level);
        title('Noise levels for users across subbands (red = higher)');
        xlabel('Subband'); ylabel('User');
        colorbar;

        
        figure(SUBBANDS);
        for i = 1:num_cells
            subplot(num_cells, 1, i); hist(user_subband(user_cell == i),1:Ns);
            axis([-inf inf 0 N_cell]);
            title(['Subband distribution in cell ' num2str(i) ' at time step t = ' num2str(t)]);
        end
        
        
        figure(Q_GRAPH);
        max_val = max(beta*(max(max(Q)) + max(Z)),.1);
        for i = 1:num_cells
            plot = beta*[Q(i,:); ones(size(Q(i,:)))*Z(i)];
            subplot(num_cells, 1, i); bar(plot', 'stacked');
            axis([-inf inf 0 max_val]);
            title(['\beta*(queue size) in cell ' num2str(i) ' at time step t = ' num2str(t)]);
        end
        legend('subcarrier', 'power');
        
        
        figure(POWER);
        for i = 1:num_cells
            total_power = zeros(1,Ns);
            for j = 1:Ns
                total_power(j) = mean(user_power(user_cell==i & user_subband==j));
            end
            subplot(num_cells, 1, i); bar(total_power);
            title(['Average power distribution in cell ' num2str(i) ' at time step t = ' num2str(t)]);
        end
        
        
        figure(BAND_CHANGE_GRAPH);
        title('Percentage of users who changed bands');
        xlabel('Time step'); ylabel('Percentage');
        axis([1 t_max 0 100]);
        bar(band_changes);
        
        
        figure(PAPER_GRAPHS);
        for i = 1:num_cells
            total_power = zeros(1,Ns);
            total_subbands = zeros(1,Ns);
            for j = 1:Ns    % for each subband
                total_power(j) = sum(user_power(user_cell==i & user_subband==j));
                total_subbands(j) = sum(user_subband(user_cell==i)==j);
            end
            subplot(num_cells, 1, i); bar(total_power./total_subbands);
            title(['Power/subband in cell ' num2str(i) ' at time step t = ' num2str(t)]);
        end
        
        
        pause(wait_time);
        Q
    end
    
    % Verbose level 2
    if (output2 == 1)
        % Display subband allocation
        figure(S);
        for i = 1:num_cells
            subplot(num_cells, 1, i); hist(user_subband(user_cell == i & user_activated == 1),1:Ns);
            axis([-inf inf 0 N_cell]);
            title(['Subband distribution in cell ' num2str(i) ' at time step t = ' num2str(t)]);
        end
    end
    
    
    if(any(any(Q>0)) | any(Z > 0))
        problem = 1;
    else
        problem = 0;
    end
    
    
    if (problem == 0)
        % Reset the stop count
        stop_count = 0;
        
        % Increment the stability counter
        stable_count = stable_count + 1;
        
        % If we've managed to do well with all these users for long enough,
        % declare ourselves finished
        if (stable_count >= grace_period)
            if (all(user_activated))
                display(['Cannot fit any more!']);
                best_N = sum(user_activated);
                return;
            end
            
            
            % Add another user
            pause(wait_time);
            N = sum(user_activated);
            b = mod(N,2);
            user_activated(b*N_cell + floor(N/2)+1) = 1;
            
            stable_count = 0;
        end
        

        
    else
        % Reset the stability counter
        stable_count = 0;
        
        % Increment the stop count
        stop_count = stop_count + 1;
    end
    
    if (stop_count >= grace_period)
        display(['Leaving because we reached the stopping criterion and t = ' num2str(t) '.']);
        best_N = sum(user_activated) - 1;   % We went one too far
        return;
    end
    
end


if (t == t_max)
    display(['Did not reach the limit in ' num2str(t) ' time steps.']);
    best_N = sum(user_activated)-1;
end

