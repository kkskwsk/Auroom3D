function [V, F] = parseRoomFile(filename) 
    V = zeros(0, 3);
    F = zeros(0, 3);
    vertex_index = 1;
    face_index = 1;
    fid = fopen(filename, 'r');
    if fid == -1
        msgID = 'PARSER:FileDoesntExist';
        msg = 'This file doesnt exist!';
        exception = MException(msgID, msg);
        throw(exception);
    end
    line = fgets(fid);
    
    
    while ischar(line)
        vertex = sscanf(line,'v %d %d %d');
        face = sscanf(line,'f %d %d %d');
        
        if size(vertex) > 0
            V(vertex_index,:) = vertex;
            vertex_index = vertex_index + 1;
        elseif size(face,1) == 3
            F(face_index, :) = face;
            face_index = face_index + 1;
        else
            msgID = 'PARSER:BadFileFormat';
            msg = 'Wrong format of room file.';
            exception = MException(msgID, msg);
            throw(exception);
        end
        
        line  = fgets(fid);
    end
    
    fclose(fid);
end

