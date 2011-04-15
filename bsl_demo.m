
% waveedges = [ [0;2] [2;4] [4;7.5] [7.5;9.5] [9.5;11.5] [11.5;15] [15;22] [22;30] ];
% wavenames = {'delta1', 'delta2', 'theta', 'alfa1', 'alfa2', 'smr', 'beta1', 'beta2', 'gamma' };
% 
% load dataset.mat;

% data = struct();
% data.X = X;
% data.y = y;
% data.fsampl = 4000;
% data.labels = labels;

plan = bsl_exec_plan ({
        @pb_bining,     {},     [1],    []; 
        @pb_fourier,    {},     [2 3 4], [];
        @pb_som_train,  {},     [],     [];
        @pb_evaluate,   {},     [],     []
    }, [
        0 1 0 0;
        0 0 1 0;
        0 0 0 1;
        0 0 0 0
    ],{
        [256 500 1000 2000 4000];   % f samp reduced
        [256 500 1000 2000 4000];   % time window before transform
        [ 10 20 50 ];               % number of steps inside one window
        [
            0  20; 
            20 250
        ]                           % frequency filters (column vetors of 2 components)
    } );

plan = pb_dag_dfs(data, plan, [], 1000, 1000, 5, [ 0; 20] );
plan = pb_dag_dfs(data, plan, [], 1000, 1000, 5, [20;250] );
    