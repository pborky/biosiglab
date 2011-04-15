function [ server, data ] = edfdata( server, limit,  equip  )
%EDFDATA Retrieve data and header from specifeid equipments.
%
%   Usage
%       [ server, data ] = edfdata( server, limit,  equip  )
%       inputs
%           server  - structure holding the server control variables
%           limit   - time in seconds to watch
%           equip   - vector of equip ids if empty all EEG is used.
%       output
%           server  - structure holding the server control variables
%           data    - output data structure

    %% initialize and retrieve data
    starttime = now;
    [ server ] = edfstatus (server);
    if nargin < 3 || isempty(equip), equip = server.eeg; end;
    [ server, message ] = edfwatch( server, limit, equip );
    data = cell(size(equip));
    fprintf ('Receiving headers.');
    for e = equip, 
        [ server, data{e == equip}.head ] = edfheader(server, e); 
        fprintf ('.');
    end;
    fprintf ('\nReceiving duration %.1fsec.\n', 24*60*60*(now - starttime));
    %[ server ] = socketclose(server);
    starttime = now;
    
    %% process received data
    message = message(message(:,1)=='!', 3:end);
    if ~isempty(message),
        for e = equip,
            % we expect e is always one digit..
            sel = find(message(:,1) == int2str(e));
            line = message(sel(1),:);
            ind = find(line == 32);
            line = str2num(line);
            lines = message(sel,ind(3)+1:end);
            if isempty(lines), continue; end;
            x = str2num(lines);
            if isempty(x),
                throw(MException('NeuroClient:WrongData', 'Received data is not consistent.'));
            end;
            if line(3) ~= size(x,2),
                fprintf (2, 'Channel count inconsistent.\n');
            end;
            data{equip == e}.data = x;
        end;
    end;
    fprintf ('Postprocessing duration %.1fsec.\n', 24*60*60*(now - starttime));
    
end

