clear all
close all
clear classes

addpath ../config;
configInitPath;

%Create a receiver
commonX = 300;
commonZ = 300;
recPos = Vec3d(commonX, 200, commonZ);
recRealSize = 0.5;
receiverModel = Receiver3dModel(recPos, 0, 0, recRealSize);
%

%Create an Image Source
imageSource = ImageSource3d(0, 0);
%

%Create an impulse
impulse = [1];

[left, right] = receiverModel.binauralize(imageSource, impulse);
leftChannel = left;
rightChannel = right;
time = 1/44100:1/44100:length(leftChannel)/44100;
leftEarFilter = Filter(1, leftChannel, 44100, 'leftEar');
rightEarFilter = Filter(1, rightChannel, 44100, 'rightEar');
figure();
plot(time, leftChannel);
title('Left channel IR');
figure();
plot(time, rightChannel);
title('Right channel IR');

SimulationContext3d.auralize('monodp.mp3', leftEarFilter, rightEarFilter);

