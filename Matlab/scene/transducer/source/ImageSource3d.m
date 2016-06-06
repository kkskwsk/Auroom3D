classdef ImageSource3d < handle
    properties
        positionVector;
        walls;
        wallFilter;
    end
    
    methods (Access = 'public')
        function this = ImageSource3d(reception)
            lastRay                     =   reception.getLastRay();
            backtraceImageSourceRay     =   Ray3d(lastRay.getEndVector(), lastRay.getDirectionVector()*(-1));
            backtraceImageSourceRay.setLength(calcSizeInPixels(reception.getDistance()));
            this.positionVector         =   backtraceImageSourceRay.getEndVector();
            this.walls                  =   reception.getWalls();
            
            this.calcFilter();
        end
        
        function positionVector = getPositionVector(this)
            positionVector  =   this.positionVector();
        end
        function walls = getWalls(this)
            walls           =   this.walls;
        end
        function wallFilter = getWallFilter(this)
            wallFilter      =   this.wallFilter;
        end
    end
    
    methods (Access = 'private')
        function calcFilter(this)
            resultImpulseResponse   =   1;
            
            for i = 1:length(this.walls)
                tempFilter              =   this.walls(i).getMaterial().getFilter();
                resultImpulseResponse   =   Dsp.filter(resultImpulseResponse, tempFilter);
            end
            
            this.wallFilter             =   Filter(1, resultImpulseResponse, 44100);
        end
    end
end

