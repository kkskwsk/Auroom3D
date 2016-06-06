classdef Face3d < handle
    properties (GetAccess = 'private', SetAccess = 'private')
        vertices;
        normalVector;
    end
    
    methods (Access = 'public')
        function this = Face3d(vecA, vecB, vecC)
            this.vertices       =   Vec3d.empty(0);
            this.vertices(1)    =   vecA;
            this.vertices(2)    =   vecB;
            this.vertices(3)    =   vecC;
            
            this.calcNormal();
        end
        
        function calcNormal(this)
            v12     =   this.vertices(2) - this.vertices(1); 
            v13     =   this.vertices(3) - this.vertices(1);
            
            normal              =   Vec3d.crossProd(v12, v13);
            tempNormalVector    =   Vec3d(normal.getX(), normal.getY(), normal.getZ());
            this.normalVector   =   tempNormalVector.normalize();
        end
        
        function vertices = getVertices(this)
            vertices        =   this.vertices;
        end
        function normalVector = getNormalVector(this)
            normalVector    =   this.normalVector;
        end
    end
end