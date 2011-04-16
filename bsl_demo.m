
% waveedges = [ [0;2] [2;4] [4;7.5] [7.5;9.5] [9.5;11.5] [11.5;15] [15;22] [22;30] ];
% wavenames = {'delta1', 'delta2', 'theta', 'alfa1', 'alfa2', 'smr', 'beta1', 'beta2', 'gamma' };
% 
% load dataset.mat;

% data = struct();
% data.X = X;
% data.y = y;
% data.fsampl = 4000;
% data.labels = labels;

%data = struct('X', data{1}.data', 'fsampl', data{1}.head.SampleRate, 'y', zeros(1,size(data{1}.data, 1)));
data = struct();
data.labels = dataset{1}.classes;
data.X = dataset{1}.X';
data.y = dataset{1}.y';
data.fsampl = dataset{1}.edf{1}.head.SampleRate;

plan = bsl_exec_plan ({
        @neuro_bining,     {},     [1],    []; 
        @neuro_fourier,    {},     [2 3 4], [];
        @neuro_som_train,  {},     [],     [];
        @neuro_evaluate,   {},     [],     [];
        @neuro_draw,       {},     [],     []
    }, [
        0 1 0 0 0;
        0 0 1 0 0;
        0 0 0 1 0;
        0 0 0 0 1;
        0 0 0 0 0
    ],{
        [256 500 1000 2000 4000];   % f samp reduced
        [256 500 1000 2000 4000];   % time window before transform
        [ 10 20 50 ];               % number of steps inside one window
        [
            0  20; 
            20 250
        ]                           % frequency filters (column vetors of 2 components)
    } );

%plan = bsl_dag_dfs(data, plan, [], 1000, 1000, 5, [ 0; 20] );
plan = bsl_dag_dfs(data, plan, [], 1000, 1000, 5, [20;250] );

% init neuroclient

[ server ] = edfstatus( struct('host', 'localhost', 'port', 8336) );
edfdata( server, .8, [], 1, 20, @(data) neuro_classify(data, plan.def{4,4}{1}) );

    