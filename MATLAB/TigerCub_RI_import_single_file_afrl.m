%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
% Based on ASC code, edited by AFRL/RW
%
% Advanced Scientific Concepts Llc, proprietary information
% Extract the data from the SEQ and store in matrices
% When displaying the range matrix, force the color limits to 0 to max
% range using caxis([0 max_range])
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

%variables
%nframes = 1000;

%constants, do not change
numpix = 16384;
%iframe = 1:nframes;
fstartri = 512;
fileheader=1024;
framesize = 66960;
xpxl = 1:128;
ypxl = 1:128;

% directory to the .SEQ file and the name of the file ex: 'C:\Folder\Tiger_Cub_Data.seq'
%   fname   = ('N:\tigercub training\hanwha_1_2018-11-05-02-07-28_RI AGC.seq');
d = fileSelectorUI(88);
if isempty(d)
    return
end
fname = d.fullname;

fid1    = fopen(fname);
eof=fseek(fid1,0,'eof');
file_size=ftell(fid1);

% USE THE FOLLOWING 2 LINES TO IMPORT ALL FRAMES
nframes=(file_size-fstartri-fileheader)/framesize;
iframe=1:nframes;

% FILL iframes YOURSELF FOR WHICH FRAMES YOU WANT LOADED,
% TO LOAD THE FRAMES 12 TO 49 DO THE FOLLOWING iframes=12:49
% IF LOADING ALL FRAMES, COMMENT THE FOLLOWING LINE
% iframe=4:12;

%initiate the data matrices with correct sizes for speed
intensity = zeros(128,128,size(iframe,1));
range = zeros(128,128,size(iframe,1));

% get image data
%'inten' is grayscale intensity, 'range' stores the range in feet

for frame=iframe(1):iframe(1)+size(iframe,2)-1
    fseek(fid1, fstartri+(frame-1)*framesize,'bof');   % get to the start of R&I data
    RIvector =  uint32(fread(fid1,numpix,'uint32','l'));
    RIvector = fliplr(flip(reshape(RIvector,128,128)));
    intensity(:,:,frame-iframe(1)+1) = bitand(RIvector(ypxl,xpxl),4095); % store the intensity counts data
    range(:,:,frame-iframe(1)+1) = double(bitshift(RIvector(ypxl,xpxl),-12))./64; % store the range data
end
range=rot90(rot90(rot90(range)));
intensity=rot90(rot90(rot90(intensity)));
fclose(fid1);

%clears useless variables
clearvars -except range intensity fname d

%%
rotate = true;
if rotate
    range = rot90(range);
    intensity = rot90(intensity);
end

clc
int = intensity;
int(int==0) = NaN;
imean = nanmean(int(:));
int(isnan(int(:))) = imean;
int2 = int./16;

rng = range;
rng(rng==0) = NaN;
rng(rng>(5*nanstd(rng(:))+nanmean(rng(:)))) = NaN;
rng(rng<(nanmean(rng(:))-5*nanstd(rng(:)))) = NaN;
rmean = nanmean(rng(:));
rng(isnan(rng(:))) = rmean;
% rng2 = rng./64;
rng2 = rng/max(rng(:))*2^8;

for i = 1:size(int,3)
    I = uint16(int(:,:,i));
    Ji(:,:,i) = imadjust(I,stretchlim(I),[]);
    I = uint8(int2(:,:,i));
    Ji2(:,:,i) = imadjust(I,stretchlim(I),[]);
    
    I = uint16(rng(:,:,i));
    Jr(:,:,i) = imadjust(I,stretchlim(I),[]);
    I = uint8(rng2(:,:,i));
    Jr2(:,:,i) = imadjust(I,stretchlim(I),[]);
end

[dir,name,ext] = fileparts(d.fullname);
igifName = fullfile(dir,[name '_intensity.gif']);
rgifName = fullfile(dir,[name '_range.gif']);

map = colormap(gray(2^8));
image_i = uint8(Ji2);
image_r = uint8(Jr2);
frame_interval = 1/20;

iaviName = fullfile(dir,[name '_intensity.avi']);
raviName = fullfile(dir,[name '_range.avi']);
iv = VideoWriter(iaviName);
rv = VideoWriter(raviName);
open(iv);
open(rv);

for i = 1:size(image_i,3) % frames
    
    A = image_i(:,:,i);
    B = image_r(:,:,i);
    
    writeVideo(iv,A)
    writeVideo(rv,B)
    
    if i == 1
        imwrite(A, map, igifName, 'gif', 'LoopCount', Inf, ...
            'DelayTime', frame_interval);
        imwrite(B, map, rgifName, 'gif', 'LoopCount', Inf, ...
            'DelayTime', frame_interval);
    else
        imwrite(A, map, igifName, 'gif', 'WriteMode', 'append', ...
            'DelayTime', frame_interval);
        imwrite(B, map, rgifName, 'gif', 'WriteMode', 'append', ...
            'DelayTime', frame_interval);
    end
end
close(iv);
close(rv);

implay(uint16(Ji))
implay(uint16(Jr))

disp('Import complete!')
disp('GIFs and AVIs for range and intensity images were saved to the input folder!')
