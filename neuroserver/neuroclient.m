function [ server, message ] = neuroclient( server, command )
%NEUROCLIENT Low level function to communication with neuroserver based on
%java classes. I sends command to server and receives response data. 
%
%   Usage
%       [ server, message ] = neuroclient( server, command )
%       inputs
%           server  - structure holding the server control variables
%           command - char matrix to send to the server, it is filled with line
%                 terminators to each row from right
%       output
%           server  - structure holding the server control variables
%           message - char matrix received data

    %% Initialize
    import java.net.Socket
    import java.io.*
    
    message = [];
    if ~isfield(server,'socket'),
        server.socket = [];
    end
    
    try
        %% Create socket enter display mode
        if (isempty(server) || isempty(server.socket) || ~server.socket.isConnected || server.socket.isClosed)
            server.socket = Socket(server.host, server.port);
            server.socket.setKeepAlive(1);
            server.istream = BufferedReader(InputStreamReader(server.socket.getInputStream));
            server.ostream = OutputStreamWriter(server.socket.getOutputStream);
            cmd = char(['display',10]);
            server.ostream.write(cmd, 0, length(cmd));
            server.ostream.flush;
            while ~server.istream.ready, pause(.001); end;
            message = char(server.istream.readLine);
            if isempty(message), throw(MException('NeuroClient:InitFailed',['Empty response.' message])); end;
            if length(message) < 6 || ~strcmp('200 OK',char(message(1:6)))
                throw(MException('NeuroClient:WrongData', ['Unexpected response: ' message]));
            end;
            %disp(char(message));
        end
        
        %% Send command
        if (nargin > 1 && ~isempty(command));
            command(:,end+1) = 13;
            command(:,end+1) = 10;
            command = command';
            cmd = command(:)';
            server.ostream.write(cmd, 0, length(cmd));
            server.ostream.flush;
            go = 100; while go && ~server.istream.ready, pause(.001); go = go -1; end;
        end
        
        %% Receive data 
        i = 1; initsize = 5000;
        msg = cell(1,floor(initsize*1.1));
        while (true)
            msg{i} = char(server.istream.readLine);
            go = 100; while go && ~server.istream.ready && i < initsize, go = go - 1 ; pause(.001); end;
            if ~server.istream.ready, break; end;
            i = i+1;
        end;
        message =  char(msg(1:i));
    catch e
        %% Error handling
        if (isfield(server,'socket') && ~isempty(server.socket))
            server.socket.close;
            server.socket = [];
            server.watching = 0;
        end
        throw(e);
    end
end

