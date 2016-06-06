classdef Reception < handle
    properties (GetAccess = 'private', SetAccess = 'private')
        lastRay;
        walls;
        distance;
    end
    
    methods (Access = 'public')
        function this = Reception(lastRay, walls, distance)
            this.lastRay    =   lastRay;
            this.walls      =   walls;
            this.distance   =   distance;
        end
        
        function lastRay = getLastRay(this)
            lastRay     =   this.lastRay;
        end
        function walls = getWalls(this)
            walls       =   this.walls;
        end
        function distance = getDistance(this)
            distance    =   this.distance;
        end
    end
end

