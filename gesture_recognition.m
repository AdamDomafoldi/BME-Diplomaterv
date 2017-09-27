% Initialization
% Create the Video Device System object.
vidDevice = imaq.VideoDevice('winvideo', 1, 'MJPG_640x480', ...
                             'ROI', [1 1 640 480], ...
                             'ReturnedColorSpace', 'rgb', ...
                             'DeviceProperties.Brightness', 128, ...
                             'DeviceProperties.Sharpness', 5);

% Choose optical flow algorithm and customize it
% returns an optical flow object used to estimate the direction and
opticalFlowType = 'Farneback';

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
while (nFrames<100)     % Process for the first 200 frames.    
   % Acquire single frame from imaging device.
   rgbData = step(vidDevice);    
   % Compute the optical flow for that particular frame.
   optFlow = estimateFlow(optical,rgb2gray(rgbData));
   % Display acquired frame
   imshow(rgbData)   
   hold on
   % Plot vectors
   plot(optFlow ,'DecimationFactor',[5 5],'ScaleFactor',25)
   hold off    
   % Increment frame count
   nFrames = nFrames + 1;  
   pause(0.01)
end

% Release
% Here you call the release method on the System objects to close any open 
% files and devices.
release(vidDevice);