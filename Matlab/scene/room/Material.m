classdef Material < handle %<attenuator
    %--------------
    % Short description
    %--------------
    properties (GetAccess = 'private', SetAccess = 'private')
        name;
        filter;
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
        function this = Material(name, filter)
            this.name = name;
            this.filter = filter;
        end
        
        %Getters
        function name = getName(this)
            name = this.name;
        end
        function filter = getFilter(this)
            filter = this.filter;
        end
    end
    %--------------
    %Private Methods
    %--------------
end