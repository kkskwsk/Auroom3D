classdef Simulation3dContext < handle
    %--------------
    %This is a context class for the whole simulation.
    %--------------
    properties (GetAccess = 'private', SetAccess = 'private')
        roomModel;
        sourceModel;
        receiverModel;
        %drawingContext;
        settings;
        distanceThreshold;
        speedOfSound;
        filtersMap;
        
        leftEarFilter;
        rightEarFilter;
        
        hrtf;
    end
    %--------------
    %Public Methods
    %--------------
    methods (Access = 'public')
        function this = Simulation3dContext(numberOfParticles, hrtf)
            %init all properties
            this.initializeFilters();
            this.initSettings();
            
            this.hrtf = hrtf;
            
            this.roomModel = Room3dModel(this.settings.roomModel.vertices, ...
                                         this.settings.roomModel.faces, ...
                                         this.settings.roomModel.materials, ...
                                         this.settings.roomModel.medium);
                                     
            this.sourceModel = Source3dModel(this.settings.sourceModel.positionVector, ...
                                             this.settings.sourceModel.directionAngle.azimuth, ...
                                             this.settings.sourceModel.directionAngle.elevation);
            this.sourceModel.setNumberOfParticles(numberOfParticles);
            
            this.receiverModel = Receiver3dModel(this.settings.receiverModel.positionVector, ...
                                                 this.settings.receiverModel.directionAngle.azimuth, ...
                                                 this.settings.receiverModel.directionAngle.elevation, ...
                                                 this.settings.receiverModel.realSize,...
                                                 this.hrtf);
%             this.drawingContext = Drawing2dContext(this.settings.drawing.canvasSizeX, ... 
%                                                    this.settings.drawing.canvasSizeY, ...
%                                                    this.settings.drawing.lineWidth);
            this.distanceThreshold = this.settings.simulation.distanceThreshold;
            this.speedOfSound = this.settings.simulation.speedOfSound;
        end
        
        
%         function drawScene(this)
%             this.roomModel.draw(this.drawingContext); % funkcje powinny sie nazywac po prostu "draw"
%             this.sourceModel.draw(this.drawingContext);
%             this.receiverModel.draw(this.drawingContext);
%             this.sourceModel.drawRays(this.drawingContext);
%         end
        
%         function showScene(this)
%             figure();
%             imshow(this.drawingContext.getCanvas());
%         end
        
        function start(this)
            this.sourceModel.shootParticles(this);
            this.calcImpulseResponse();
        end
        
%         function result = isImageSourceConsidered(this, particle, receptionNo)
%             reception = particle.getReception(receptionNo);
%             receptionWalls = reception.getWalls();
%             if isempty(receptionWalls)
%                 1;
%             end
%             for i=1:length(this.imageSources)
%                 if isequal(this.imageSources(i).getWalls(), receptionWalls)
%                     result = true;
%                     return;
%                 end
%             end
%             result = false;
%         end
%         
        function calcImpulseResponse(this)
            impulse = [1];
            particles = this.sourceModel.getParticles();
            leftChannel = 0;
            rightChannel = 0;
            imageSourcesCounter = 0;
            allReceptions = Reception.empty(0);
            
            for i = 1:length(particles)
                if particles(i).isReceived()
                    allReceptions = [allReceptions particles(i).getReceptions()];
                    %allReceptions(end + 1) = particles(i).getReceptions();
                end
            end
            
            for i = 1:length(allReceptions)
                rec = allReceptions(i);
                walls = rec.getWalls();
                for j = i+1:length(allReceptions)
                    if isequal(allReceptions(j).getWalls(), walls) && (allReceptions(j).getDistance() ~= 0)
                        allReceptions(j) = Reception(0, 0, 0);
                    end
                end
            end
            leftContainer = Handler.empty(0);%zeros(1, length(particles));
            rightContainer = Handler.empty(0);%zeros(1, length(particles));
            
            for i = 1:length(allReceptions)
                leftContainer(i) = Handler([]);
                rightContainer(i) = Handler([]);
            end
            %allReceptions(allReceptions == 0) = [];
            parfor i = 1:length(allReceptions)
                reception = allReceptions(i);
                if reception.getDistance() == 0
                    continue;
                end
                left = 0;
                right = 0;
                imageSourcesCounter = imageSourcesCounter + 1;
                imageSource = ImageSource3d(reception);
                [leftEarImpulseResponse, rightEarImpulseResponse] = this.receiverModel.binauralize(imageSource, impulse, this);
                left = Dsp.addBuffers(left, leftEarImpulseResponse);
                right = Dsp.addBuffers(right, rightEarImpulseResponse);
                hnd = leftContainer(i);
                hnd.setProperty(left);
                leftContainer(i) = hnd;
                hnd = rightContainer(i);
                hnd.setProperty(right);
                rightContainer(i) = hnd;
                
            end
            
            for i = 1:length(leftContainer);
                leftProp = leftContainer(i).getProperty();
                rightProp = rightContainer(i).getProperty();
                if isempty(leftProp) || isempty(rightProp)
                    continue;
                end
                leftChannel = Dsp.addBuffers(leftChannel, leftProp);
                rightChannel = Dsp.addBuffers(rightChannel, rightProp);
            end
