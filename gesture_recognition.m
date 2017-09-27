% Better use the existing camera object if it was used previously but the process
% was aborted and it still exists.
if exist('vidDevice', 'var') == 0   
   % Initialization
   % Create the Video Device System object.
   vidDevice = imaq.VideoDevice('winvideo', 1, 'MJPG_640x480', ...
                             'ROI', [1 1 640 480], ...
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
   rgbData = step(vidDevice);    
   % Compute the optical flow for that particular frame.
   optFlow = estimateFlow(optical,rgb2gray(rgbData));
   %iterator = 0;
   %for i = 1:numel(optFlow.Orientation)
   % element =  optFlow.Orientation(i);
   % if(element)>1
   %     iterator = iterator + 1;
   % end
  % end
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

% Close figures
close;
% Release camera resource
release(vidDevice);