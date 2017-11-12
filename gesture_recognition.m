
% Get user input
saveImages = input('Save images? 1 or 0: ');
% Set resolution
width = 320;
height = 240; 
% Better use the existing camera object if it was used previously but the process
% was aborted and it still exists.
if exist('vidDevice', 'var') == 0
   % Initialization
   % Create the Video Device System object.
   vidDevice = imaq.VideoDevice('winvideo', 1, 'MJPG_640x480', ...
                             'ROI', [1 1 width height], ...
                             'ReturnedColorSpace', 'rgb', ...
                             'DeviceProperties.Brightness', 128, ...
                             'DeviceProperties.Sharpness', 5);
end

% Choose optical flow algorithm and customize it
% returns an optical flow object used to estimate the direction and
opticalFlowType = 'LK';

switch opticalFlowType         
   case 'Farneback'
      optical = opticalFlowFarneback('FilterSize',500);
    case 'LK'      
      optical = calibrateNoiseThreshold(0.02, vidDevice);
    case 'LKDoG'
      optical = opticalFlowLKDoG('NumFrames', 3);
    case 'HS'
      optical = opticalFlowHS('VelocityDifference',0);
    otherwise
      optical = opticalFlowHS('VelocityDifference',0);
end

% Stream Acquisition and Processing Loop
% Create a processing loop to perform motion detection in the input
% video. This loop uses the System objects you instantiated above.

% Set up for stream
nFrames = 0;
while (nFrames<100)     % Process for the first selected amount frames  
    % Acquire single frame from imaging device.
    rawImage = step(vidDevice);
    % Mirror the image (flip the matrix by rows and columns)
    rgbData = flip(rawImage,1); 
    rgbData = flip(rawImage,2);    
    % Compute the optical flow for that particular frame.
    optFlow = estimateFlow(optical,rgb2gray(rgbData));
    % Filter pixels by magnitude
    binaryImage = optFlow.Magnitude > 1.0;    
    [y, x] = find(binaryImage);  % x and y are column vectors.
    % Create single conforming 2-D boundary around the points
    j = boundary(x,y,0);
    % Display acquired camera frame 
    imshow(rgbData)       
    
    hold on;
    % Plot boundary lines
    plot(x(j),y(j));
   
    if(isempty(x) == 0 && isempty(y) == 0)
        shape = regionprops(double(binaryImage), 'Centroid');
        %shape.Centroid(1)
       % cent = [mean(x) mean(y)]
        plot (shape.Centroid(1), shape.Centroid(2),'r.','MarkerSize',20);  
    end

    % Save windows content as .png
    if(saveImages)    
        saveas(gcf,['snapshots/image' num2str(nFrames) '.png']);   
    end
  
    hold off;
   % Increment frame count
   nFrames = nFrames + 1;  
   pause(0.01)
end

if(saveImages)    
    makeVideoFromImages(nFrames-1);   
end

% Close figures
close;
% Release camera resource
release(vidDevice);

function makeVideoFromImages(numberOfImages)
    writerObj = VideoWriter([datestr(now,'yyyy-mm-dd__HH-MM') '.mp4'],'MPEG-4');
    writerObj.FrameRate = 15;
    open(writerObj);
    for K = 0 : numberOfImages
      filename = sprintf('snapshots/image%d.png', K);
      thisimage = imread(filename);
      writeVideo(writerObj, thisimage);
    end
    close(writerObj);
end

function optical = calibrateNoiseThreshold(threshold, vidDevice)
    nFrames = 0;
    nonZeroComponents = 0;
    while (nFrames < 10)  
        opticalFlow = opticalFlowLK('NoiseThreshold',threshold); 
        % Acquire single frame from imaging device.
        rawImage = step(vidDevice);  
        % Compute the optical flow for that particular frame.
        optFlow = estimateFlow(opticalFlow,rgb2gray(rawImage));  
        % Count non zero elements (pixels that have magnitude value)
        nonZeroComponents = nonZeroComponents + nnz(optFlow.Magnitude);
    
        nFrames = nFrames + 1;    
    end;
   
    if(nonZeroComponents > 0)
        disp('Calibration in progress');  
        disp(strcat({'LK noiseThreshold increased to'}, {' '}, {num2str(threshold*2)}));
        % Recursive call
        optical = calibrateNoiseThreshold(threshold * 2, vidDevice);
    end      
   
    disp('Calibration finished');    
     
    optical = opticalFlow;
end