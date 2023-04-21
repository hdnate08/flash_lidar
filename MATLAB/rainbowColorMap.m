%*****************************************************************************
%
% FUNCTION NAME(S):     rainbowColorMap()
%
% DESCRIPTION:          This function creates a color model for the 3D
%                       point cloud using the intensity data acquired from
%                       the FLRT receiver CSV. This function is called in
%                       the buildPointCloud() function.
%
% FORMAL ARGUMENTS:     intensity
%
% FUNCTION OUTPUT:      rgb
% 
%*****************************************************************************

function rgb = rainbowColorMap(intensity)
    %% Convert intensity to RGB
    a = (1-intensity)/0.25;        % invert and group
    X = floor(a);           % this is the integer part
    Y = uint8(floor(255*(a-X)));   % fractional part from 0 to 255
    rgb = uint8(zeros(length(a),3));
    
    % X==0;
    y = Y(X==0);
    len = length(y);
    zer = uint8(zeros(len,1));
    rgb(X==0,:) = horzcat(zer+255,y,zer);
    
    y = Y(X==1);
    len = length(y);
    zer = uint8(zeros(len,1));
    rgb(X==1,:) = horzcat(255-y,zer+255,zer);
    
    y = Y(X==2);
    len = length(y);
    zer = uint8(zeros(len,1));
    rgb(X==2,:) = horzcat(zer,zer+255,y);
    
    y = Y(X==3);
    len = length(y);
    zer = uint8(zeros(len,1));
    rgb(X==3,:) = horzcat(zer,255-y,zer+255);
    
    y = Y(X==4);
    len = length(y);
    zer = uint8(zeros(len,1));
    rgb(X==4,:) = horzcat(zer,zer,zer+255);
end