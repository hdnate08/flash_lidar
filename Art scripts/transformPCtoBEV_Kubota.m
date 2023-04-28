function transformPCtoBEV_Kubota(lidarData,boxLabels,gridParams,dataLocation)
% createBEVData create the Bird's-Eye-View image data and the corresponding
% labels from the given dataset.
%
% Copyright 2021 The MathWorks, Inc.

% Get classnames of dataset.  Should be 2 - "ATV" and "Pole"
classNames = boxLabels.Properties.VariableNames;

% Get the number of files.
numFiles = size(boxLabels,1);
processedLabels = cell(size(boxLabels));

% Reset the point cloud datastore.
reset(lidarData);

 for i = 1:numFiles
     
    ptCloud = read(lidarData);     
    groundTruth = boxLabels(i,:);

% Tilde in next line means "Don't import the second return from preprocess() (i.e., ptCldOut) to the workspace".
% The 1st return, processedData, is a colormap that appears to be, well IDK what it is.
    [processedData,~] = preprocess(ptCloud,gridParams);

    for ii = 1:numel(classNames)
        labels = groundTruth(1,classNames{ii}).Variables;
        processedLabels{i,ii} = [];
        if(iscell(labels))
            labels = labels{1};
        end
        if ~isempty(labels)

            % Get the label indices that are in the selected RoI.
            labelsIndices = labels(:,1) - labels(:,4) > gridParams{1,1}{1} ...
                          & labels(:,1) + labels(:,4) < gridParams{1,1}{2} ...
                          & labels(:,2) - labels(:,5) > gridParams{1,1}{3} ...
                          & labels(:,2) + labels(:,5) < gridParams{1,1}{4} ...
                          & labels(:,4) > 0 ...
                          & labels(:,5) > 0 ...
                          & labels(:,6) > 0;
            % This is setting certain labels to [] b/c labelsIndices = 0 in  
            % those cases, rejecting up to 1/2 the file for tripod data
            labels = labels(labelsIndices,:); 

            labelsBEV = labels(:,[2,1,5,4,9]);
            labelsBEV(:,5) = -labelsBEV(:,5);
%**************************************************************************
% Next line modded (blindly) by adding the +gridParams{1,2}{1}/2 term to 
% make it "symmetrical" with the line above it. IDK if it's correct but it 
% worked on the tripod & ATV data!!
%**************************************************************************
            %labelsBEV(:,1) = int32(floor(labelsBEV(:,1)/gridParams{1,3}{1})) + 1;
            labelsBEV(:,1) = int32(floor(labelsBEV(:,1)/gridParams{1,3}{1}) + gridParams{1,2}{1}/2) + 1;
            labelsBEV(:,2) = int32(floor(labelsBEV(:,2)/gridParams{1,3}{2}) + gridParams{1,2}{2}/2) + 1;

            labelsBEV(:,3) = int32(floor(labelsBEV(:,3)/gridParams{1,3}{1})) + 1;
            labelsBEV(:,4) = int32(floor(labelsBEV(:,4)/gridParams{1,3}{2})) + 1;
%**************************************************************************
% Had to add this if() statement to take care of the formatting of 
% processedLabels.  Otherwise cell2table() (line 87) does not give the  
% proper tablestructure below and boxLabelDatastore(processedLabels) in the 
% main script crashes.
%
% Old line: processedLabels{i,ii} = labelsBEV; and it works well for
% multiple entries in the 1st column (but not just 1 entry).  See Example
% code
%**************************************************************************
            if size(labelsBEV,1)==1 & ii==1
                processedLabels{i,ii} = {labelsBEV};
            else
                processedLabels{i,ii} = labelsBEV;
            end
        end
        
    end
    
    writePath = fullfile(dataLocation,'BEVImages');
    if ~isfolder(writePath)
        mkdir(writePath);
    end
    
    imgSavePath = fullfile(writePath,sprintf('%04d.jpg',i));
    imwrite(processedData,imgSavePath);

end

processedLabels = cell2table(processedLabels);
numClasses = size(processedLabels,2);
for j = 1:numClasses
    processedLabels.Properties.VariableNames{j} = classNames{j};
