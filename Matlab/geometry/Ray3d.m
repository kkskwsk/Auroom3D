classdef Ray3d < handle
    properties (GetAccess = 'private', SetAccess = 'private')
        originVector;
        directionVector;
        length;
    end
    
    methods (Access = 'public')
        function this = Ray3d(originVector, directionVector)
            this.originVector       =   originVector;
            this.directionVector    =   directionVector;
            this.length             =   0;
        end
        
        function dirVector = calcReflectionDirVector(this, face)
            faceNormalVector    =   face.getNormalVector;
            cos1                =   -1 * Vec3d.dotProd(faceNormalVector, this.directionVector);
            dirVector           =   this.directionVector + (face.getNormalVector() * 2 * cos1);
        end
        
        function [isTrue, len] = intersectFace(this, face)
            %Linear component intersecting a triangle - algorithm based on
            %the one found in "Geometric Tools for Computer Graphics" by
            %Schneider and Eberly. The solution is based on using
            %barycentric coordinates.
            epsilon         =   0.00000000000001;
            triangleVerts   =   face.getVertices();
            e1              =   triangleVerts(2) - triangleVerts(1);
            e2              =   triangleVerts(3) - triangleVerts(1);
            
            p               =   Vec3d.crossProd(this.directionVector, e2);
            tmp             =   Vec3d.dotProd(p, e1);
            
            if (tmp > -epsilon && tmp < epsilon)
                isTrue  =   false;
                len     =   0;
                return;
            end
            
            tmp     =   1.0 / tmp;
            s       =   this.originVector - triangleVerts(1);
            
            u       =   tmp * Vec3d.dotProd(s, p);
            
            if (u < 0 || u > 1)
                isTrue  =   false;
                len     =   0;
                return;
            end
            
            q   =   Vec3d.crossProd(s, e1);
            v   =   tmp * Vec3d.dotProd(this.directionVector, q);
            
            if (v < 0 || u + v > 1)
                isTrue  =   false;
                len     =   0;
                return;
            end
            
            t   =   tmp * Vec3d.dotProd(e2, q);
            
            if (t <= epsilon)
                isTrue  =   false;
                len     =   0;
                return;
            end
            
            isTrue  =   true;
            len     =   t;            
        end
        
        function [isTrue, len, point] = intersectSphere(this, sphere)
            originMinusCenter   =   this.originVector - sphere.getCenter();
            radius              =   sphere.getRadius();
            a                   =   Vec3d.dotProd(this.directionVector, this.directionVector);
            b                   =   2*Vec3d.dotProd(this.directionVector, originMinusCenter);
            c                   =   Vec3d.dotProd(originMinusCenter, originMinusCenter) - radius^2;
            discrm              =   b^2 - 4*a*c;
            
            if (discrm < 0)
                isTrue  =   false;
                len     =   0;
                point   =   0;
                return;
            elseif discrm > 0
                t(1)    =   (-b + sqrt(discrm)) / (2*a);
                t(2)    =   (-b - sqrt(discrm)) / (2*a);
                
                if (t(1) < 0 && t(2) < 0)
                    isTrue  =   false;
                    len     =   0;
                    point   =   0;
                    return
                elseif t(1) < t(2)
                    len     =   t(1);
                else
                    len     =   t(2);
                end
                
                isTrue  =   true;
                point   =   this.originVector + this.directionVector*len;
            elseif discrm == 0
                t   =   -b/(2*a);
                
                if (t < 0)
                    isTrue  =   false;
                    len     =   0;
                    point   =   0;
                    return;
                end
                
                len     =   t;
                isTrue  =   true;
                point   =   this.originVector + this.directionVector*len;
            end
        end
        
        function originVector = getOriginVector(this)
            originVector    =   this.originVector;
        end
        function endVector = getEndVector(this)
            endVector       =   Vec3d(this.originVector.getX() + this.length*this.directionVector.getX(), this.originVector.getY() + this.length*this.directionVector.getY(), this.originVector.getZ() + this.length*this.directionVector.getZ());
        end
        function directionVector = getDirectionVector(this)
            directionVector =   this.directionVector;
        end
        function length = getLength(this)
            length          =   this.length;
        end
        
        function setLength(this, length)
            this.length     =   length;
        end
    end
end