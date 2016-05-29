classdef Face3d < handle
    %--------------
    % Short description
    %--------------
    properties (GetAccess = 'private', SetAccess = 'private')
        vertices;
        normalVector;
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
        function this = Face3d(vecA, vecB, vecC)
            this.vertices(1) = vecA;
            this.vertices(2) = vecB;
            this.vertices(3) = vecC;
            calcNormal();
            
        end
        
        function calcNormal(this)
            v12 = this.vertices(2) - this.vertices(1); 
            v13 = this.vertices(3) - this.vertices(1);
            
            normal = cross([v12.getX(), v12.getY(), v12.getZ()], [v13.getX(), v13.getY(), v13.getZ()]);
            tempNormalVector = Vec3d(normal.getX(), normal.getY(), normal.getZ());
            this.normalVector = tempNormalVector.normalize();
        end
        
        function draw(this, drawing2dContext)
            %Line2d.validateInput(drawing2dContext);
            %shape = insertShape(drawing2dContext.getCanvas, 'line', ...
            %                    [this.originVertex.getY(), ...
            %                     this.originVertex.getX(), ...
            %                     this.endVertex.getY(),    ...
            %                     this.endVertex.getX()],   ...
            %                     'Color', this.color,      ...
            %                     'LineWidth', drawing2dContext.getLineWidth());
            %drawing2dContext.setCanvas(shape);
            error('Drawing is not supported in 3D');
        end
        %Getters
        function vertices = getVertices(this)
            vertices = this.vertices;
        end
        function normalVector = getNormalVector(this)
            normalVector = this.normalVector;
        end
    end
end