end

labelsSavePath = fullfile(dataLocation,'Cuboids/BEVGroundTruthLabels.mat');
save(labelsSavePath,'processedLabels');
end

%% Get the BEV image from point cloud.

function [imageMap,ptCldOut] = preprocess(ptCld,gridParams)

    % These are the [x,y,z] ranges set in the main script
    pcRange = [gridParams{1,1}{1} gridParams{1,1}{2} gridParams{1,1}{3} ...
               gridParams{1,1}{4} gridParams{1,1}{5} gridParams{1,1}{6}]; 

    % Locus of Pt cloud pts that are inside the ranges set above
    indices = findPointsInROI(ptCld,pcRange);
    ptCldOut = select(ptCld,indices);

    % Extract grid size from gridParams.
    bevHeight = gridParams{1,2}{2}; % 608
    bevWidth = gridParams{1,2}{1};  % 608
    
    % Extract grid resolution from gridParams.
    gridH = gridParams{1,3}{2}; % 9.8684
    gridW = gridParams{1,3}{1}; % 3.2895
     
    % Location and (normalized) intensity of pts within the ranges set above
    loc = ptCldOut.Location;
    intensity = ptCldOut.Intensity;
    intensity = normalize(intensity,'range'); % Rescale to [0,1] range

    % Find the grid position each point falls into.
% *************************************************************************
% I added +bevWidth/2 (i.e., 608/2) to int32(floor(loc(:,2)/gridW)) + 1 
% (i.e., y coord of ptCldOut.Location). That allowed me to execute this 
% function and also centered up the pt cloud.  Otherwise, line 151 
% (mapIndices = sub2ind(...)) causes a crash. 
% Note the perspective still looks incorrect. IDK if it's just my chosen 
% view or what. 
% *************************************************************************
    loc(:,1) = int32(floor(loc(:,1)/gridH)+bevHeight/2) + 1;
    %loc(:,2) = int32(floor(loc(:,2)/gridW)) + 1;
    loc(:,2) = int32(floor(loc(:,2)/gridW)+bevWidth/2) + 1;

    % Normalize the height (i.e., z coord of ptCldOut.Location)
    % This is really just a NUC on the z data
    loc(:,3) = loc(:,3) - min(loc(:,3));
    loc(:,3) = loc(:,3)/(pcRange(6) - pcRange(5));

    % Sort the points based on height.
    % IDK why they do this
    [~,I] = sortrows(loc,[1,2,-3]); % Sort based on 1st col (x data), break  
                                    % ties w/ 2nd col (y data), then w/ 3rd 
                                    % col (z data) but here, do it 
                                    % descending order
                                    
    locMod = loc(I,:); % Sorted ptCldOut.Location
    intensityMod = intensity(I,:); %Sorted (normalized) ptCldOut.Intensity
    
    % Initialize height and intensity map
    heightMap = zeros(bevHeight,bevWidth);
    intensityMap = zeros(bevHeight,bevWidth);
    
    locMod(:,1) = min(locMod(:,1),bevHeight);
    locMod(:,2) = min(locMod(:,2),bevHeight);
    
    % Find the unique indices having max height.
    mapIndices = sub2ind([bevHeight,bevWidth],locMod(:,1),locMod(:,2));
    [~,idx] = unique(mapIndices,"rows","first");
    
    binc = 1:bevWidth*bevHeight;
    counts = hist(mapIndices,binc);
    
    normalizedCounts = min(1.0, log(counts + 1) / log(64));
    
    for i = 1:size(idx,1)
        heightMap(mapIndices(idx(i))) = locMod(idx(i),3);
        intensityMap(mapIndices(idx(i))) = intensityMod(idx(i),1);
    end
    
    densityMap = reshape(normalizedCounts,[bevHeight,bevWidth]);
    
    % This is where they get that kooky colormap from
    imageMap = zeros(bevHeight,bevWidth,3);
    imageMap(:,:,1) = densityMap;       % R channel
    imageMap(:,:,2) = heightMap;        % G channel
    imageMap(:,:,3) = intensityMap;     % B channel
end