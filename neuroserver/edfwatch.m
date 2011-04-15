function [ server, data ] = edfwatch( server, limit, equip )
%EDFWATCH Sends watch command to neuroserver, waits for response for
%specified time limit. Then it sends unwatch command. Output structure is
%cell array with one element for each equipment. Each element contains
%atribute data and header for edf-data and edf-header.
%
%   Usage
%       [ server, data ] = edfwatch( server, limit, equip )
%       inputs
%           server  - structure holding the server control variables
%           limit   - time in seconds to watch
%           equip   - vector of equip ids if empty all EEG is used.
%       output
%           server  - structure holding the server control variables
%           data    - output data structure

    %% Initial check
    % if not specified take all
    if nargin < 1,
        throw(MException('NeuroClient:IllegalArgument',...
            'Wrong number of arguments to function edfwatch.'));
    end;
    if nargin < 3, equip = server.eeg; end;
    if isempty(equip), 
        throw(MException('NeuroClient:IllegalArgument',...
            'No equipment selected.'));
    end;
    
    if ~isfield(server,'watching'), server.watching = 0; end;
    
    %% Receiving data
    endtime = now + (limit/(60*60*24)); tries = 0; data = cell(0);    
    while (now<=endtime) || server.watching,
        %% send watch command
        if ~server.watching,
            cmd = {};
            for e = equip, cmd{end+1} = ['watch ',int2str(e)]; end;
            cmd = char(cmd);
            fprintf('Receiving.');
            [ server, message ] = neuroclientwrapper( server, cmd );
            if ~isempty(message), data{end+1} = message; end;
            server.watching = 1;
        else
            %% receiving data
            if (now<=endtime),
                fprintf('.');
                [ server, message ] = neuroclient( server );        
                if isempty(message),
                    tries = tries + 1;
                    if tries>30, 
                        throw(MException('NeuroClient:NoData',...
                            'No message received.')); 
                    end;
                else
                    tries = 0;
                    data{end+1} = message;
                end;
            else
            %% send unwatch command
                fprintf('.');
                cmd = {};
                for e = equip, cmd{end+1} = ['unwatch ',int2str(e)]; end;
                cmd = char(cmd);
                [ server, message ] = neuroclientwrapper( server, cmd );
                if ~isempty(message), data{end+1} = message; end;
                fprintf('\n');
                server.watching = 0;
            end;
        end;
    end
    data = char(data);
end

