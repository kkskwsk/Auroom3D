classdef Simulation3dContext < handle
    properties (GetAccess = 'private', SetAccess = 'private')
        settings;
        distanceThreshold;
        speedOfSound;
        
        roomModel;
        sourceModel;
        receiverModel;
        materialsMap;
        hrtf;
        
        leftEarFilter;
        rightEarFilter;
        
        recalcGeometryFlag      =   true;
        recalcIrFlag            =   true;
        attenuationOnHead       =   false; 
        pauseAuralization       =   false;
        stopAuralization        =   false;
        isAuralizationRunning   =   false;
        isMaterialSet           =   false;
    end
    
    methods (Access = 'public')
        function this = Simulation3dContext()
            this.initSettings();
            this.distanceThreshold  =   []; 
            this.speedOfSound       =   this.settings.simulation.speedOfSound;
            
            this.roomModel      =   [];
            this.sourceModel    =   [];
            this.receiverModel  =   [];
            this.materialsMap   =   containers.Map('KeyType', 'char', 'ValueType', 'any');
            this.hrtf           =   Hrtf.loadHrtf();
        end
        
        function createRoomModel(this, vertices, faces)
            try
                this.roomModel  =   Room3dModel(vertices, faces);
            catch ME
                this.roomModel  =   [];
                throw ME;
            end
        end
        function createSourceModel(this, positionVector)
            this.sourceModel    =   Source3dModel(positionVector);
        end
        function createReceiverModel(this, positionVector, azimuth, size)
            this.receiverModel  =   Receiver3dModel(positionVector, azimuth, size, this.hrtf);
        end
        
        function setParticlesNumber(this, numberOfParticles)
            if ~isempty(this.sourceModel) 
                this.sourceModel.setNumberOfParticles(numberOfParticles);
            else
                msgID       =   'SIMCTX:EmptySourceModel';
                msg         =   'Initialize source model first!';
                exception   =   MException(msgID, msg);
                throw(exception);
            end
        end
       
        function setIrLength(this, time)
            this.distanceThreshold  =   time * this.settings.simulation.speedOfSound;
        end
        function setAttenuationOnHead(this, value)
            this.attenuationOnHead  =   value;
        end
        
        function addMaterial(this, material)
            this.materialsMap(material.getName())   =   material;
        end
        function deleteMaterial(this, name)
            this.materialsArray(name)   =   [];
        end
        function setMaterial(this, name)
            if ~isempty(this.roomModel)
                this.roomModel.setWallMaterial(this.materialsMap(name));
                this.isMaterialSet  =   true;
            else
                msgID       =   'SIMCTX:EmptyRoomModel';
                msg         =   'Initialize room model first!';
                exception   =   MException(msgID, msg);
                throw(exception);
            end
        end
        
        function setRecalcGeometryFlag(this, value)
            this.recalcGeometryFlag     =   value;
        end
        function setRecalcIrFlag(this, value)
            this.recalcIrFlag   =   value;
        end
        
        function start(this)
            if isempty(this.roomModel)
                msgID       =   'SIMCTX:EmptyRoomModel';
                msg         =   'Initialize room first!';
                exception   =   MException(msgID, msg);
                throw(exception);
            end
            
            if isempty(this.sourceModel)
                msgID       =   'SIMCTX:EmptySrcModel';
                msg         =   'Initialize source first!';
                exception   =   MException(msgID, msg);
                throw(exception);
            end
            
            if isempty(this.receiverModel)
                msgID       =    'SIMCTX:EmptyRecModel';
                msg         =    'Initialize receiver first!';
                exception   =    MException(msgID, msg);
                throw(exception);
            end
            
            if isempty(this.distanceThreshold)
                msgID       =    'SIMCTX:EmptyThreshold';
                msg         =    'Impulse response length is not set yet.';
                exception   =    MException(msgID, msg);
                throw(exception);
            end
            
            if ~this.isMaterialSet
                msgID       =    'SIMCTX:EmptyMaterial';
                msg         =    'Room material is not set yet.';
                exception   =    MException(msgID, msg);
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
            this.recalcGeometryFlag     =   false;
            this.recalcIrFlag           =   false;
        end
        
        function calcImpulseResponse(this)
            impulse                 =   [1];
            particles               =   this.sourceModel.getParticles();
            leftChannel             =   0;
            rightChannel            =   0;
            imageSourcesCounter     =   0;
            allReceptions           =   Reception.empty(0);
            
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
            
            h       =   waitbar(0, 'Calculating binaural room impulse response.');
            recNum  =   length(allReceptions);
            step    =   0;
            
            for i = 1:recNum
                left        =   0;
                right       =   0;
                step        =   step + 1;
                reception   =   allReceptions(i);
                waitbar(step/recNum);
                
                if reception.getDistance() == 0
                    continue;
                end
                
                imageSourcesCounter     =   imageSourcesCounter + 1;
                imageSource             =   ImageSource3d(reception);
                [leftEarImpulseResponse, rightEarImpulseResponse] = this.receiverModel.binauralize(imageSource, impulse, this);
                
                left    =   Dsp.addBuffers(left, leftEarImpulseResponse);
                right   =   Dsp.addBuffers(right, rightEarImpulseResponse);
                
                hnd     =   leftContainer(i);
                hnd.setProperty(left);
                leftContainer(i)    =   hnd;
                
                hnd     =   rightContainer(i);
                hnd.setProperty(right);
                rightContainer(i)   =   hnd;
                
            end
            
            close(h);
            
            for i = 1:length(leftContainer);
                leftProp    =   leftContainer(i).getProperty();
                rightProp   =   rightContainer(i).getProperty();
                
                if isempty(leftProp) || isempty(rightProp)
                    continue;
                end
                
                leftChannel     =   Dsp.addBuffers(leftChannel, leftProp);
                rightChannel    =   Dsp.addBuffers(rightChannel, rightProp);
            end
            
            time                    =   1/this.settings.auralization.samplingRate:(1/this.settings.auralization.samplingRate):(length(leftChannel)/this.settings.auralization.samplingRate);
            this.leftEarFilter      =   Filter(1, leftChannel, this.settings.auralization.samplingRate);
            this.rightEarFilter     =   Filter(1, rightChannel, this.settings.auralization.samplingRate);
            
            figure(1);
            plot(time, leftChannel);
            title('Left channel IR');
            figure(2);
            plot(time, rightChannel);
            title('Right channel IR');
            
            message     =   sprintf('Image sources number: %d', imageSourcesCounter);
            msgbox(message, 'Info');
        end
        
        function auralize(this, filename, frameLength, leftEarFilter, rightEarFilter, writeToFile)
            this.stopAuralization       =   false;
            this.isAuralizationRunning  =   true;
            auralizedFilename           =   'auralized.wav';
            path                        =   sprintf('../sounds/%s',filename);
            fileReader                  =   dsp.AudioFileReader(path, 'SamplesPerFrame', frameLength);
            i                           =   info(fileReader);
            
            if (i.NumChannels ~= 1)
                error('To many channels. Cannot auralize a stereo sound. First convert to mono.');
            end
            
            if ~writeToFile
                writer  =   audioDeviceWriter('SampleRate', fileReader.SampleRate);
            else
                writer      =   dsp.AudioFileWriter(auralizedFilename, 'SampleRate', 44100);
                h           =   dir(path);
                fileSize    =   h.bytes/2;
                wb          =   waitbar(0, sprintf('Auralizing and writing to file %s', auralizedFilename));
                wbstep      =   0;
            end
            
            impulseResponseLength   =   length(leftEarFilter.getCoeffsB());
            
            if (impulseResponseLength ~= 1)
                overlapLength       =   impulseResponseLength - 1;
                leftEarOverlap      =   zeros(overlapLength, 1);
                rightEarOverlap     =   zeros(overlapLength, 1);
                
                while ~isDone(fileReader)
                    rightEarOverlap     =   [rightEarOverlap; zeros(frameLength - overlapLength, 1)];
                    leftEarOverlap      =   [leftEarOverlap; zeros(frameLength - overlapLength, 1)];
                    
                    if this.pauseAuralization
                        chunk   =   zeros(1, frameLength);
                    else
                        chunk   =   step(fileReader);
                    end
                    
                    processedLeftEarChunk   =   Dsp.filter(chunk, leftEarFilter);
                    processedRightEarChunk  =   Dsp.filter(chunk, rightEarFilter);
                    chunkToPlay(:,1)        =   leftEarOverlap(1:frameLength) + processedLeftEarChunk(1:frameLength);
                    chunkToPlay(:,2)        =   rightEarOverlap(1:frameLength) + processedRightEarChunk(1:frameLength);
                    
                    leftEarOverlap(end+1:end+min(frameLength, overlapLength))   =   0;
                    rightEarOverlap(end+1:end+min(frameLength, overlapLength))  =   0;
                    
                    leftEarOverlap      =   processedLeftEarChunk(frameLength+1:end) + leftEarOverlap(frameLength+1:end);
                    rightEarOverlap     =   processedRightEarChunk(frameLength+1:end) + rightEarOverlap(frameLength+1:end);
                    
                    if writeToFile
                        wbstep  =   wbstep + frameLength;
                        waitbar(wbstep/fileSize);
                        step(writer, chunkToPlay);
                    else
                        play(writer, chunkToPlay);
                    end
                end
            else
                while ~isDone(fileReader)
                    chunk               =   step(fileReader);
                    chunkToPlay(:,1)    =   Dsp.filter(chunk, leftEarFilter);
                    chunkToPlay(:,2)    =   Dsp.filter(chunk, rightEarFilter);
                    
                    if writeToFile
                        wbstep = wbstep + frameLength;
                        waitbar(wbstep/fileSize);
                        step(writer, chunkToPlay);
                    else
                        play(writer, chunkToPlay);
                    end
                end
            end
            
            if writeToFile
                close(wb);
            end
            
            release(fileReader);
            release(writer);
            
            this.isAuralizationRunning  =   false;
        end
        
        function filename = saveBinauralImpulseResponseToFile(this)
            if isempty(this.leftEarFilter) || isempty(this.rightEarFilter)
                msgID       =   'SIMCTX:EmptyFilters';
                msg         =   'No impulse responses found. Simulate first, then save.';
                exception   =   MException(msgID, msg);
                throw(exception);
            end
            
            filename        =   'impulseresp.wav';
            leftBuf         =   this.leftEarFilter.getCoeffsB();
            rightBuf        =   this.rightEarFilter.getCoeffsB();
            finalBuf(:, 1)  =   leftBuf;
            finalBuf(:, 2)  =   rightBuf;
            
            audiowrite(filename, finalBuf, this.leftEarFilter.getFs());
        end
        
        %Getters
        function roomModel = getRoomModel(this)
            roomModel           =   this.roomModel;
        end
        
        function receiverModel = getReceiverModel(this)
            receiverModel       =   this.receiverModel;
        end
        
        function distanceThreshold = getDistanceThreshold(this)
            distanceThreshold   =   this.distanceThreshold;
        end
        
        function speedOfSound = getSpeedOfSound(this)
            speedOfSound        =   this.speedOfSound;
        end
        
        function settings = getSettings(this)
            settings            =   this.settings;
        end
        
        function result = isAuralRunning(this)
            result              =   this.isAuralizationRunning;
        end
        
        function [leftEarFilter, rightEarFilter] = getFilters(this)
            leftEarFilter   =   this.leftEarFilter;
            rightEarFilter  =   this.rightEarFilter;
        end
        
        function setFilters(this, filename)
            [buffers, fs]   =   audioread(filename);
            
            if fs ~= this.settings.auralization.samplingRate
                msgID       =   'SIMCTX:BadSamplingRate';
                message     =   sprintf('You should use a file with sampling rate of %d Hz', this.settings.auralization.samplingRate);
                exception   =   MException(msgID, message);
                throw(exception);
            end
            
            this.leftEarFilter      =   Filter(1, buffers(:,1), fs);
            this.rightEarFilter     =   Filter(1, buffers(:,2), fs);
        end
    end
    
    methods (Access = 'private')
        function initSettings(this)
            this.settings.auralization.samplingRate     =   44100;                                              %Hz
            this.settings.simulation.temperature        =   21;                                                 %Celsius
            this.settings.simulation.speedOfSound       =   331.5 + 0.6*this.settings.simulation.temperature;   %m/s
        end
    end
end