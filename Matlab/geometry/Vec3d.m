classdef Vec3d < handle
    %--------------
    % Short description
    %--------------
    properties (GetAccess = 'private', SetAccess = 'private')
        x;
        y;
        z;
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
        function this = Vec3d(x, y, z)
            this.x = x;
            this.y = y;
            this.z = z;
        end
        
        function length = getLength(this)
            length = sqrt(this.x^2 + this.y^2 + this.z^2);
        end
        
        function r = eq(vec1, vec2)
            if (vec1.x == vec2.x && vec1.y == vec2.y && vec1.z == vec2.z)
                r = true;
            else
                r = false;
            end
        end
        
        function r = plus(vec1, vec2)
            r = Vec3d(vec1.x + vec2.x, vec1.y + vec2.y, vec1.z + vec2.z);
        end
        
        function r = minus(vec1, vec2)
            r = Vec3d(vec1.x - vec2.x, vec1.y - vec2.y, vec1.z - vec2.z);
        end
        function r = mtimes(vec1, scalar)
            r = Vec3d(vec1.x * scalar, vec1.y * scalar, vec1.z * scalar);
        end
        
        function normalizedVector = normalize(this)
            length = this.getLength();
            normalizedVector = Vec3d(this.x/length, this.y/length, this.z/length);
        end
        
        %Getters
        function x = getX(this)
            x = this.x;
        end
        function y = getY(this)
            y = this.y;
        end
        
        function z = getZ(this)
            z = this.z;
        end
        %Setters
        function x = setX(this, x)
            this.x = x;
        end
        function y = setY(this, y)
            this.y = y;
        end
        function z = setZ(this, z)
            this.z = z;
        end
    end
    %--------------
    %Private Methods
    %--------------
    methods (Static = true, Access = 'public')
        %function angle = calcAngle(vec1, vec2)
        %    angleRad = acos(dot([vec1.x, vec1.y], [vec2.x, vec2.y])/(vec1.getLength() * vec2.getLength()));
        %    angle = angleRad * (180/pi);
        %end
        function r = dotProd(vec1, vec2)
            r = dot([vec1.x vec1.y vec1.z], [vec2.x vec2.y vec2.z]);
        end
        
        function r = crossProd(vec1, vec2)
            matrixResult = cross([vec1.getX(), vec1.getY(), vec1.getZ()], [vec2.getX(), vec2.getY(), vec2.getZ()]);
            r = Vec3d(matrixResult(1), matrixResult(2), matrixResult(1));
        end
        
    end
end