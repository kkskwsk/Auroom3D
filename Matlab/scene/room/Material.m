classdef Material < handle 
    properties (GetAccess = 'private', SetAccess = 'private')
        name;
        filter;
    end
    
    methods (Access = 'public')
        function this = Material(name, filter)
            this.name   =   name;
            this.filter =   filter;
        end
        
        function name = getName(this)
            name        =   this.name;
        end
        function filter = getFilter(this)
            filter      =   this.filter;
        end
    end
end