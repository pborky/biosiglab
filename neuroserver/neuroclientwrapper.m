function [ server, message ] = neuroclientwrapper( server, command )
%NEUROCLIENTWRAPPER Calls neuroclient and handles its exceptions.
%
%   Usage
%       [ server, message ] = neuroclient( server, command )
%       inputs
%           server  - structure holding the server control variables
%           command - char matrix to send to the server, it is filled with line
%                   terminators to each row from right
%       output
%           server  - structure holding the server control variables
%           message - char matrix received data

    if nargin < 2, command = []; end;
    go = 3;
    while (go),
        try
            [ server, message ] = neuroclient( server, command );
        catch e
            fprintf(2, '\nWarning: NeuroClient: got exception: %s.\n', [ e.identifier e.message ]);
            fprintf(2, '\tRetrying..\n');
            server = socketclose(server);
            go = go - 1;
            if go == 0, throw(e); end;
            continue;
        end;
        if isempty(message),
            fprintf(2, '\nWarning: NeuroClient: got wrong response.\n\tRetrying..\n');
            server = socketclose(server);
            go = go - 1;
            continue;
        end;
        break;
    end;