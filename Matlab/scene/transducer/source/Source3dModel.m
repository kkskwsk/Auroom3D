classdef Source3dModel < handle
    %--------------
    % Short description
    %--------------
    properties (GetAccess = 'private', SetAccess = 'private')
        positionVector;
        shape;
        azimuthDirectionAngle; %in degrees
        elevationDirectionAngle; %in degrees
        numberOfParticles;
        particles;
        %directivity;
        %freqResponse;
        %diaphragmRadius;
        %nearFieldBorder;
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
        function this = Source3dModel(positionVector, azimuthDirectionAngle, elevationDirectionAngle)
            this.positionVector = positionVector;
            this.azimuthDirectionAngle = azimuthDirectionAngle;
            this.elevationDirectionAngle = elevationDirectionAngle;
            radius = 1; %sfera jednostkowa
            this.shape = Sphere3d(positionVector, radius);
            this.numberOfParticles = 0;
            this.particles = SoundParticle.empty(0);
        end
        
        function draw(this, drawing2dContext)
            error('Drawing is not supported in 3D');
        end
        
        function shootParticles(this, simulationContext)
            if this.numberOfParticles == 0
                error('number of particles is not initialized');
            end
            
            directionVectors = Source3dModel.calcParticlesDirections(this.numberOfParticles, false);
            
            for i = 1:length(directionVectors)
                particle = SoundParticle(this, directionVectors(i));
                this.particles(i) = particle;
            end
            tic
            particlesLocal = this.particles;
%             parfor j = 1:length(particlesLocal)
%                 particle = particlesLocal(j);
%                 particle.shoot(simulationContext);
%                 particlesLocal(j) = particle;
%             end
            parfor j = 1:length(particlesLocal)
                particle = particlesLocal(j);
                particle.shoot(simulationContext);
                particlesLocal(j) = particle;
            end
            
            this.particles = particlesLocal;
            fprintf('time of full processing: %d [sec]\n', toc);
        end
        
        function drawRays(this, drawing2dContext)
            %for i = 1:length(this.particles)
            %    this.particles(i).draw(drawing2dContext);
            %end
            error('Drawing is not supported in 3D');
        end
        
        %Getters
        function positionVector = getPositionVector(this)
            positionVector = this.positionVector;
        end
        function azimuthDirectionAngle = getAzimuthDirectionAngle(this)
            azimuthDirectionAngle = this.azimuthDirectionAngle;
        end
        function elevationDirectionAngle = getElevationDirectionAngle(this)
            elevationDirectionAngle = this.elevationDirectionAngle;
        end
        function particles = getParticles(this)
            particles = this.particles;
        end
        %Setters
        function setNumberOfParticles(this, numberOfParticles)
            this.numberOfParticles = numberOfParticles;
        end
    end
    
    methods (Access = 'public', Static = true)
        %czy orientacje osi s� dobre?
        %fibonacci sphere czy jako� tak
        function directionVectors = calcParticlesDirections(numberOfPoints, randomize)
            directionVectors = Vec3d.empty(0);
            offset = 2/numberOfPoints;
            increment = pi * (3 - sqrt(5));
            rnd = 1;
            
            if randomize
                rnd = rand * numberOfPoints;
            end
            
            for i = 0:numberOfPoints-1
                y = ((i * offset) - 1) + (offset / 2);
                r = sqrt(1 - y^2);
                
                phi = mod((i + rnd), numberOfPoints) * increment;
                
                x = cos(phi) * r;
                z = sin(phi) * r;
                
                directionVectors(i+1) = Vec3d(x, y, z);
                fprintf(1, 'Length of calculated dir vector: %d\n', directionVectors(i+1).getLength());
                directionVectors(i+1).print();
            end
        end
    end
end