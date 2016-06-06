classdef Wall3d < handle
    properties (GetAccess = 'private', SetAccess = 'private')
        faces;
        material;
        id;
    end
    
    methods (Access = 'public')
        function this = Wall3d(faces, id)
            if (nargin > 0)
                this.faces  =   faces;
                this.id     =   id;
            end
        end
        
        function faces = getFaces(this)
            faces       =   this.faces;
        end
        function material = getMaterial(this)
            material    =   this.material;
        end
        
        function setMaterial(this, material)
            this.material   =   material;
        end
        function appendFace (this, face)
            this.faces(end + 1)     =   face;
        end
    end
end