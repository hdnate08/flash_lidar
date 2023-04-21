%% Written by: Jarrod P.Brown
% Date: 09/15/2018
% Notice: This software directly supports FSU PhD dissertation
% Description:
function [varargout] = imagers(varargin)
if nargin == 1
    im = varargin{1};
    plotIt = true;
    stds = 3;
elseif nargin == 2
    im = varargin{1};
    plotIt = varargin{2};
    stds = 2;
elseif nargin >= 4
    im = varargin{1};
    plotIt = varargin{2};
    param = varargin{3};
    if strcmpi(param,'lims')
        lims = varargin{4};
        stds = 0;
    elseif strcmpi(param,'stds')
        stds = varargin{4};
    else
        error('invalid param')
    end
else
    error('incorrect input args');
end

% check for struct
if isstruct(im)
    im_all = im;
    if isfield(im_all,'s0')
        im = im_all.s0;
    else
        disp('im is a sruct')
    end
end    

% if more than 1 frame, plot the first one
[~,~,frames] = size(im);
if frames > 1
    im = im(:,:,1);
end

%   reshape and imagesc with color scaling
if numel(im(:)) == (256*320)
    im = reshape(im(:),256,[]);
elseif numel(im(:)) == (480*640)
    im = reshape(im(:),480,[]);
elseif numel(im(:)) == (512*512)
    im = reshape(im(:),512,[]);
elseif numel(im(:)) == (720*1280)
    im = reshape(im(:),720,[]);
elseif numel(im(:)) == (725*2152)
    im = reshape(im(:),725,[]);
elseif numel(im(:)) == (144*430)
    im = reshape(im(:),144,[]);
elseif size(im,1) == 1 || size(im,2) == 1
    sr = sqrt(length(im(:)));
    disp('Guessing on the shape of the image')
    if floor(sr)==sr
        im = reshape(im(:),sr,[]);
    else
        im = [reshape(im(:),1,[]) zeros(1,ceil(sr)^2-length(im(:)))];
        im = reshape(im(:),ceil(sr),[]);
        disp('Added zero elements to force image to be square')
    end
    
end

if plotIt
    if stds >= 0
        m = mean(im(:), 'omitnan');
        s = std(im(:), 'omitnan');
        lims = [(m - (stds * s)) (m + (stds * s))];
    end
    if lims(1) < min(im(:))
        lims(1) = min(im(:));
    end
    if lims(2) > max(im(:))
        lims(2) = max(im(:));
    end
%     im(isnan(im(:))) = m;
    if lims(1) == lims(2)
        imagesc(im)
    else
        imagesc(im,lims)
    end
    axis off
    colormap(gray)
    drawnow
%     truesize
end

if nargout == 1
    varargout{1} = im;
elseif nargout == 2
    varargout{1} = size(im,1);
    varargout{2} = size(im,2);
elseif nargout == 3
    varargout{1} = im;
    varargout{2} = size(im,1);
    varargout{3} = size(im,2);
end
