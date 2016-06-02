classdef Directivity3d < handle
    properties (GetAccess = 'private', SetAccess = 'private')
        filtersMap;
        nodes;
        type;
    end
    
    methods (Access = 'public')
        function this = Directivity3d(anglesMap, filenamePattern, type, transducerModel)
            this.filtersMap = containers.Map('KeyType','int16','ValueType','any'); %Vec3d.ID -> filter
            nodeCounter = int16(0);
            this.nodes = [];
            
            radius = transducerModel.getShape().getRadius();
            
            elevationAngles = keys(anglesMap);
            for i = elevationAngles
                azimuthAngles = anglesMap(i);
                for j = azimuthAngles
                    filename = sprintf(filenamePattern, Hrtf.convertHRThetaToGeneral(i), Hrtf.convertHRPhiToGeneral(j));
                    nodeCounter = nodeCounter + int16(1);
                    this.nodes(nodeCounter) = Vec3d.createWithSpherical(radius, i, j);
                    this.filtersMap(nodeCounter) = audioread(filename);
                end
            end
            this.type = type;
            %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
            %this.filtersMap = containers.Map('KeyType','double','ValueType','any');
            %tempMap = containers.Map('KeyType', 'double', 'ValueType', 'any');
            %
            %elevationAngles = keys(anglesMap);
            %for i = elevationAngles
            %    azimuthAngles = anglesMap(i);
            %    for j = azimuthAngles
            %        filename = sprintf(filenamePattern, Hrtf.convertHRThetaToGeneral(i), Hrtf.convertHRPhiToGeneral(j));
            %        tempMap(j) = audioread(filename);
            %    end
            %    this.filtersMap(i) = tempMap;
            %end
            %this.type = type;
        end
        
        function filter = getFilter(this, point)
            filter = Filter(1, this.filtersMap(angle), 44100, this.type);  
        end
    end
    
    methods (Access = private)
    end  
end