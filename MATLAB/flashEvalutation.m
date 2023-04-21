%% Written by: Jarrod P.Brown
% Date: 09/06/2019
% Notice: This software directly supports AFRL/RW
% Description:
% Run Tiger import first. Adjust the parameters below before running this
% script.
%
%% Setup Parameters
fov = 3*[1 1]; % [az el] ***************************adjust this to match sensor FOV

frames = [1:size(range,3)];
% frames = frames(end); % (frame start:frame end)*****adjust to only use some frames (helps with processing time)

avgFrames = false;   %***************************adjust to enable/disable (true/false) frame averaging

% range gating to keep more/less data
% The data will be replaced with Not-A-Number place holders in all further processing.
min_range = 0;      %***********************************
max_range = 2000;     %***********************************

% Set this to any percentage other than zero to enable
outlier = 0;        %***********************************alternative to range gating. 
% outlier = 50; % as a +-% 
% outlier removes ranges and intensity values more than x% from the mean.
% For example, 50 removes ranges more than 150% the mean range as well as
% ranges less than 50% the mean range. If outlier is 0 this function is
% disabled. 

%% Run
clc
az = linspace(-fov(1)/2,fov(1)/2,size(range,2));
el = linspace(-fov(2)/2,fov(2)/2,size(range,1));

az_matrix = repmat(az,[numel(el) 1]);
el_matrix = repmat(flip(el)',[1 numel(az)]);
az_array = az_matrix(:);
el_array = el_matrix(:);

if outlier ~= 0
   min_range = (1-outlier/100)*mean(range_array);
   max_range = (1+outlier/100)*mean(range_array);
end

if avgFrames
    range1 = nanmean(range,3);
    intensity1 = nanmean(intensity,3);
    frames = 1;
else
    range1 = range;
    intensity1 = intensity;
end

frame = [];
i = 0;
for frameNum = frames %size(range,3)  % loop through frames
    i = i+1;
    % 1 frame of data as a matrix (FPA)
    range_matrix = range1(:,:,frameNum);
    intensity_matrix = intensity1(:,:,frameNum);
    
    % 1 frame of data as an array
    range_array = range_matrix(:);
    intensity_array = intensity_matrix(:);
    
    % remove crazy outliers
    mask = true(size(range_array));
%     mask(range_array>max_range) = false;
%     mask(range_array<min_range) = false;
    
    az_array(~mask) = NaN;
    el_array(~mask) = NaN;
    range_array(~mask) = NaN; 
    intensity_array(~mask) = NaN;
    
    % convert to cartesian coordinates
    [x,y,z] = sph2cart(az_array*pi/180,...
                       el_array*pi/180,...
                       range_array);
                   
    % build pointcloud
    xyzPoints = horzcat(x,y,z);
    if exist('rainbowColorMap.m','file') % if you have this file, then add color
        intensity_1 = intensity_array/max(intensity_array(:));
        rgb = rainbowColorMap(intensity_1);
        ptCloud = pointCloud(xyzPoints,'Color',rgb);
    else
        ptCloud = pointCloud(xyzPoints,'Color',rgb); % otherwise, ignore color
    end

    % store processed data of each frame
    frame(i).x = x;
    frame(i).y = y;
    frame(i).z = z;
    frame(i).intensity = intensity_matrix;
    frame(i).range = range_matrix;
    frame(i).ptCloud = ptCloud;
end

% loop through frames and plot and calculate stats
figure
for i = 1:length(frame)
    pcshow(frame(i).ptCloud,'MarkerSize',20);

    xlabel('x')
    ylabel('y')
    zlabel('z')
    k = gca;
    k.CameraViewAngle = 7;
    view(-90,0)
    axis([200 2500 -150 150 -150 150])
    drawnow
    disp(['Frame ' num2str(i)])
    disp(['mean=' num2str(nanmean(frame(i).x))])
    disp(['std=' num2str(nanstd(frame(i).x))])
end

figure
imagers(frame(i).intensity)
title('Intensity')

figure
imagers(frame(i).range)
title('Range')

figure
imagers(frame(i).x)
title(['X, FOV=' num2str(fov)])
colorbar