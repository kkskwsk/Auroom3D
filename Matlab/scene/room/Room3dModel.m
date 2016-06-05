classdef Room3dModel < handle
    %--------------
    % Two dimensional model of a room where simulation takes place.
    %--------------
    properties (GetAccess = 'private', SetAccess = 'private')
        walls;
    end
    
    methods (Access = 'private', Static = true)
        function result = checkHoles(polyhedronFaces)
            facesArraySize = size(polyhedronFaces, 1);
            oneFaceArraySize = length(polyhedronFaces(1,:));
            edges = zeros(facesArraySize * oneFaceArraySize, 2);
            
            for i = 0:facesArraySize - 1
                face = polyhedronFaces(i + 1, :);
                for j = 0:oneFaceArraySize - 1
                    edges(i*oneFaceArraySize + j + 1, 1) = face(j + 1);
                    edges(i*oneFaceArraySize + j + 1, 2) = face(mod(j+1, oneFaceArraySize)+ 1);
                    edges(i*oneFaceArraySize + j + 1, :) = sort(edges(i*oneFaceArraySize + j + 1, :));
                end
            end
            [~, UIDs, edgesByUID] = unique(edges, 'rows');
            UIDs = UIDs';
            
            for i = 1:length(UIDs)
                if length(edgesByUID(edgesByUID == i)) < 2
                    fprintf(1, 'There is a hole!\n');
                    result = false;
                    return
                end
            end 
            fprintf(1, 'No holes found!\n');
            result = true;
        end
    end
    
    methods (Access = 'public')
        %Constructor
        function this = Room3dModel(vertices, faces)
            if ~Room3dModel.checkHoles(faces)
                msgID = 'ROOM:HolesFound';
                msg = 'Incorrect walls definition. Holes found.';
                exception = MException(msgID,msg);
                throw(exception);
            end
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
                    this.walls(wallsCounter) = Wall3d(face, wallsCounter);
                end
                alreadyAppended = false;
            end
        end
        
        function setWallMaterial(this, material)
            for i = 1:length(this.walls)
                this.walls(i).setMaterial(material);
            end
        end
        
        %TO DO; na pocz¹tku poprawiæ ray
        function [minLen, wall, reflectionDirVector] = reflect(this, ray)
            wall = [];
            minLen = [];
            eps = 10e-13;
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
            
            if ~isempty(wall)
                faces = wall.getFaces();
                reflectionDirVector = ray.calcReflectionDirVector(faces(1));
            else
                minLen = [];
                reflectionDirVector = [];
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