function [ server ] = edfstatus( server )
%EDFSTATUS Retrieves status of neuroserver and sets up fields .clients and .eeg.
%Field .clients contains information about of all clients and .eeg
%contains identifiers of registered EEG devices on servers.
%
%   Usage
%       [ server ] = edfstatus( server )
%       inputs
%           server  - structure holding the server control variables
%       output
%           server  - structure holding the server control variables

    [ server, message ] = neuroclientwrapper( server, 'status' );
    
    if isempty(message), throw(MException('NeuroClient:InitFailed',['Empty response.' message])); end;
    if length(message) < 6 || ~strcmp('200 OK',char(message(1,1:6))),        
        throw(MException('NeuroClient:WrongData', ['Unexpected response: ' message]));
    end;
    nclients = str2double(message(2,1:(find(message(2,:) == 32, 1, 'first')-1)));
    server.clients = cell(1,nclients);
    server.eeg = [];
    for i = 1:nclients
        s = strsplit(message(i+2,:),':');
        server.clients{i}.id = str2double(s{1});
        server.clients{i}.role = s{2}(s{2} ~= 32);
        if strcmp(server.clients{i}.role,'EEG'),
            server.eeg = [server.eeg server.clients{i}.id];
        end;
    end;
end

