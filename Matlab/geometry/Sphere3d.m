classdef Sphere3d < handle
    properties (GetAccess = 'private', SetAccess = 'private')
        center;
        radius;
    end
    
    methods (Access = 'public')
        function this = Sphere3d(center, radius)
            if (nargin ~= 0)
                this.center     =   center;
                this.radius     =   radius;
            end
        end
        
        function center = getCenter(this)
            center  =   this.center;
        end
        function radius = getRadius(this)
            radius  =   this.radius;
        end
    end
end