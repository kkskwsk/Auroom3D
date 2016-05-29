classdef Sphere3d < handle
    properties (GetAccess = 'private', SetAccess = 'private')
        center;
        radius;
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
        function this = Sphere3d(center, radius)
            if (nargin ~= 0)
                this.center = center;
                this.radius = radius;
            end
        end
        
        function draw(this, filled, drawing2dContext)
            error('Drawing is not supported in 3D');
        end
        %Getters
        function center = getCenter(this)
            center = this.center;
        end
        function radius = getRadius(this)
            radius = this.radius;
        end
    end
end