classdef Wall3d < handle
    %--------------
    % Short description
    %--------------
    properties (GetAccess = 'private', SetAccess = 'private')
        face;
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
        function this = Wall3d(face, material, id)
            if (nargin > 0)
                this.face = face;
                this.material = material;
                this.id = id;
            end
        end
        
        function draw(this, drawing2dContext)
            %Wall2d.validateInput(drawing2dContext);
            %this.line.draw(drawing2dContext);
            error('Drawing is not supported in 3D mode.');
        end
        
        %Getters
        function line = getFace(this)
            line = this.face;
        end
        function material = getMaterial(this)
            material = this.material;
        end
    end
end