function [ server ] = socketclose( server )
%SOCKETCLOSE Closes socket opened by neuroclient and resets structure.
%   TODO: merge with neuroclient
    if isfield(server,'socket') && ~isempty(server.socket)
        server.socket.close;
    end
    server = struct('host', server.host, 'port', server.port);
end

