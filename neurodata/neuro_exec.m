function actions = neuro_exec ( data, actions, action, idag, varargin )  

    %% input checks
    if nargin < 3,
        fprintf(2, 'Expecting at least 3 parameters. Exiting..');
        return;
    end;
    % obtain dag
    if iscell(actions.dag), dag = actions.dag{idag}; else dag = actions.dag; end;
    % if action is unspecified search for root node(s) in DAG
    if isempty(action), action = find(sum(dag,1)==0); end; 
    % but we work only with one node..
    if length(action) ~= 1,
        action = action(1);
        fprintf(2, 'Expecting exactly one root. Choosing %i..', action(1));
    end;
    
    %% DFS
    % details for execution
    actiondef = actions.def(action, :);
    params = actions.params(actiondef{3});
    % choose param from search space
    for i = 1:length(params),
        p = params{i};
        params{i} = p(:, varargin{actiondef{3}(i)});
        if iscell(params{i}) && length(params{i}) == 1 && ~isnumeric(params{i}{1}),
            params{i} = params{i}{1};
        end;
    end;
    % if there is precalculated result use it
    % TODO: data should be cell array and should be filled by call of parent nodes 
    if ~isfield(data,'params'), data.params = {[]}; end;
    data.iparams = reshape(cell2mat(varargin), 1,[]);
    data.params{1} = [data.params{1} action];
    data.params = [data.params, reshape(params, 1,[])];
    data2 = gethist( actiondef{4}, data.params);
    if isempty(data2),
        tic;
        [ data2 ] = actiondef{1}(data, actiondef{2}{:}, params{:});
        if isfield(actions,'maxtics') && toc > actions.maxtics, 
            throw(MException('BSL:TimeRunnedOut', 'Time for single operation runned out.')); 
        end;
        if ~isempty(data2),
            actions.def{action, 4}{end+1} = data2;
        end;
    end;
    % find edges and traverse there 
    nextactions = find(dag(action,:));
    for nextaction = nextactions(:)',
        actions  = neuro_exec ( data2, actions, nextaction, idag, varargin{:} );
    end;

function [ hist ] = gethist( data, params )
    hist = [];
    if isempty(data) || isempty(params),
        return;
    end;
    for i = 1:length(data),
        if compareparams(data{i}.params, params),
            hist = data{i};
        end;
    end
    
function [ match ] = compareparams(params1, params2)
    match = 1;
    if iscell(params1) && iscell(params2) && length(params1) == length(params2),
        for j = 1:length(params1),
            % not same dataclass
            if ~strcmp(class(params1{j}), class(params2{j})) ...
                    && xor(ismatrix(params1{j}), ismatrix(params2{j})),
                match = 0; 
                return;
            end;
            % function handle
            if strcmp(class(params1{j}),'function_handle'),
                if ~strcmp(func2str(params1{j}),func2str(params2{j})),
                    match = 0; 
                    return;
                else
                    continue;
                end;
            end;
            % compare stings 
            if ischar(params1{j}),
                if ~strcmp(params1{j}, params2{j}),
                    match = 0; 
                    return;
                else
                    continue;
                end;
            end;
            % matrix
            if ismatrix(params1{j}),
                if (ndims(params1{j})~=ndims(params2{j}) ...
                        || max(size(params1{j})~=size(params2{j})) ...
                        || max(params1{j}(:) ~= params2{j}(:))),
                    match = 0; 
                    return;
                else
                    continue;
                end;
            end;
            % maybe same as matrix..
            if isnumeric(params1{j}),
                if max(params1{j} ~= params2{j}),
                    match = 0; 
                    return;
                else
                    continue;
                end;
            end;
        end;
    else
        match = 0;
        return;
    end;

        