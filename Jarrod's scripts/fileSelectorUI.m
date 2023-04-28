%% Written by: Jarrod P.Brown
% Date: 09/15/2018
% Notice: This software directly supports FSU PhD dissertation
% Description:
% ds = fileSelectorUI(index,'Select One or More Files','off','get','*.tiff');
% load(ds(1))
function varargout = fileSelectorUI(varargin)
varargout{1} = [];
varargout{2} = [];
if nargin > 0
    defaultIndex = varargin{1};
else
    defaultIndex = 1;
end
if nargin > 1
    str = varargin{2};
else
    str = 'Select One or More Files';
end
if nargin > 2
    multiSelect = varargin{3};
else
    multiSelect = 'on';
end
if nargin > 3
    mode = varargin{4};
else
    mode = 'get';
end
if nargin > 4
    filter = varargin{5};
else
    filter = '*.*';
end
configFile = 'config.mat';

%% Load file UI
% This section is used to load data files by prompting the user to select
% the desired file through a user interface. The selected file is saved in
% a config.mat file and will be used as the default location the next time
% the script is ran.
%% Load config file
if exist(configFile,'file')
    defaults = [];
    load(configFile);
    if length(defaults) >= defaultIndex
        fileStr = defaults{defaultIndex};
    else
        fileStr = [];
    end
else
    default_path = cd;
    fileStr = [default_path '\Pol015.raw'];
end

%% get new filepath
if strcmpi(mode,'get')
    [filename, pathname] = uigetfile('*',str,fileStr,...
        'MultiSelect', multiSelect);
else
    [filename, pathname] = uiputfile(filter,str,fileStr);
end

%% update config file
if isequal(filename,0)
    disp('User selected Cancel')
    ds = [];
else
    % more than one file selected?
    if iscell(filename)
        filenames = filename;
        filenames_str = ['"' strjoin(filename,'" "') '"'];
    else
        filenames{1} = filename;
        filenames_str = filename;
    end
    
    for i = 1:length(filenames)
        fullname =  fullfile(pathname, filenames{i});
%         disp(['User selected ', filenames{i}])
        if exist(fullname,'file')
            dir_temp = dir(fullname); 
            dir_temp.fullname = fullname;
            ds(i) = dir_temp;
        else
            ds(i).name = filenames{i};
            ds(i).folder = pathname;
            ds(i).fullname = fullname;
        end
    end
    [~,I] = sort({ds.fullname});
    ds = ds(I);
    
    % Save to default file
    defaults{defaultIndex} = [pathname filenames_str];
    if exist('Tdefaults','var')
        save('config','defaults','Tdefaults');
    else
        save('config','defaults');
    end
    
    varargout{2} = fullfile(ds.folder,ds.name);
end

varargout{1} = ds;

end












