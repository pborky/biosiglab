function bsl_demo(varargin)
%BSL_DEMO Summary of this function goes here
%   Detailed explanation goes here
    
    bsl_path;
    
    %% Parse arguments
    required = {};
    defaults = struct(...
        'umatfig', @()figure('Name', 'Umatrix and BMUs labeling'),...
        'pcaprojfig', @()figure('Name', 'PCA projection of topological structure and features'),...
        'convcurvefig', @()figure('Name', 'Convergence curve.'));
    defaultnames = fieldnames(defaults);
      
    i = 1;  
    while (i <= length(varargin)),
        name = lower(varargin{i});
        required(strcmp(name , required)) = [];
        defaultnames(strcmp( name , defaultnames)) = [];
        switch name,   
            case 'umatfig'
                i = i + 1;
                umatfig = varargin{i};
            case 'convcurvefig'
                i = i + 1;
                convcurvefig = varargin{i};
            case 'pcaprojfig'
                i = i + 1;
                pcaprojfig = varargin{i};
            otherwise
                fprintf(2, 'Ignoring unrecognized argument (%s)\n', name);
        end;
        i = i + 1;
    end;
    if ~isempty(defaultnames),
        for i = 1:length(defaultnames),
            required(strcmp( defaultnames{i} , required)) = [];
            switch defaultnames{i},
                case 'umatfig'
                    umatfig = defaults.(defaultnames{i})();
                case 'convcurvefig'
                    convcurvefig = defaults.(defaultnames{i})();
                case 'pcaprojfig'
                    pcaprojfig = defaults.(defaultnames{i})();
                otherwise
                    fprintf(2, 'Ignoring unrecognized argument (%s)\n', defaultnames{i});
            end;
        end;
    end;
    if ~isempty(required),
        required = [char(required), repmat(',',length(required),1)]';
        required = required(:); required(required==32) = []; required(end) = [];
        throw(MException('NeuroData:InitFail', ...
            sprintf('Expecting required argument(s) [%s].\n', required)));
    end;
    
    %% initialize process
    trainfig = [ umatfig, pcaprojfig ];
    adjustfig = [ convcurvefig ];
    
    trainactions = {
            @neuro_bining,     {},          [1],       []; 
            @neuro_fourier,    {},          [2 3 4],   [];
            @neuro_som_train,  {},          [5 6 7 8], []; % <- trainsetidx
            @neuro_draw,       {trainfig},  [],        []
        };
    traindags = {
            [ 0 1 0 0;
              0 0 1 0;
              0 0 0 1;
              0 0 0 0 ]
        };
    trainsetidx = 3;
    adjustactions = {
            @neuro_bining,     {},     [1],       []; 
            @neuro_fourier,    {},     [2 3 4],   [];
            @neuro_som_val,    {3},    [5 6 7 8], []; % <- adjustsetidx
        };
    adjustdags = {
            [ 0 1 0;
              0 0 1;
              0 0 0 ]
        };
    adjustsetidx = 3;
    paramspace = {
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
        };
    
    trainexecplan = neuro_mk_exec_plan (trainactions, traindags, paramspace, trainsetidx );
    adjustexecplan = neuro_mk_exec_plan (adjustactions, adjustdags, paramspace, adjustsetidx );
    
    adjfnc = @(data, dataset)  neuro_search_ea (data, dataset, ...
                'PopSize', 20, ...
                'FitFnc', @(d,t) -log(d(1)+1E-2) - log(d(4)+.5) - (.7*d(3)-.7) - 5./(1+10*exp(6-.15*t)),...
                'CrossFitFnc', @(fit, g, fc, t) unique(fc.fps(fit, [], ceil(.35*length(fit)))) ,...
                'MutateFitFnc', @(fit, g, fc, t) unique(fc.fps(-fit, [], ceil((0.05+0.25./(1+10*exp(.11*g-7)))*length(fit)))),...
                'MutateOffsFnc', @(fit, g, fc, t) .05+.25./(1+10*exp(.11*g-7)),...
                'MutateBitFnc', @(fit, g, fc, t) .2 ,...
                'StopCond', @stopcond,... %g == 150, ... 
                'ExecProfile', adjustexecplan, ...
                'ConvergenceCurve', adjustfig,...
                'Verbose', 1 );
    
    %% exec gui
    neurodata(  'Actions', {'relax', 'eyes', 'right', 'left'}, ...
                'Server',  {'host','localhost', 'port' ,8336}, ...
                'AdjustFnc', adjfnc, ...
                'TrainExecProfile', {trainexecplan, [], 1} );
    
    %% stop condition
    function [cnd ] = stopcond(fit, gen, fc, t)
        plateau = 30;
        if gen < plateau,
            cnd = ~~0;
            return;
        end;
        g0 = gen - plateau;
        m0 = max(t.fitness(t.generations==g0));
        m = max(t.fitness(t.generations==gen));
        if m ~= m0,
            cnd = ~~0;
            return;
        end;
        if max(t.fitness(t.generations > g0-1 & t.generations < gen-1)) > m,
            cnd = ~~0;
            return;
        end;
        cnd = ~~1;
    end
end

