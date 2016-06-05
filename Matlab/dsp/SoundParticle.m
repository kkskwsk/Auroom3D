classdef SoundParticle < handle
    properties (GetAccess = 'private', SetAccess = 'private')
        initialSettings;
        rays; %container
        distance;
        walls; %container
        received;
        receptions;
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
        function this = SoundParticle(sourceModel, directionVector)
            this.initialSettings.originVector = sourceModel.getPositionVector();
            this.initialSettings.directionVector = directionVector;
            %this.rays(1) = Ray2d(originVector, angle);
            this.distance = 0;
            this.walls = Wall3d.empty(0);
            this.received = false;
            this.receptions = Reception.empty(0);
        end
        
        function shoot(this, simulation3dContext)
            distanceThreshold = simulation3dContext.getDistanceThreshold();
            originVector = this.initialSettings.originVector;
            directionVector = this.initialSettings.directionVector;
            checkReceiver = true;
            
            while (this.distance <= distanceThreshold)
                this.rays = [this.rays Ray3d(originVector, directionVector)];
                ray = this.rays(end);
                
                if checkReceiver
                    [intersectsReceiver, distRec] = simulation3dContext.getReceiverModel().intersect(ray);
                end
                [distWall, wall, directionVector] = simulation3dContext.getRoomModel().reflect(ray);
                
                if isempty(wall)
                    msgID = 'PARTICLESHOOT:NoWallIntersected';
                    msg = 'Unable to intersect room boundary.';
                    exception = MException(msgID,msg);
                    throw(exception);
                end
                
                if intersectsReceiver && (distRec < distWall)
                    ray.setLength(distRec);
                    this.distance = this.distance + calcSizeInMeters(abs(distRec));
                    this.received = true;
                    this.receptions = [this.receptions Reception(ray, this.walls, this.distance)];
                    originVector = ray.getEndVector();
                    directionVector = ray.getDirectionVector();
                    checkReceiver = false;
                    intersectsReceiver = false;
                    continue; 
                end
                
                this.walls(end + 1) = wall;
                ray.setLength(distWall);
                this.distance = this.distance + calcSizeInMeters(abs(distWall));
                originVector = ray.getEndVector();
                checkReceiver = true;
            end
            
            if (this.distance > distanceThreshold)
                excess = this.distance - distanceThreshold;
                ray.setLength(ray.getLength() - calcSizeInPixels(excess));
                if (this.received == true && isequal(this.receptions(end).getLastRay(), ray))
                    this.receptions(end) = [];
                    if isempty(this.receptions)
                        this.received = false;
                    end
                else
                    this.walls(end) = [];
                end
            end
        end
        
        function draw(this, drawing2dContext)
%             for i = 1:length(this.rays)
%                 this.rays(i).draw(drawing2dContext);
%             end
            error('Drawing is not supported in 3d yet');
        end 
        
        function rays = getRays(this)
            rays = this.rays;
        end
        function distance = getDistance(this)
            distance = this.distance;
        end
        function received = isReceived(this)
            received = this.received;
        end
        function filters = getWalls(this)
            filters = this.walls;
        end
        function receptions = getReceptions(this)
            receptions = this.receptions;
        end
        function reception = getReception(this, no)
            reception = this.receptions(no);
        end
        
    end
    %--------------
    %Private Methods
    %--------------
end