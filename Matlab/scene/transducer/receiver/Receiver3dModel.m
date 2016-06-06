classdef Receiver3dModel < handle
    properties (GetAccess = 'private', SetAccess = 'private')
        positionVector;
        shape;
        azimuthDirectionAngle;  %in degrees
        realSize;
        hrtf;
    end
    
    methods (Access = 'public')
        function this = Receiver3dModel(positionVector, azimuthDirectionAngle, size, hrtf)
            this.positionVector         =   positionVector;
            this.azimuthDirectionAngle  =   azimuthDirectionAngle;
            this.realSize               =   calcSizeInMeters(size);
            radius                      =   size;
            this.shape                  =   Sphere3d(positionVector, radius);
            
            hrtf.init(this);
            this.hrtf   =   hrtf;
        end
        
        function [isTrue, len] = intersect(this, ray)
            [isTrue, len]   =   ray.intersectSphere(this.shape);
        end
        
        function [leftEarFilter, rightEarFilter] = interpolateHrtf(this, imageSource)
            headPositionVector              =   this.getPositionVector();
            [leftEarFilter, rightEarFilter] =   this.hrtf.interpolate(headPositionVector, imageSource);
        end
        
        function distance = calcDistanceFromImageSource(this, imageSource)
            imageSourcePosition         =   imageSource.getPositionVector();
            imageSourceToReceiverVec    =   this.positionVector - imageSourcePosition;
            distance                    =   calcSizeInMeters(imageSourceToReceiverVec.getLength());
        end
        
        function [leftEarImpulseResponse, rightEarImpulseResponse] = binauralize(this, imageSource, impulse, simulationContext)
            %filtracja zwi¹zana z odbiciami od œcian
            filteredBuffer  =   Dsp.filter(impulse, imageSource.getWallFilter());
            
            %dodane opóŸnienie
            distance        =   this.calcDistanceFromImageSource(imageSource);
            delayTime       =   distance / simulationContext.getSpeedOfSound();
            delaySamples    =   round(delayTime * 44100);
            filteredBuffer  =   delay(filteredBuffer, delaySamples);
            
            %filtracja zwi¹zana z przebyt¹ odleg³oœci¹ oraz transmitancj¹
            %oœrodka
            attFactor       =   1/(distance);
            filteredBuffer  =   filteredBuffer.*attFactor;
            
            %filtracja binauralna (HRTF)
            [leftEarFilter, rightEarFilter]     =   this.interpolateHrtf(imageSource);
            leftEarImpulseResponse              =   Dsp.filter(filteredBuffer, leftEarFilter);
            rightEarImpulseResponse             =   Dsp.filter(filteredBuffer, rightEarFilter);
        end
        
        function positionX = getPositionX(this)
            positionX   =   this.positionVector.getX();
        end
        function positionY = getPositionY(this)
            positionY   =   this.positionVector.getY();
        end
        function positionZ = getPositionZ(this)
            positionZ   =   this.positionVector.getZ();
        end        
        function positionVector = getPositionVector(this)
            positionVector  =   this.positionVector;
        end
        function shape = getShape(this)
            shape           =   this.shape;
        end
        function directionAngle = getAzimuthDirectionAngle(this)
            directionAngle  =   this.azimuthDirectionAngle;
        end
        function realSize = getRealSize(this)
            realSize        =   this.realSize;
        end
    end
    
    methods (Access = 'private', Static = true)
        function validateInput(drawing2dContext)
            if ~isa(drawing2dContext, 'Drawing2dContext')
                error('Invalid input argument');
            end
        end
    end
end