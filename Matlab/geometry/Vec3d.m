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
            
                %this.calcSphericalCoords();
        end
        
        function length = getLength(this)
            length = sqrt(this.x^2 + this.y^2 + this.z^2);
        end
        
        function r = eq(vec1, vec2)
            if (length(vec1) == 1)
                if (vec1.x == vec2.x && vec1.y == vec2.y && vec1.z == vec2.z)
                    r = true;
                else
                    r = false;
                end
            elseif length(vec1 > 1)
                r = zeros(size(vec1));
                for i = 1:length(vec1)
                    temp = vec1(i) == vec2(i);
                    r(i) = temp;
                end
            else
                error('empty input');
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
        
        function rotate(this, axis, angle)
            if strcmp('z', axis)
                rotMatrix = [ cosd(angle), sind(angle), 0, 0;...
                             -sind(angle), cosd(angle), 0, 0;...
                              0          , 0          , 1, 0;...
                              0          , 0          , 0, 1];
                pointMatrix = [this.getCoords()' 0];
                
                rotatedPoint = pointMatrix * rotMatrix;
                this.setX(rotatedPoint(1));
                this.setY(rotatedPoint(2));
                this.setZ(rotatedPoint(3));
            else
                error('Not supported');
            end
        end
        
        function print(this)
            fprintf(1, 'Vec3d object:\nx = %d,\ny = %d,\nz = %d\n', this.x, this.y, this.z);
        end
        
        function normalizedVector = normalize(this)
            length = this.getLength();
            normalizedVector = Vec3d(this.x/length, this.y/length, this.z/length);
        end
        
        %Getters
        %%Cartesian
        function coords = getCoords(this)
            coords = [this.x; this.y; this.z];
%             coords(1) = this.x;
%             coords(2) = this.y;
%             coords(3) = this.z;
        end
        
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
        %%Cartesian
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
        function [x, y, z] = calcCartesianCoords(radius, theta, phi)
            x = radius*sind(theta)*cosd(phi);
            y = radius*sind(theta)*sind(phi);
            z = radius*cosd(theta);
        end
        
        function [radius, theta, phi] = calcSphericalCoords(this)
            radius = sqrt(this.x^2 + this.y^2 + this.z^2);
            theta = acos(this.z/radius);
            phi = acos(this.y/this.x);
        end
        
        function vec3d = createWithSpherical(radius, theta, phi)
            [x, y, z] = Vec3d.calcCartesianCoords(radius, theta, phi);
            vec3d = Vec3d(x, y, z);
        end
        
        function r = dotProd(vec1, vec2)
            r = dot([vec1.x vec1.y vec1.z], [vec2.x vec2.y vec2.z]);
        end
        
        function r = crossProd(vec1, vec2)
            matrixResult = cross([vec1.getX(), vec1.getY(), vec1.getZ()], [vec2.getX(), vec2.getY(), vec2.getZ()]);
            r = Vec3d(matrixResult(1), matrixResult(2), matrixResult(3));
        end
        
        
    end
end