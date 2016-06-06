classdef Source3dModel < handle
    properties (GetAccess = 'private', SetAccess = 'private')
        positionVector;
        shape;
        numberOfParticles;
        particles;
    end
    
    methods (Access = 'public')
        function this = Source3dModel(positionVector)
            this.positionVector     =   positionVector;
            radius                  =   1; %sfera jednostkowa
            this.shape              =   Sphere3d(positionVector, radius);
            this.numberOfParticles  =   0;
            this.particles          =   SoundParticle.empty(0);
        end
        
        function shootParticles(this, simulationContext)
            if this.numberOfParticles == 0
                error('number of particles is not initialized');
            end
            
            directionVectors    =   Source3dModel.calcParticlesDirections(this.numberOfParticles, false);
            
            for i = 1:length(directionVectors)
                particle            =   SoundParticle(this, directionVectors(i));
                this.particles(i)   =   particle;
            end
            
            h               =   waitbar(0, 'Performing ray tracing.');
            particlesLocal  =   this.particles;
            particlesNum    =   length(particlesLocal);
            step            =   0;
            
            try
                for j = 1:particlesNum
                    step                =   step + 1;
                    waitbar(step/particlesNum);
                    particle            =   particlesLocal(j);
                    particle.shoot(simulationContext);
                    particlesLocal(j)   = particle;
                end
                
            catch ME
                close(h);
                throw(ME);
            end
            
            close(h);
            
            this.particles  =   particlesLocal;
        end
        
        function positionVector = getPositionVector(this)
            positionVector  =   this.positionVector;
        end
        function particles = getParticles(this)
            particles       =   this.particles;
        end
        
        function setNumberOfParticles(this, numberOfParticles)
            this.numberOfParticles  =   numberOfParticles;
        end
    end
    
    methods (Access = 'public', Static = true)
        function directionVectors = calcParticlesDirections(numberOfPoints, randomize)
            directionVectors    =   Vec3d.empty(0);
            offset              =   2/numberOfPoints;
            increment           =   pi * (3 - sqrt(5));
            rnd                 =   1;
            
            if randomize
                rnd     =   rand * numberOfPoints;
            end
            
            for i = 0:numberOfPoints-1
                y   =   ((i * offset) - 1) + (offset / 2);
                r   =   sqrt(1 - y^2);
                phi =   mod((i + rnd), numberOfPoints) * increment;
                
                x   =   cos(phi) * r;
                z   =   sin(phi) * r;
                
                directionVectors(i+1)   =   Vec3d(x, y, z);
            end
        end
    end
end