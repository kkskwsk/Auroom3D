classdef Hrtf < handle
    properties (GetAccess = 'private', SetAccess = 'private')
        anglesMap;
        leftBuffers;
        rightBuffers;
        
        nodes;
        triangles;
        faces;
        %leftEarDirectivity;
        leftEarFiltersMap;
        rightEarFiltersMap;
        receiverModel;
    end
    
    methods (Access = 'private')
        function loadFilters(this, anglesMap, leftFilenamePattern, rightFilenamePattern)
            this.leftBuffers = containers.Map('KeyType','int32','ValueType','any'); %Vec3d.ID -> filter
            this.rightBuffers = containers.Map('KeyType','int32','ValueType','any'); %Vec3d.ID -> filter
            %nodeCounter = int32(0);
            %this.nodes = Vec3d.empty(0);
            
            %radius = this.receiverModel.getShape().getRadius();
            %translationVec = this.receiverModel.getPositionVector();
            
            elevationAngles = keys(anglesMap);
            for i = elevationAngles
                i = cell2mat(i);
                azimuthAngles = anglesMap(i);
                leftTempMap = containers.Map('KeyType', 'int32', 'ValueType', 'any');
                rightTempMap = containers.Map('KeyType', 'int32', 'ValueType', 'any');
                for j = azimuthAngles
                    filenameLeft = sprintf(leftFilenamePattern, i, j);
                    filenameRight = sprintf(rightFilenamePattern, i, j);
                    leftTempMap(j) = Handler(audioread(filenameLeft));
                    rightTempMap(j) = Handler(audioread(filenameRight));
                end
                this.leftBuffers(i) = leftTempMap;
                this.rightBuffers(i) = rightTempMap;
            end
        end 
        function initFilters(this, anglesMap)
            this.leftEarFiltersMap = containers.Map('KeyType','int32','ValueType','any'); %Vec3d.ID -> filter
            this.rightEarFiltersMap = containers.Map('KeyType','int32','ValueType','any'); %Vec3d.ID -> filter
            nodeCounter = int32(0);
            this.nodes = Vec3d.empty(0);
            
            radius = this.receiverModel.getShape().getRadius();
            translationVec = this.receiverModel.getPositionVector();
            rotationAngle = this.receiverModel.getAzimuthDirectionAngle();
            
            elevationAngles = keys(anglesMap);
            for i = elevationAngles
                i = cell2mat(i);
                leftAzimuth2BufferMap = this.leftBuffers(i);
                rightAzimuth2BufferMap = this.rightBuffers(i);
                azimuthAngles = anglesMap(i);
                for j = azimuthAngles
                    nodeCounter = nodeCounter + int32(1);
                    convPhi = Hrtf.convertHRPhiToGeneral(j);
                    convTheta = Hrtf.convertHRThetaToGeneral(i);
                    node = Vec3d.createWithSpherical(radius, convTheta, convPhi);
                    node.rotate('z', rotationAngle);
                    this.nodes(nodeCounter) = translationVec + node;
                    this.leftEarFiltersMap(nodeCounter) = leftAzimuth2BufferMap(j);%audioread(filenameLeft);
                    this.rightEarFiltersMap(nodeCounter) = rightAzimuth2BufferMap(j);
                end
            end
        end 
        %Delaunay triangulation of measured HRTF points. To get surface triangles
        %a convex hull is then created. This operation is necessary for
        %HRTF interpolation.
        function triangulate(this)
            this.faces = Face3d.empty(0);
            nodesNum = length(this.nodes);
            coordsMatrix  = zeros(nodesNum, 3);
            for i = 1:nodesNum
                coordsMatrix(i, :) = this.nodes(i).getCoords();
            end
            DT = delaunayTriangulation(coordsMatrix);
            this.triangles = DT.convexHull();
            for i = 1:size(this.triangles, 1)
                this.faces(i) = Face3d(this.nodes(this.triangles(i,1)), this.nodes(this.triangles(i,2)), this.nodes(this.triangles(i,3)));
            end
            faceColor  = [0.6875 0.8750 0.8984];
            tetramesh(DT,'FaceColor', faceColor,'FaceAlpha',1);
        end
    end
    
    methods (Access = 'public')
        function this = Hrtf()
            this.anglesMap = containers.Map('KeyType', 'double', 'ValueType', 'any');
            Hrtf.fillAnglesMap(this.anglesMap);
            [leftEarFilenamePattern, rightEarFilenamePattern] = Hrtf.createFilenamePatterns();
            this.loadFilters(this.anglesMap, leftEarFilenamePattern, rightEarFilenamePattern);
%             this.receiverModel = receiverModel;
%             anglesMap = containers.Map('KeyType', 'double', 'ValueType', 'any');
%             Hrtf.fillAnglesMap(anglesMap);
%             [leftEarFilenamePattern, rightEarFilenamePattern] = Hrtf.createFilenamePatterns();
%             this.initFilters(anglesMap, leftEarFilenamePattern, rightEarFilenamePattern);
%             this.triangulate();
        end
        
        function init(this, receiverModel)
            this.receiverModel = receiverModel;
            this.initFilters(this.anglesMap);
            this.triangulate();
        end
        
        function [leftEarFilter, rightEarFilter] = interpolate(this, headPositionVector, imageSource)
            minLen = [];
            imageSourcePositionVector = imageSource.getPositionVector();
            directionVector = headPositionVector - imageSourcePositionVector;
            directionVector = directionVector.normalize();
            ray = Ray3d(imageSourcePositionVector, directionVector);
            
