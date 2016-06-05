classdef Filter < handle
    properties (GetAccess = 'private', SetAccess = 'private')
        aCoeffs;
        bCoeffs;
        fs;
    end
    
    methods (Access = 'public')
        function this = Filter(aCoeffs, bCoeffs, fs)
            this.aCoeffs    =   aCoeffs;
            this.bCoeffs    =   bCoeffs;
            this.fs         =   fs;
        end
        
        function aCoeffs = getCoeffsA(this)
            aCoeffs     =   this.aCoeffs;
        end
        
        function bCoeffs = getCoeffsB(this)
            bCoeffs     =   this.bCoeffs;
        end
        
        function fs = getFs(this)
            fs          =   this.fs;
        end
    end
end