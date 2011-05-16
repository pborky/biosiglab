function [  ] = bsl_demo_nia( chromosome, exec )
%BSL_DEMO_SOM Summary of this function goes here
%   Detailed explanation goes here
    
    bsl_path;
    
    execplan = neuro_mk_exec_plan ({
            @neuro_bining,     {},     [1],    []; 
            @neuro_fourier,    {},     [2 3 4], [];
            @neuro_som_train,  {},     [5 6 7 8],     []; % <- trainsetidx
            @neuro_evaluate,   {},     [],     [];
            @neuro_draw,       {},     [],     []
        }, { [
            0 1 0 0 0;
            0 0 1 0 0;
            0 0 0 1 0;
            0 0 0 0 1;
            0 0 0 0 0
        ] },{
            [256 666 1333 4000]; % f samp reduced
            [80 200 800 2000];  % time window before transform
            [2 8];     % number of steps inside one window
            [
                0   20;
                50 200
            ]; % frequency filters (column vetors of 2 components)
            {'histD', 'log', 'var', 'logistic'};
            {'seq', 'batch'};
            {'hexa', 'rect'};
            {'small', 'normal'} % frequency filters (column vetors of 2 components)
        } ); 
        
    neurodata('Actions', {'relax', 'eyes', 'right', 'left'}, ...
              'Server',  {'host','localhost', 'port' ,8336}, ...
              'ExecProfile', [{exec, 1, 1} num2cell(chromosome+1)], ...
              'TrainSetIdx', 3);

end

