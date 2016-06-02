clear all;
clear classes;
close all;

addpath ../config;
configInitPath;

simulationContext = Simulation3dContext();

simulationContext.start();
%simulationContext.drawScene();
%simulationContext.showScene();

%inputSound = Sound('am.flac', 16, 0, 0);
%outputSound = simulationContext.auralize(inputSound);
%outputSound.play(0);
simulationContext.auralize('multimedia/used/monodp.wav');

configCleanPath;    
rmpath config;