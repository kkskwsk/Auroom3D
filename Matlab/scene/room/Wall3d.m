classdef Wall3d < handle
    %--------------
    % Short description
    %--------------
    properties (GetAccess = 'private', SetAccess = 'private')
        faces;
        material;
        id;
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
        function this = Wall3d(faces, id)
            if (nargin > 0)
                this.faces = faces;
                this.id = id;
            end
        end
        
        function draw(this, drawing2dContext)
            %Wall2d.validateInput(drawing2dContext);
            %this.line.draw(drawing2dContext);
            error('Drawing is not supported in 3D mode.');
        end
        
        %Getters
        function faces = getFaces(this)
            faces = this.faces;
        end
        function material = getMaterial(this)
            material = this.material;
        end
        
        function setMaterial(this, material)
            this.material = material;
        end
        
        function appendFace (this, face)
            this.faces(end + 1) = face;
        end
    end
end