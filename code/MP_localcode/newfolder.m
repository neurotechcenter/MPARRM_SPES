function newfolder(folderpath, foldername)
% create a newfolder 
% Tao Xie, Mar/21/2022

%%
if nargin == 1
    if ~exist(folderpath,'dir')
        mkdir(folderpath);
    end
end

if nargin == 2
    for i = 1:length(foldername)
        fullpath = [folderpath '/' foldername{i}];
        if ~exist(fullpath,'dir')
            mkdir(fullpath);
        end
    end
end