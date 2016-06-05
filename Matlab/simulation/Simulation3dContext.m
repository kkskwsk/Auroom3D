classdef Simulation3dContext < handle
    %--------------
    %This is a context class for the whole simulation.
    %--------------
    properties (GetAccess = 'private', SetAccess = 'private')
        roomModel;
        sourceModel;
        receiverModel;
        settings;
        distanceThreshold;
        speedOfSound;
        materialsMap;
        %filtersMap;
        
        leftEarFilter;
        rightEarFilter;
        
        recalcGeometryFlag = true;
        recalcIrFlag = true;
        attenuationOnHead = false; 
        pauseAuralization = false;
        stopAuralization = false;
        isAuralizationRunning = false;
        
        hrtf;
    end
    %--------------
    %Public Methods
    %--------------
    methods (Access = 'public')
        function this = Simulation3dContext()
            %this.initializeFilters();
            this.initSettings();
            this.hrtf = Hrtf.loadHrtf();
            this.roomModel = [];
            this.sourceModel = [];
            this.receiverModel = [];
            this.materialsMap = containers.Map('KeyType', 'char', 'ValueType', 'any');
            %Simulation settings class is necessary
            this.distanceThreshold = [];
            this.speedOfSound = this.settings.simulation.speedOfSound;
        end
       
        function setAttenuationOnHead(this, value)
            this.attenuationOnHead = value;
        end
        
        function setIrLength(this, time)
            this.distanceThreshold = time * this.settings.simulation.speedOfSound;
        end
        
        function setParticlesNumber(this, numberOfParticles)
            if ~isempty(this.sourceModel) 
                this.sourceModel.setNumberOfParticles(numberOfParticles);
            else
                msgID = 'SIMCTX:EmptySourceModel';
                msg = 'Initialize source model first!';
                exception = MException(msgID, msg);
                throw(exception);
            end
        end
        
        function addMaterial(this, material)
            this.materialsMap(material.getName()) = material;
        end
        
        function deleteMaterial(this, name)
            this.materialsArray(name) = [];
        end
        
        function setMaterial(this, name)
            if ~isempty(this.roomModel)
                this.roomModel.setWallMaterial(this.materialsMap(name));
            else
                msgID = 'SIMCTX:EmptyRoomModel';
                msg = 'Initialize room model first!';
                exception = MException(msgID, msg);
                throw(exception);
            end
        end
            
        
        function createRoomModel(this, vertices, faces)
            try
                this.roomModel = Room3dModel(vertices, faces);
            catch ME
                this.roomModel = [];
                throw ME;
            end
        end
        
        function createSourceModel(this, positionVector)
            this.sourceModel = Source3dModel(positionVector);
        end
        
        function createReceiverModel(this, positionVector, azimuth, realSize)
            this.receiverModel = Receiver3dModel(positionVector, azimuth, realSize, this.hrtf);
        end
        
        function setRecalcGeometryFlag(this, value)
            this.recalcGeometryFlag = value;
        end
        
        function setRecalcIrFlag(this, value)
            this.recalcIrFlag = value;
        end
        
        function start(this)
            if isempty(this.sourceModel)
                msgID = 'SIMCTX:EmptySrcModel';
                msg = 'Initialize source first!';
                exception = MException(msgID, msg);
                throw(exception);
            end
            
            if this.recalcGeometryFlag
                try
                    this.sourceModel.shootParticles(this);
                catch ME
                    throw(ME);
                end
            end
            this.calcImpulseResponse();
            this.recalcGeometryFlag = false;
            this.recalcIrFlag = false;
        end
        
        function calcImpulseResponse(this)
            impulse = [1];
            particles = this.sourceModel.getParticles();
            leftChannel = 0;
            rightChannel = 0;
            imageSourcesCounter = 0;
            allReceptions = Reception.empty(0);
            
            if this.attenuationOnHead
                for i = 1:length(particles)
                    if particles(i).isReceived()
                        allReceptions = [allReceptions particles(i).getReception(1)];
                    end
                end
            else
                for i = 1:length(particles)
                    if particles(i).isReceived()
                        allReceptions = [allReceptions particles(i).getReceptions()];
                        %allReceptions(end + 1) = particles(i).getReceptions();
                    end
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
            %parfor
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
            time = 1/44100:1/44100:length(leftChannel)/44100;
            this.leftEarFilter = Filter(1, leftChannel, 44100);
            this.rightEarFilter = Filter(1, rightChannel, 44100);
            figure();
            plot(time, leftChannel);
            title('Left channel IR');
            figure();
            plot(time, rightChannel);
            title('Right channel IR');
            imageSourcesCounter
        end
        
        function stopAural(this)
            this.stopAuralization = true;
        end
        
        function pauseAural(this)
            this.pauseAuralization = true;
        end
        
        function resumeAural(this)
            this.pauseAuralization = false;
        end
        
        function auralize(this, filename, frameLength, leftEarFilter, rightEarFilter)
            this.stopAuralization = false;
            fileReader = dsp.AudioFileReader(filename, 'SamplesPerFrame', frameLength);
            i = info(fileReader);
            this.isAuralizationRunning = true;
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
                
                while ~isDone(fileReader) && (~this.stopAuralization)
                    rightEarOverlap = [rightEarOverlap; zeros(frameLength - overlapLength, 1)];
                    leftEarOverlap = [leftEarOverlap; zeros(frameLength - overlapLength, 1)];
                    if this.pauseAuralization
                        chunk = zeros(1, frameLength);
                    else
                        chunk = step(fileReader);
                    end
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
                while ~isDone(fileReader) && (~this.stopAuralization)
                    if this.pauseAuralization
                        chunk = zeros(1, frameLength);
                    else
                        chunk = step(fileReader);
                    end
                    chunkToPlay(:,1) = Dsp.filter(chunk, leftEarFilter);
                    chunkToPlay(:,2) = Dsp.filter(chunk, rightEarFilter);
                    play(deviceWriter, chunkToPlay);
                end
            end
            
            this.isAuralizationRunning = false;
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
        
        function result = isAuralRunning(this)
            result = this.isAuralizationRunning;
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
            %this.settings.roomModel.vertices = [[50 100 0]; [1250 100 0]; [1250 1600 0]; [50 1600 0]; [50 100 600]; [1250 100 600]; [1250 1600 600]; [50 1600 600]];
            %this.settings.roomModel.faces = [1 2 3; 1 3 4; 1 6 2; 1 5 6; 2 6 3; 3 6 7; 3 7 4; 4 7 8; 5 7 6; 5 8 7; 1 4 5; 4 8 5];
            %material = Material('wood', this.filtersMap('woodenWall'));
