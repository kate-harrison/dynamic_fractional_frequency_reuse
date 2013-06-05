function [R] = rand_unif(min, max, size)
%   function [R] = rand_unif(min, max, size)
R = min + (max-min).*rand(size);

%         Generate uniform values from the interval [a, b].
%            r = a + (b-a).*rand(100,1);
%  
%         Generate integers uniform on the set 1:n.
%            r = ceil(n.*rand(100,1));
