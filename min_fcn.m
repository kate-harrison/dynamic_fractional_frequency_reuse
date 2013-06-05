function [ B ] = min_fcn( a, beta, Q, Z, m, p, extras )
%   [ B ] = min_fcn( a, beta, Q, Z, m, p, extras )
%
% This is the shadow function as defined in Stolyar and Viswanathan's paper
% "Self-organizing dynamic fractional frequency reuse in OFDMA systems".


% Parse input
c = extras(1);
p_limit = extras(2);


% Shadow function
% B = a*p + beta*(Q.*m + Z*p);
B = a*p;


% Impose constraints
B(Q >= c) = inf;
% if (all(B == inf))
%     display('Warning: arbitrary choice between subbands!');
%     problem = 1;
% end

% if (all(B == inf))
%     Q
% end

% if (Z >= p_limit)
%     display('Warning: ran out of power at the base station!');
%     problem = 1;
% end


end

