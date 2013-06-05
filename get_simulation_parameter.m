function [varargout] = get_simulation_parameter(param_name, varargin)


switch(param_name)
    case 'CDR',
        % constant data rate in bps
        varargout{1} = 9.6e3;   
    case 'intersite_distance',
        % distance between base stations in km
        varargout{1} = 2.5;
    case 'BS_power_array',
        % array of maximum base station powers in dBm
        varargout{1} = 0:3:50;
    case 'num_cells',
        % number of cells in the model (warning: may not always propagate
        % correctly!)
        varargout{1} = 2;
    case 'Ns',
        % number of subbands (each has Nc/Ns subcarriers)
        varargout{1} = 2;
    case 'c',
        % number of subcarriers per subband
        varargout{1} = 1;
    case 'N_cell',
        % number of users per cell
        varargout{1} = 1;
    case 'system_bw',
        % system bandwidth in Hz
        varargout{1} = 1.25e6;
    case 'noise_bw',
        varargout{1} = get_simulation_parameter('system_bw');
    case 't_max',
        % number of timesteps to use
        varargout{1} = 100;
    case 'happy_threshold',
        % If the users' decisions haven't changed in 'happy_threshold' timesteps
        % (each), exit early.
        varargout{1} = 10;
    case 'TNP',
        if nargin > 1
            subcarrier_bw = varargin{1};
        else
            error('Expected a second input argument (bandwidth) when calculating TNP.')
        end
        % Calculate the thermal noise (i.e. noise floor) power in Watts
        k = 1.3803e-23; % Boltzmann's constant
        T = 290;        % Temperature in degrees Kelvin (~room temperature)
        B = subcarrier_bw;        % subcarrier bandwidth
        TNP = k*T*B;     % Noise power in Watts
        varargout{1} = TNP;
    otherwise,
        error(['Did not recognize parameter name ''' param_name ...
            '''. Please look in get_simulation_parameter.m for valid parameter names.']);

    
end



end