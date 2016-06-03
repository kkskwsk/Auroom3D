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
            wallsCounter = 0;
            alreadyAppended = false;
            
            for i = length(faces):-1:1
                vertIndexes = faces(i, :);
                for j = 1:length(vertIndexes)
                     usedVert = vertices(vertIndexes(j), :);
                     vectors(j) = Vec3d(usedVert(1), usedVert(2), usedVert(3));
                end
                face = Face3d(vectors(1), vectors(2), vectors(3));
                for j = 1:length(this.walls)
                    tempFaces = this.walls(j).getFaces();
                    for k = 1:length(tempFaces)
                        tempFace = tempFaces(k);
                        if (tempFace.getNormalVector() == face.getNormalVector()) && any(tempFace.getVertices() == vectors)
                            this.walls(j).appendFace(face);
                            alreadyAppended = true;
                            break;
                        end
                    end
                end 
                if ~alreadyAppended
                    wallsCounter = wallsCounter + 1;
                    this.walls(wallsCounter) = Wall3d(face, materials(wallsCounter), wallsCounter);
                end
                alreadyAppended = false;
            end
            this.medium = medium;
        end
        
        %TO DO; na pocz¹tku poprawiæ ray
        function [minLen, wall, reflectionDirVector] = reflect(this, ray)
            minLen = [];
            eps = 10e-13;
            if ray.getOriginVector().getZ() == 0
                1;
            end
            for i = 1:length(this.walls)
                tempFaces = this.walls(i).getFaces();
                for j = 1:length(tempFaces)
                    [isTrue, len] = ray.intersectFace(tempFaces(j));
                    if isTrue && (len > eps) && (isempty(minLen) || (minLen > len))
                        wall = this.walls(i);
                        minLen = len;
                    end
                end
            end
            faces = wall.getFaces();
            reflectionDirVector = ray.calcReflectionDirVector(faces(1));
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