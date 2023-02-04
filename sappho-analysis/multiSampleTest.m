%Please copy-paste the "Samples" folder in the same directory as this Octave file as such:
% |
% |---sappho_analyser.m
% |---Samples
%       |--Sappho_00XYZ.txt 

clear;
clc;
pkg load signal;

%=====BASIC DEFINITIONS=====
fileName = 'Samples/Sappho_00108.txt';
fileName2 = 'Samples/Sappho_00120.txt';
fileName3 = 'Samples/Sappho_00117.txt';




pixelsNum = 1500;
pixels = 1:1:pixelsNum;
distanceFromPDA = 5; %centimetres (this is the distance between the PDA and the object that is being measured - not the distance between the laser and the PDA)
sensorLength = 1.1; %centimetres
angleMax = rad2deg(atan(sensorLength/distanceFromPDA)); %find the maximum angle (in degrees) between a pixel and the laser pointer
step = 2*angleMax/(pixelsNum); %Δθ per pixel
angles = -(angleMax-step):step:angleMax; %aq array of 1500 angles;
figureCntr = 1;

%=====FILE HANDLER====
file = fopen(fileName,'r');
data = dlmread(file, ' ', 4,0); %Ignore the first lines of the file that contain text. Read ONLY numeric data.
file = fclose(file);

file = fopen(fileName2,'r');
data2 = dlmread(file, ' ', 4,0); %Ignore the first lines of the file that contain text. Read ONLY numeric data.
file = fclose(file);

file = fopen(fileName3,'r');
data3 = dlmread(file, ' ', 4,0); %Ignore the first lines of the file that contain text. Read ONLY numeric data.
file = fclose(file);

%file = fopen(fileName4,'r');
%data4 = dlmread(file, ' ', 4,0); %Ignore the first lines of the file that contain text. Read ONLY numeric data.
%file = fclose(file);

data = abs(data-4096);
data2 = abs(data2-4096);
data3 = abs(data3-4096);
%data4 = abs(data4-4096);

n = 20;   % filter order
dataFiltered = filter(ones(n, 1)/n, 1, data); %this is a moving average filter
dataFiltered2 = filter(ones(n, 1)/n, 1, data2);
dataFiltered3 = filter(ones(n, 1)/n, 1, data3);  
%dataFiltered4 = filter(ones(n, 1)/n, 1, data4); 


framesNum = size(data,1) / pixelsNum; %Calculate the number of the frames, based on the array size
data = reshape(data,[pixelsNum, framesNum]); %reshape the Nx1 array to a matrix with dimensions "PIXELS x FRAMES"
data2 = reshape(data2,[pixelsNum, framesNum]);
data3 = reshape(data3,[pixelsNum, framesNum]);
%data4 = reshape(data4,[pixelsNum, framesNum]); 
%reshape the Nx1 array to a matrix with dimensions "PIXELS x FRAMES"

dataFiltered = reshape(dataFiltered,[pixelsNum, framesNum]); %reshape the Nx1 array to a matrix with dimensions "PIXELS x FRAMES"
dataFiltered2 = reshape(dataFiltered2,[pixelsNum, framesNum]);
dataFiltered3 = reshape(dataFiltered3,[pixelsNum, framesNum]);
%dataFiltered4 = reshape(dataFiltered4,[pixelsNum, framesNum]);

%=====OVERLAY EVERY FRAME ON A PLOT (UNFILTERED)=====%
figure(1)
hold
title([fileName, ': Repeatability Test: Unfiltered'],'Interpreter', 'none');
xlabel('Pixels');
ylabel('Brightness (a.u.)');
set(gca, "linewidth", 2, "fontsize", 12)
for i=2:framesNum
  temp = data(:,i);
  plot(temp)
  temp2 = data2(:,i);
  plot(temp2)
  temp3 = data3(:,i);
  plot(temp3)
  %temp4 = data4(:,i);
  %plot(temp4)
 % xlim([0 1500])
 legend({"Cylindr. Unpol", "Cylindr. Pol.", "Prism Unpol.", "Prism Pol."});
  i++;
endfor

figure(2)
hold
title([fileName, ': Repeatability Test: Unfiltered'],'Interpreter', 'none');
xlabel('Pixels');
ylabel('Brightness (a.u.)');
set(gca, "linewidth", 2, "fontsize", 12)
for i=2:framesNum
  temp = dataFiltered(:,i);
  plot(temp)
  temp2 = dataFiltered2(:,i);
  plot(temp2)
  temp3 = dataFiltered3(:,i);
  plot(temp3)
  %temp4 = dataFiltered4(:,i);
  %plot(temp4)
 % xlim([0 1500])
  i++;
endfor

figure(3)
hold
title(['9.6ŠÌm Frame Median: Linear Plot'],'Interpreter', 'none');
xlabel('Pixels');
ylabel('Brightness (a.u.)');
set(gca, "linewidth", 2, "fontsize", 12)
for i=1:pixelsNum
mdnData(i) = median(dataFiltered(i,:));
mdnData2(i) = median(dataFiltered2(i,:));
mdnData3(i) = median(dataFiltered3(i,:));
%mdnData4(i) = median(dataFiltered4(i,:));
endfor
plot(mdnData)
plot(mdnData2)
plot(mdnData3)
%plot(mdnData4)
legend({"Cylindr. Unpol.", "Prism. Unpol.", "Prism Pol.", "Cylindr Pol."});

figure(4)
hold
title(['Multiple particle sizes, Frame Median: Normalised Plot'],'Interpreter', 'none');
xlabel('Angle (Degrees)');
ylabel('Brightness (normalised)');
set(gca, "linewidth", 2, "fontsize", 12)
normMdn = (mdnData - min(mdnData)) / ( max(mdnData) - min(mdnData)); 
normMdn2 = (mdnData2 - min(mdnData2)) / ( max(mdnData2) - min(mdnData2)); 
normMdn3 = (mdnData3 - min(mdnData3)) / ( max(mdnData3) - min(mdnData3)); 
%normMdn4 = (mdnData4 - min(mdnData4)) / ( max(mdnData4) - min(mdnData4)); 

plot(angles,normMdn)
plot(angles,normMdn2)
plot(angles,normMdn3)
%plot(angles,normMdn4)
%xlim([-22 22])
legend({"9.6μm, 1ρ, 100μs, Unpol.", "9.6μm, 0.1ρ 20μs, Pol.", "9.6μm, 0.1ρ, 20μs, Pol.", "4.8μm, 100μs, Pol."});