%             parfor i = 1:length(this.faces)
%                 [isTrue, len] = ray.intersectFace(this.faces(i));
%                 if isTrue && (isempty(minLen) || minLen > len)
%                     minLen = len;
%                     triangle = this.triangles(i, :);
%                 end
%             end
            localFaces = this.faces;
            %parfor!!!!!!!!!!
            parfor i = 1:length(this.faces)
                [isTrue(i), len(i)] = ray.intersectFace(localFaces(i));
            end
            
            for i = find(isTrue)
                if (isempty(minLen) || minLen > len(i))
                    minLen = len(i);
                    triangle = this.triangles(i, :);
                end
            end

            ray.setLength(minLen);
            intersectionPoint = ray.getEndVector();
            
           % Interpolation itself
            S = [intersectionPoint.getX();...
                 intersectionPoint.getY();...
                 intersectionPoint.getZ()];
             
            H = [this.nodes(triangle(1)).getCoords(),...
                 this.nodes(triangle(2)).getCoords(),...
                 this.nodes(triangle(3)).getCoords()];
             
            g = H\S;%inv(H)*S;
            
            resultLeftHRIR = g(1)*this.leftEarFiltersMap(triangle(1)).getProperty()...
                           + g(2)*this.leftEarFiltersMap(triangle(2)).getProperty()...
                           + g(3)*this.leftEarFiltersMap(triangle(3)).getProperty();
            resultRightHRIR = g(1)*this.rightEarFiltersMap(triangle(1)).getProperty()...
                           + g(2)*this.rightEarFiltersMap(triangle(2)).getProperty()...
                           + g(3)*this.rightEarFiltersMap(triangle(3)).getProperty();
                       
            leftEarFilter  = Filter(1, resultLeftHRIR, 44100, 'LeftEar');
            rightEarFilter = Filter(1, resultRightHRIR, 44100, 'RightEar');
        end
            
            
            %leftEarFilter = this.leftEarDirectivity.getFilter(roundedAngle);
            %rightEarFilter = this.rightEarDirectivity.getFilter(roundedAngle);
            %if leftEarFilter.getFs() ~= leftEarFilter.getFs()
            %    error('Sampling rates don''t match');
            %end
        %end
    end
    
    methods (Access = 'private', Static = true)
        function fillAnglesMap(anglesMap)
            azimuthAngles = [];
            elevationAngles = -40:10:90;
            for i = elevationAngles
                if i == -40 || i == 40
                    azimuthAngles = [0 6 13 19 26 32 39 45 51 58 64 71 77 ...
                                     84 90 96 103 109 116 122 129 135 141 ...
                                     148 154 161 167 174 180 186 193 199  ...
                                     206 212 219 225 231 238 244 251 257  ...
                                     264 270 276 283 289 296 302 309 315  ...
                                     321 328 334 341 347 354]; 
                elseif i == 90
                    azimuthAngles = 0;
                else
                    if i == 0 || i == -10 || i == 10 || i == -20 || i == 20
                        quant = 5;
                    elseif i == -30 || i == 30
                        quant = 6;
                    elseif i == 50
                        quant = 8;
                    elseif i == 60
                        quant = 10;
                    elseif i == 70
                        quant = 15;
                    elseif i == 80
                        quant = 30;
                    end
                    
                    azimuthAngles = 0:quant:360-quant;
                end
                
                %phis = Hrtf.convertHRPhiToGeneral(azimuthAngles);
                %theta = Hrtf.convertHRThetaToGeneral(i);
                %anglesMap(theta) = phis;
                anglesMap(i) = azimuthAngles;
            end
        end
        
        function [leftEarFilenamePattern, rightEarFilenamePattern] = createFilenamePatterns()
            leftEarFilenamePattern = 'L%1de%1.03da.wav';
            rightEarFilenamePattern = 'R%1de%1.03da.wav';
        end
    end
    
    methods (Access = 'public', Static = true)
        function [theta, phi] = convertAnglesToGeneralCoords(thetaHR, phiHR)
            theta = 90 - thetaHR;
            phi = -phiHR;
        end
        
        function [thetaHR, phiHR] = convertAnglesToHRCoords(theta, phi)
            thetaHR = 90 - theta;
            phiHR = -phi;
        end
        
        function theta = convertHRThetaToGeneral(thetaHR)
            theta = 90 - thetaHR;
        end
        function theta = convertHRPhiToGeneral(phiHR)
            theta = -phiHR;
        end
        
        function thetaHR = convertThetaToHR(theta)
            thetaHR = 90 - theta;
        end
        
        function phiHR = convertPhiToHR(phi)
            phiHR = -phi;
        end
    end
end

