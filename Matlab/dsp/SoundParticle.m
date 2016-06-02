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
            %disp('============SHOOT================')
            %tic
            distanceThreshold = simulation3dContext.getDistanceThreshold();
            originVector = this.initialSettings.originVector;
            directionVector = this.initialSettings.directionVector;
            checkReceiver = true;
            %fprintf(1, 'Beginning step of shoot: %d sec', toc);
            %receiverCheckTimes = 0;
            %wallCheckTimes = 0;
            %tic
            while (this.distance <= distanceThreshold)
                %tic
                if (length(this.rays) == 24)
                    1;
                end
                this.rays = [this.rays Ray3d(originVector, directionVector)];
                ray = this.rays(end);
                %fprintf(1, 'Ray creation: %d sec\n', toc);
                
                %tic
                if checkReceiver
                    [intersectsReceiver, distRec] = simulation3dContext.getReceiverModel().intersect(ray);
                end
                %temp = toc;
                %receiverCheckTimes = [receiverCheckTimes temp];
                %fprintf(1, 'Receiver check: %d sec\n', temp);
                
                %tic
                [distWall, wall, directionVector] = simulation3dContext.getRoomModel().reflect(ray);
                %temp = toc;
                %wallCheckTimes = [wallCheckTimes temp];
                %fprintf(1, 'Wall check: %d sec\n', toc);
                
                
                if intersectsReceiver && (distRec < distWall)
                    %tic
                    ray.setLength(distRec);
                    this.distance = this.distance + calcSizeInMeters(abs(distRec));
                    this.received = true;
                    this.receptions = [this.receptions Reception(ray, this.walls, this.distance)];
                    originVector = ray.getEndVector();
                    directionVector = ray.getDirectionVector();
                    checkReceiver = false;
                    intersectsReceiver = false;
                    %fprintf(1, 'Handling Receiver incidence of tracing loop: %d sec\n', toc);
                    continue; 
                end
                
                
                %tic
                this.walls(end + 1) = wall;
                ray.setLength(distWall);
                this.distance = this.distance + calcSizeInMeters(abs(distWall));
                originVector = ray.getEndVector();
                checkReceiver = true;
                %fprintf(1, 'Handling wall incidence of tracing loop: %d sec\n', toc);
            end
            %fprintf(1, 'Time of processing particle: %d\n', toc);
            
            %tic
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
            %fprintf(1, 'Last step of tracing loop: %d sec\n', toc);
            %disp('============STOP================')
            %figure()
            %plot(receiverCheckTimes);
            %title('Receiver check Times');
            %xlabel('Check index');
            %ylabel('Time [s]');
            %figure()
            %plot(wallCheckTimes);
            %title('Wall check Times');
            %xlabel('Check index');
            %ylabel('Time [s]');
            
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