% Run this file to set up all of the directories correctly, etc.

clc; clear all; close all;

%% Add all subdirectories to the path
% We do this now so we can call get_simulation_value() below.
% Note that the strings below will be used in regexpi so we escape the
% period in .svn and .git using the \ character.
do_not_include = {'\.svn', '\.git', 'html', 'tl_', 'cvx'};


path_string = genpath(pwd);
strings = regexp(path_string, ':', 'split');
new_paths = [];

for i = 1:length(strings)
    if all(cellfun('isempty',regexpi(strings(i), do_not_include)))
        % If it does not contain any of the banned strings, put it in the
        % queue to be added
        new_paths = [new_paths ':' cell2mat(strings(i))];
    end
end

new_paths([1 end]) = [];  % chop off leading and trailing ':'
addpath(new_paths);


%% Create the directories data/ and Figures/ if they don't already exist
for i = 1:3
    switch(i)
        case 1, dir_name = 'data';
        case 2, dir_name = 'Figures';
        case 3, dir_name = 'partial_data';
    end
    
    if (exist(dir_name, 'dir') ~= 7)
        display(['Creating directory ' dir_name '/...']);
        mkdir('.', dir_name);
    end
end


%% Add all subdirectories to the path
% We do this again to catch the directories we just created.
display('Adding all subdirectories to the path...');
path_string = genpath(pwd);
strings = regexp(path_string, ':', 'split');
new_paths = [];

for i = 1:length(strings)
    if all(cellfun('isempty',regexpi(strings(i), do_not_include)))
        % If it does not contain any of the banned strings, put it in the
        % queue to be added
        new_paths = [new_paths ':' cell2mat(strings(i))];
    end
end

new_paths([1 end]) = [];  % chop off leading and trailing ':'
addpath(new_paths);


%% Done!
display(' ');
display('      ...done!');
display(' ');
display(' ');
display('IMPORTANT: If you are new to this code base, I suggest you read');
display('the file getting_started.m before proceeding. Use the command');
display('''edit README.md'' to do this.');

%% Clean up
clear all;