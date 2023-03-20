
%Please copy-paste the "Samples" folder in the same directory as this Octave file as such:
% |
% |---sappho_analyser.m
% |---Samples
%       |--Sappho_00XYZ.txt 

clear;
clc;
pkg load signal;
%=====BASIC DEFINITIONS=====
fileName = 'Samples/Sample_00129.txt';
pixelsNum = 128;
pixels = 1:1:pixelsNum;
distanceFromPDA = 3.5; %centimetres (this is the distance between the PDA and the object that is being measured - not the distance between the laser and the PDA)
sensorLength = 0.812; %centimetres
angleMax = rad2deg(atan(sensorLength/distanceFromPDA)); %find the maximum angle (in degrees) between a pixel and the laser pointer
step = 2*angleMax/(pixelsNum); %Δθ per pixel
angles = -(angleMax-step):step:angleMax; %array of 128 angles;

%=====FILE HANDLER====
file = fopen(fileName,'r');
data = dlmread(file, ' ', 4,0); %Ignore the first lines of the file that contain text. Read ONLY numeric data.
fid = fclose(file);

%=====DATA INVERTING & FILTERING===== 
data = abs(data-4096);
n = 10;   % filter order
dataFiltered = filter(ones(n, 1)/n, 1, data); %this is a moving average filter
%=====RESHAPE MATRIX=====
framesNum = size(data,1) / pixelsNum; %Calculate the number of the frames, based on the array size
data = reshape(data,[pixelsNum, framesNum]); %reshape the Nx1 array to a matrix with dimensions "PIXELS x FRAMES"
dataFiltered = reshape(dataFiltered,[pixelsNum, framesNum]);


%=====OVERLAY EVERY FRAME ON A PLOT (UNFILTERED)=====%
figure(1)
hold
title([fileName, ': Repeatability Test: Unfiltered Frames'],'Interpreter', 'none');
xlabel('Pixels');
ylabel('Brightness (a.u.)');
set(gca, "linewidth", 2, "fontsize", 12)
for i=1:framesNum
  temp = data(:,i);
  plot(temp)
  legend
  i++;
endfor

%=====OVERLAY EVERY FRAME ON A PLOT (FILTERED)=====%
figure(2)
hold
title([fileName, ': Repeatability Test: Frames + Moving Average Filter'],'Interpreter', 'none');
xlabel('Pixels');
ylabel('Brightness (a.u.)');
set(gca, "linewidth", 2, "fontsize", 12)
for i=1:framesNum
  temp = dataFiltered(:,i);
  plot(temp)
  legend
  i++;
endfor
%set(gca, "linewidth", 4, "fontsize", 12)
%=====CALCULATE AVERAGE AND MEDIAN SIGNAL=====%
figure(3)
hold
title([fileName, ': Frame Average vs Median: Linear Plot'],'Interpreter', 'none');
xlabel('Pixels');
ylabel('Brightness (a.u.)');
set(gca, "linewidth", 2, "fontsize", 12)
for i=1:pixelsNum
avgData(i) = mean(dataFiltered(i,:)); %If the original signal is too noisy (e.g. because of the light source) replace "data" with "dataFiltered" here
mdnData(i) = median(dataFiltered(i,:));
endfor
plot(avgData)
plot(mdnData)
legend({"Average", "Median"});

%=====NORMALISE DATA=====
figure(4)
hold
title([fileName, ': Frame Average vs Median: Normalised Plot'],'Interpreter', 'none');
xlabel('Pixels');
ylabel('Brightness (normalised)');
set(gca, "linewidth", 2, "fontsize", 12)
normAvg = (avgData - min(avgData)) / ( max(avgData) - min(avgData)); %max value -> 1, min value -> 0
normMdn = (mdnData - min(mdnData)) / ( max(mdnData) - min(mdnData)); 
plot(normAvg)
plot(normMdn)
legend ({"Norm. Average", "Norm. Median"});

%=====MAX-MIN % ERROR CALCULATION=====
figure(5)
hold
title([fileName, ': Max-Min Relative Error: Unfiltered vs Filtered'],'Interpreter', 'none');
xlabel('Pixels');
ylabel('Brightness (a.u.)');
set(gca, "linewidth", 2, "fontsize", 12)
for i=1:pixelsNum %Ignore the first N pixels because the filtering is quirky there
  relError(i) = (max(data(i,:)) - min(data(i,:)) ) / max(data(i,:));
  i++; %calculate the relative min-max error per pixel
endfor

for i=1:pixelsNum-1 %Ignore the first N pixels because the filtering is quirky there
  if i<=n
    relErrorFiltered(i) = 0;
  elseif i>n
  relErrorFiltered(i) = (max(dataFiltered(i,:)) - min(dataFiltered(i,:)) ) / max(dataFiltered(i,:));
  endif
  i++; %calculate the relative min-max error per pixel
endfor
relError = relError * 100;
relErrorFiltered = relErrorFiltered * 100;
plot(relError)
plot(relErrorFiltered)
legend ({"Unfilt. Rel. Error", "Filt. Rel. Error"});
