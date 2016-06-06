classdef Handler < handle
    properties (GetAccess = 'private', SetAccess = 'private')
        property;
    end
    
    methods (Access = 'public')
        function this = Handler(prop)
            this.property   =   prop;
        end
        
        function prop = getProperty(this)
            prop            =   this.property;
        end
        
        function setProperty(this, property)
            this.property   =   property;
        end
    end
end

