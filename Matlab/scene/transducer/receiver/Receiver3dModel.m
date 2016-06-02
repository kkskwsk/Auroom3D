classdef Receiver3dModel < handle %mog�oby dziedziczy� po Transducer
    %--------------
    % Short description
    %--------------
    properties (GetAccess = 'private', SetAccess = 'private')
        positionVector;
        shape;
        azimuthDirectionAngle; %in degrees
        elevationDirectionAngle;
        realSize;
        hrtf;
        %freqResponse;
    end
    %--------------
    %Constants
    %--------------
    %-----------------------------------------------------------
    %--------------
    %Public Methods
    %--------------
    methods (Access = 'public')
        %Constructor
        function this = Receiver3dModel(positionVector, azimuthDirectionAngle, elevationDirectionAngle, realSize)
            this.positionVector = positionVector;
            this.azimuthDirectionAngle = azimuthDirectionAngle;
            this.elevationDirectionAngle = elevationDirectionAngle;
            this.realSize = realSize;
            size = calcSizeInPixels(this.realSize);
            radius = size/2;
            this.shape = Sphere3d(positionVector, radius);
            tic
            this.hrtf = Hrtf(this);
            fprintf(1, 'Time of loading HRTF: %d [sec]', toc);
        end
        
        function [isTrue, len] = intersect(this, ray)
            [isTrue, len] = ray.intersectSphere(this.shape);
        end
        
        function [leftEarFilter, rightEarFilter] = interpolateHrtf(this, imageSource)
            headPositionVector = this.getPositionVector();
            [leftEarFilter, rightEarFilter] = this.hrtf.interpolate(headPositionVector, imageSource);
        end
        
        %function angle = findRelativeAngle(this, point)
        %    dirVec = point - this.getShape().getCenter();
        %    angle = (180/pi) * atan(dirVec.getY()/dirVec.getX());
        %    if (dirVec.getX() < 0)
        %        angle = angle + 180;
        %    end
        %    angle = angle - this.getDirectionAngle();
        %end
        
        function distance = calcDistanceFromImageSource(this, imageSource)
            imageSourcePosition = imageSource.getPositionVector();
            imageSourceToReceiverVec = this.positionVector - imageSourcePosition;
            distance = calcSizeInMeters(imageSourceToReceiverVec.getLength());
        end
        
        function [leftEarImpulseResponse, rightEarImpulseResponse] = binauralize(this, imageSource, impulse, simulationContext)
            %filtracja zwi�zana z odbiciami od �cian
            %tic
            filteredBuffer = impulse * imageSource.getWallFilter().getCoeffsB();
            %filteredBuffer = Dsp.filter(impulse, imageSource.getWallFilter());
            %fprintf(1, 'Przetwarzanie odbicia od �cian: %d [sec]\n', toc);
            
            %dodane op�nienie
            %tic
            distance = this.calcDistanceFromImageSource(imageSource);
            delayTime = distance / simulationContext.getSpeedOfSound();
            delaySamples = round(delayTime * simulationContext.getSettings().simulation.sampleRate);
            filteredBuffer = delay(filteredBuffer, delaySamples);
            %fprintf(1, 'Przetwarzanie op�nienia: %d [sec]\n', toc);
            
            %filtracja zwi�zana z przebyt� odleg�o�ci� oraz transmitancj�
            %o�rodka
            %tic
            attFactor = 1/(distance);
            %filteredBuffer = Dsp.filter(filteredBuffer, getAirFilter(distance));
            filteredBuffer = filteredBuffer.*attFactor;
            %fprintf(1, 'Przetwarzanie propagacji przez medium: %d [sec]\n', toc);
            %filtracja binauralna (HRTF)
            %tic
            [leftEarFilter, rightEarFilter] = this.interpolateHrtf(imageSource);
            
            leftEarImpulseResponse = Dsp.filter(filteredBuffer, leftEarFilter);
            rightEarImpulseResponse = Dsp.filter(filteredBuffer, rightEarFilter);
            %fprintf(1, 'Przetwarzanie binauralne: %d [sec]\n', toc);
        end
        
        function draw(this, drawing2dContext)
            error('Drawing not supported yet');
            %Receiver2dModel.validateInput(drawing2dContext);
            %filled = 0;
            %this.shape.draw(filled, drawing2dContext);
            %directionLine = Line2d();
            %directionLine.initWithAngleLength(this.positionVector, ...
            %                                    this.directionAngle, this.shape.getRadius(), 'black');
            %directionLine.draw(drawing2dContext);
        end
        %Getters
        function positionX = getPositionX(this)
            positionX = this.positionVector.getX();
        end
        function positionY = getPositionY(this)
            positionY = this.positionVector.getY();
        end
        function positionZ = getPositionZ(this)
            positionZ = this.positionVector.getZ();
        end
        
        function positionVector = getPositionVector(this)
            positionVector = this.positionVector;
        end
        function shape = getShape(this)
            shape = this.shape;
        end
        function directionAngle = getAzimuthDirectionAngle(this)
            directionAngle = this.azimuthDirectionAngle;
        end
        function directionAngle = getElevationDirectionAngle(this)
            directionAngle = this.elevationDirectionAngle;
        end
        function realSize = getRealSize(this)
            realSize = this.realSize;
        end
    end
    %--------------
    %Private Methods
    %--------------
    methods (Access = 'private', Static = true)
        function validateInput(drawing2dContext)
            if ~isa(drawing2dContext, 'Drawing2dContext')
                error('Invalid input argument');
            end
        end
    end 
    
    methods (Access = 'public', Static = true)
        
    end
end