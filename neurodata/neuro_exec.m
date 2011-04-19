function actions = neuro_exec ( data, actions, action, varargin )  

    %% input checks
    if nargin < 3,
        fprintf(2, 'Expecting at least 3 parameters. Exiting..');
        return;
    end;
    if isempty(action), action = find(sum(actions.dag,1)==0); end;
    if length(action) ~= 1,            
        fprintf(2, 'Expecting exactly one root. Choosing %i..', action(1));
    end;
    
    %% DFS
    action = action(1);
    nextactions = find(actions.dag(action,:));
    actiondef = actions.def(action, :);
    if ~isfield(data,'params'), data.params = {[]}; end;
    data.params{1} = [data.params{1} action];
    data.params = [data.params, varargin{actiondef{3}}];
    data2 = gethist( actiondef{4}, data.params);
    if isempty(data2),
        [ data2 ] = actiondef{1}(data, actiondef{2}{:}, varargin{actiondef{3}});
        actions.def{action, 4}{end+1} = data2;
    end;
    for nextaction = nextactions(:)',
        actions  = neuro_exec ( data2, actions, nextaction, varargin{:} );
    end;

function [ hist ] = gethist( data, params )
    if isempty(data) || isempty(params), 
        hist = [];
        return;
    end;
    hist = [];
    for i = 1:length(data),
        b = 1;
        if length(data{i}.params) == length(params),
            for j = 1:length(data{i}.params),
                if ~strcmp(class(data{i}.params{j}), class(params{j})) || ...
                        ( ischar(data{i}.params{j}) && ~strcmp(data{i}.params{j}, params{j}) ) ||...
                        ( ismatrix(data{i}.params{j}) && length(size(params{j}))~=length(size(data{i}.params{j})) && max(size(params{j}))~=max(size(data{i}.params{j}))) ||...
                        max(data{i}.params{j} ~= params{j}),
                    b = 0;
                    break;
                end;
            end;
            if b, 
                hist = data{i}; 
                return;
            end;
        end;
    end;