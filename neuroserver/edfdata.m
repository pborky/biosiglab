function [ server, data ] = edfdata( server, limit,  equip, getheader, steps, callback  )
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
    %starttime = now;
    [ server ] = edfstatus (server);
    if nargin < 3 || isempty(equip), equip = server.eeg; end;
    if nargin < 4 || isempty(getheader), getheader = 1; end;
    if nargin < 6, steps = 1; callback = []; end;
    data = cell(size(equip));
    if getheader,
        fprintf (2, 'Receiving headers.\n');
        for e = equip, 
            [ server, data{e == equip}.head ] = edfheader(server, e); 
            %fprintf ('.');
        end;
    end;
    while steps, 
        steps = steps - 1;
        fprintf (2, 'Receiving data.\n');
        [ server, message ] = edfwatch( server, limit, equip );
        %fprintf ('\nReceiving duration %.1fsec.\n', 24*60*60*(now - starttime));
        %[ server ] = socketclose(server);
        %starttime = now;

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
                if ~isfield(data{equip == e},'data') || isempty(data{equip == e}.data),
                    data{equip == e}.data = x;
                else
                    data{equip == e}.data = [data{equip == e}.data; x];
                end;
            end;
        end;
        %fprintf ('Postprocessing duration %.1fsec.\n', 24*60*60*(now - starttime));
        if ~isempty(callback), callback(data); end;
    end;
end