%             
%             parfor i = 1:length(particles)
%                 soundParticle = particles(i);
%                 if soundParticle.isReceived()
%                     receptions = soundParticle.getReceptions();
%                     left = 0;
%                     right = 0;
%                     for j = 1:min(2, length(receptions))%length(receptions)
%                         if this.isImageSourceConsidered(soundParticle, j)
%                             continue;
%                         end
%                         imageSourcesCounter = imageSourcesCounter + 1;
%                         imageSource = ImageSource3d(soundParticle, j);
%                         this.imageSources = [this.imageSources imageSource];
%                         [leftEarImpulseResponse, rightEarImpulseResponse] = this.receiverModel.binauralize(imageSource, impulse, this);
%                         left = Dsp.addBuffers(left, leftEarImpulseResponse);
%                         right = Dsp.addBuffers(right, rightEarImpulseResponse);
%                     end
%                 end
%                 leftContainer(i) = left;
%                 rightContainer(i) = right;
%             end
%             
%             for i = 1:length(leftContainter)
%                 leftChannel = Dsp.addBuffers(leftChannel, leftContainer(i));
%                 rightChannel = Dsp.addBuffers(rightChannel, rightContainer(i));
%             end
            
            fprintf(1, 'Image sources processing time: %d [sec]\n', toc);
            time = 1/this.settings.simulation.sampleRate:1/this.settings.simulation.sampleRate:length(leftChannel)/this.settings.simulation.sampleRate;
            this.leftEarFilter = Filter(1, leftChannel, this.settings.simulation.sampleRate, 'leftEar');
            this.rightEarFilter = Filter(1, rightChannel, this.settings.simulation.sampleRate, 'rightEar');
            figure();
            plot(time, leftChannel);
            title('Left channel IR');
            figure();
            plot(time, rightChannel);
            title('Right channel IR');
            imageSourcesCounter
        end
        
        %Getters
        function roomModel = getRoomModel(this)
            roomModel = this.roomModel;
        end
        
        function receiverModel = getReceiverModel(this)
            receiverModel = this.receiverModel;
        end
        
        function distanceThreshold = getDistanceThreshold(this)
            distanceThreshold = this.distanceThreshold;
        end
        
        function speedOfSound = getSpeedOfSound(this)
            speedOfSound = this.speedOfSound;
        end
        
        function settings = getSettings(this)
            settings = this.settings;
        end
        
        function [leftEarFilter, rightEarFilter] = getFilters(this)
            leftEarFilter = this.leftEarFilter;
            rightEarFilter = this.rightEarFilter;
        end
                
    end
    %--------------
    %Private Methods
    %--------------
    methods (Access = 'private')
        function initSettings(this)
            this.settings.roomModel.vertices = [[50 100 0]; [1250 100 0]; [1250 1600 0]; [50 1600 0]; [50 100 600]; [1250 100 600]; [1250 1600 600]; [50 1600 600]];
            this.settings.roomModel.faces = [1 2 3; 1 3 4; 1 6 2; 1 5 6; 2 6 3; 3 6 7; 3 7 4; 4 7 8; 5 7 6; 5 8 7; 1 4 5; 4 8 5];
            material = Material('wood', [.7 .5 0], this.filtersMap('woodenWall'));
            this.settings.roomModel.materials = [material, ...
                                                material, ...
                                                material, ...
                                                material, ...
                                                material, ...
                                                material, ...
                                                material, ...
                                                material, ...
                                                material, ...
                                                material, ...
                                                material, ...
                                                material];
            this.settings.roomModel.medium = 'air';
            
            this.settings.sourceModel.positionX = 500;
            this.settings.sourceModel.positionY = 1000;
            this.settings.sourceModel.positionZ = 300; %zmieni� podawanie pozycji - w metrach
            this.settings.sourceModel.positionVector = Vec3d(this.settings.sourceModel.positionX, this.settings.sourceModel.positionY, this.settings.sourceModel.positionZ);
            this.settings.sourceModel.directionAngle.elevation = 0; %in degrees
            this.settings.sourceModel.directionAngle.azimuth = 0; 
            %this.settings.sourceModel.realSize = 0.5; %in meters
            
            this.settings.receiverModel.positionX = 500;
            this.settings.receiverModel.positionY = 500;
            this.settings.receiverModel.positionZ = 300;
            this.settings.receiverModel.positionVector = Vec3d(this.settings.receiverModel.positionX, this.settings.receiverModel.positionY, this.settings.receiverModel.positionZ);
            this.settings.receiverModel.directionAngle.elevation = 0;
            this.settings.receiverModel.directionAngle.azimuth = 180; %in degrees
            this.settings.receiverModel.realSize = 2; %in meters
            
            this.settings.simulation.temperature = 21; %Celsius
            this.settings.simulation.speedOfSound = 331.5 + 0.6*this.settings.simulation.temperature; %m/s
            this.settings.simulation.timeThreshold = 0.8; %seconds
            this.settings.simulation.distanceThreshold = this.settings.simulation.timeThreshold * this.settings.simulation.speedOfSound; 
            this.settings.simulation.sampleRate = 44100;
            
            this.settings.dsp.frameLength = 2*4096;
            this.checkSceneSanity();
        end
        
        function initializeFilters(this)
            this.filtersMap = containers.Map('KeyType','char','ValueType','any');
            this.filtersMap('woodenWall') = Filter(1, -0.9, 44100, 'wood'); %[0; 0; 0; 0.1; 0.2; 0.3; 0.2; 0.1; 0; 0; 0]
        end
        
        function checkSceneSanity(this)
            %(canvas size/room position) sanity
            %vertices = this.settings.roomModel.vertices;
            %drawingSettings = this.settings.drawing;
            %for i = 1:2:length(vertices)
            %    if (vertices(i) >= drawingSettings.canvasSizeX) || (vertices(i + 1) >= drawingSettings.canvasSizeY)
            %        error('Scene sanity check failed. There are vertices placed out of the scene.');
            %    end
            %end
            %(room/source position) sanity
            %TO ADD POINT IN POLYGON CHECK
            %(room/receiver position) sanity
            %(receiver/source position) sanity - near field border
        end
    end
    
    methods (Access = 'public', Static = true)
        function hrtf = loadHrtf()
            tic
            hrtf = Hrtf();
            fprintf(1, 'Time of loading hrtf: %d [sec]\n', toc);
        end
        function auralize(filename, leftEarFilter, rightEarFilter)
            frameLength = 4096*2;
            fileReader = dsp.AudioFileReader(filename, 'SamplesPerFrame', frameLength);
            i = info(fileReader);
            if (i.NumChannels ~= 1)
                error('To many channels. Cannot auralize a stereo sound. First convert to mono.');
            end
            
            %TO DO: Check how to choose a device? Speakers/file. It is
            %necessary to choose if the sound should be played or just
            %saved to a new file.
            deviceWriter = audioDeviceWriter('SampleRate', fileReader.SampleRate);
            
            %I assume that both ears' impulse responses are of equal
            %length.
            impulseResponseLength = length(leftEarFilter.getCoeffsB());
            
            if (impulseResponseLength ~= 1)
                overlapLength = impulseResponseLength - 1;
                leftEarOverlap  = zeros(overlapLength, 1);
                rightEarOverlap = zeros(overlapLength, 1);
                
                while ~isDone(fileReader)
                    rightEarOverlap = [rightEarOverlap; zeros(frameLength - overlapLength, 1)];
                    leftEarOverlap = [leftEarOverlap; zeros(frameLength - overlapLength, 1)];
                    chunk = step(fileReader);
                    processedLeftEarChunk = Dsp.filter(chunk, leftEarFilter);
                    processedRightEarChunk = Dsp.filter(chunk, rightEarFilter);
                    chunkToPlay(:,1) = leftEarOverlap(1:frameLength) + processedLeftEarChunk(1:frameLength);
                    chunkToPlay(:,2) = rightEarOverlap(1:frameLength) + processedRightEarChunk(1:frameLength);
                    leftEarOverlap(end+1:end+min(frameLength, overlapLength)) = 0;
                    rightEarOverlap(end+1:end+min(frameLength, overlapLength)) = 0;
                    leftEarOverlap = processedLeftEarChunk(frameLength+1:end) + leftEarOverlap(frameLength+1:end);
                    rightEarOverlap = processedRightEarChunk(frameLength+1:end) + rightEarOverlap(frameLength+1:end);
                    play(deviceWriter, chunkToPlay);
                end
            else
                while ~isDone(fileReader)
                    chunk = step(fileReader);
                    chunkToPlay(:,1) = Dsp.filter(chunk, leftEarFilter);
                    chunkToPlay(:,2) = Dsp.filter(chunk, rightEarFilter);
                    play(deviceWriter, chunkToPlay);
                end
            end
            
        end
    end
end