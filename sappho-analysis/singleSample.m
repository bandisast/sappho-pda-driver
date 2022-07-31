%Please copy-paste the "Samples" folder in the same directory as this Octave file as such:
% |
% |---sappho_analyser.m
% |---Samples
%       |--Sappho_00XYZ.txt 

clear;
clc;
pkg load signal;
%=====BASIC DEFINITIONS=====
pixelsNum = 1500;
pixels = 1:1:pixelsNum;

%=====FILE HANDLER====
file = fopen('Samples/Sappho_00068.txt','r');
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
for i=1:framesNum
  temp = data(:,i);
  hold on
  plot(temp)
  legend
  i++;
endfor

%=====OVERLAY EVERY FRAME ON A PLOT (FILTERED)=====%
figure(2)
for i=1:framesNum
  temp = dataFiltered(:,i);
  hold on
  plot(temp)
  legend
  i++;
endfor

%=====CALCULATE AVERAGE AND MEDIAN SIGNAL=====%
figure(3)
for i=1:pixelsNum
avgData(i) = mean(data(i,:)); %If the original signal is too noisy (e.g. because of the light source) replace "data" with "dataFiltered" here
mdnData(i) = median(data(i,:));
endfor
plot(avgData)
hold
plot(mdnData)

%TODO: value normaliser, max-min error calculation, beautify graphs, add "angle" as an axis,