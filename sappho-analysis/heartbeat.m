%Please copy-paste the "Samples" folder in the same directory as this Octave file as such:
% |
% |---sappho_analyser.m
% |---Samples
%       |--Sappho_00XYZ.txt 

clear;
clc;
pkg load signal;
%=====BASIC DEFINITIONS=====
fileName = 'Samples/Sappho_00131.txt';
pixelsNum = 1500;
pixels = 1:1:pixelsNum;
distanceFromPDA = 3.5; %centimetres (this is the distance between the PDA and the object that is being measured - not the distance between the laser and the PDA)
sensorLength = 1.1; %centimetres
angleMax = rad2deg(atan(sensorLength/distanceFromPDA)); %find the maximum angle (in degrees) between a pixel and the laser pointer
step = 2*angleMax/(pixelsNum); %Δθ per pixel
angles = -(angleMax-step):step:angleMax; %aq array of 1500 angles;
frstep = 0.0666:0.0666:4.4666;
%=====FILE HANDLER====
file = fopen(fileName,'r');
data = dlmread(file, ' ', 4,0); %Ignore the first lines of the file that contain text. Read ONLY numeric data.
file = fclose(file);

%=====DATA INVERTING & FILTERING===== 
%data = abs(data-4096);
n = 10;   % filter order
dataFiltered = filter(ones(n, 1)/n, 1, data); %this is a moving average filter

%plot(frstep,data)
%=====RESHAPE MATRIX=====
framesNum = size(data,1) / pixelsNum; %Calculate the number of the frames, based on the array size
data = reshape(data,[pixelsNum, framesNum]); %reshape the Nx1 array to a matrix with dimensions "PIXELS x FRAMES"
%dataFiltered = reshape(dataFiltered,[pixelsNum, framesNum]);


%=====OVERLAY EVERY FRAME ON A PLOT (UNFILTERED)=====%


figure(2)
hold
title([fileName, ': Heart Rate Experiment'],'Interpreter', 'none');
xlabel('Time (seconds)');
ylabel('Brightness (a.u.)');
set(gca, "linewidth", 2, "fontsize", 12)
for i=1:framesNum
  temp(i) = mean(data(:,i));
  i++;
endfor

  plot(frstep,temp)
  legend
