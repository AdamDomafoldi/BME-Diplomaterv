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
      optical = opticalFlowLK('NoiseThreshold',0.01); 
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
   
   leftImage = optFlow.Magnitude(1:height,1:width / 2 - 1);   
   rightImage = optFlow.Magnitude(1:height, width / 2:width);   
   
   binaryRight = rightImage > 0.2;
   binaryLeft = leftImage > 0.2;
   
   nL = nnz(binaryLeft);
   nR = nnz(binaryRight);
   
   if(nR > 150)
       disp('Jobb oldal')
   end
   
   if(nL > 150)
       disp('Bal oldal')
   end  

   % Display acquired frame 
   imshow(rgbData)   
   hold on   
   
   %plot a separation line
   x = [160, 160]; 
   y = [1, 240]; 
   plot (x, y)  
   % Plot vectors
   plot(optFlow ,'DecimationFactor',[5 5],'ScaleFactor',25)
   
   hold off    
   % Increment frame count
   nFrames = nFrames + 1;  
   pause(0.01)
end

% Close figures
close;
% Release camera resource
release(vidDevice);