%             this.settings.roomModel.materials = [material, ...
%                                                 material, ...
%                                                 material, ...
%                                                 material, ...
%                                                 material, ...
%                                                 material, ...
%                                                 material, ...
%                                                 material, ...
%                                                 material, ...
%                                                 material, ...
%                                                 material, ...
%                                                 material];
            
%             this.settings.sourceModel.positionX = 500;
%             this.settings.sourceModel.positionY = 1000;
%             this.settings.sourceModel.positionZ = 300; %zmieniæ podawanie pozycji - w metrach
%             this.settings.sourceModel.positionVector = Vec3d(this.settings.sourceModel.positionX, this.settings.sourceModel.positionY, this.settings.sourceModel.positionZ);
            
%             this.settings.receiverModel.positionX = 500;
%             this.settings.receiverModel.positionY = 500;
%             this.settings.receiverModel.positionZ = 300;
%             this.settings.receiverModel.positionVector = Vec3d(this.settings.receiverModel.positionX, this.settings.receiverModel.positionY, this.settings.receiverModel.positionZ);
%             this.settings.receiverModel.directionAngle.azimuth = 180; %in degrees
%             this.settings.receiverModel.realSize = 1; %in meters
            
            this.settings.simulation.temperature = 21; %Celsius
            this.settings.simulation.speedOfSound = 331.5 + 0.6*this.settings.simulation.temperature; %m/s
            
        end
        
        %function initializeFilters(this)
        %    this.filtersMap = containers.Map('KeyType','char','ValueType','any');
        %    this.filtersMap('woodenWall') = Filter(1, -0.9, 44100);%, 'wood'); %[0; 0; 0; 0.1; 0.2; 0.3; 0.2; 0.1; 0; 0; 0]
        %end
        
        
        
    end
end