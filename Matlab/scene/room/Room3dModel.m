classdef Room3dModel < handle
    %--------------
    % Two dimensional model of a room where simulation takes place.
    %--------------
    properties (GetAccess = 'private', SetAccess = 'private')
        walls;
        medium;
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
        function this = Room3dModel(vertices, faces, materials, medium)
            this.walls = Wall3d.empty(0);
            for i = length(faces):-1:1
                vertIndexes = faces(i, :);
                for j = 1:length(vertIndexes)
                     usedVert = vertices(vertIndexes(j), :);
                     vectors(j) = Vec3d(usedVert(1), usedVert(2), usedVert(3));
                end
                face = Face3d(vectors(1), vectors(2), vectors(3));
                this.walls(i) = Wall3d(face, materials(i), i);
            end
            this.medium = medium;
        end
        
        %TO DO; na pocz¹tku poprawiæ ray
        function [minLen, wall, reflectionDirVector] = reflect(this, ray)
            minLen = [];
            eps = 10e-12;
            if ray.getOriginVector().getZ() == 0
                1;
            end
            for i = 1:length(this.walls)
                [isTrue, len] = ray.intersectFace(this.walls(i).getFace());
                if isTrue && (len > eps) && (isempty(minLen) || (minLen > len))
                    wall = this.walls(i);
                    minLen = len;
                end
            end
            
            rayCopy = Ray3d(ray.getOriginVector(), ray.getDirectionVector());
            rayCopy.setLength(minLen);
            endVec = rayCopy.getEndVector();
            
            reflectionDirVector = ray.calcReflectionDirVector(wall.getFace()); 
            if (endVec.getZ == 0) && (reflectionDirVector.getZ < 0)
                1;
            end
        end
        
        function draw(this, drawing2dContext)
            %Room2dModel.validateDrawInput(drawing2dContext);
            %for i = 1:length(this.walls)
            %    this.walls(i).draw(drawing2dContext);
            %end
            error('Drawing is not supported in 3D'); 
        end
        %Getters
        function walls = getWalls(this)
            walls = this.walls;
        end
    end
end