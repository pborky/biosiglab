function [ dataset ] = bsl_precompute( data )
%PRECOMPUTE Summary of this function goes here
%   Detailed explanation goes here

    %% setup path
    bsl_path;


    %% initialize dataset and execution profile
    d = struct();
    d.labels = data.dataset.classes;
    d.X = data.dataset.X';
    d.y = data.dataset.y';
    d.fsampl = data.dataset.edf{1}.head.SampleRate;
    data = d;

    exec = neuro_mk_exec_plan ({
            @neuro_bining,     {},     [1],     []; 
            @neuro_fourier,    {},     [2 3 4], [];
            @neuro_som_val,    {3},    [5 6 7 8],      []
        }, { [
            0 1 0 0 0;
            0 0 1 0 0;
            0 0 0 0 0;
            0 0 0 0 0;
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
            {'small', 'normal'}
        } );
    % exec.maxtics = 25;
    dataset =[];
    % validation err | mean quantization error | topographic error | window  size [sec]
    fitfnc = @(d) [d.eval d.params{3}/d.fsampl]; 
    nfit = 4;
    [ dataset ] = do( data, exec, dataset, fitfnc, nfit );

    function [ dataset ] = do( data, exec, dataset, fitfnc, nfit )
    %BSL_PRECOPUTE Summary of this function goes here
    %   Detailed explanation goes here

        profile{1} = exec;
        profile(2:3) = {1 1};
        ngenes = length(profile{1}.params);
        genesizes = zeros(1, ngenes);
        for g = 1:ngenes,
            genesizes(g) = size(profile{1}.params{g}, 2);
        end;
        nspec = prod(genesizes);
        dataset.chromosomes = nan(nspec,ngenes);
        dataset.fitness = nan(nspec,nfit);
        dataset.runningtime = nan(nspec,1);
        counters = zeros(1,ngenes);
        counters(end) = -1;
        for i = 1:nspec,
            for j = ngenes:-1:1,
                counters(j) = counters(j)+1;
                if counters(j) >= genesizes(j),
                    counters(j) = 0;
                else
                    break;
                end;
            end;
            tm = mean(dataset.runningtime(~isnan(dataset.runningtime)))*(nspec-i);        
            fprintf(['(%4.1f%% %8.0fsec) [ ' repmat('%2i,',1,ngenes-1) '%2i ] '], 100*i/nspec, tm, counters);
            dataset.chromosomes(i,:) = counters;

            profile(4:4+ngenes-1) = num2cell(counters+1);
            tic;
            try                 
                res = neuro_exec(data, profile{:});
            catch e,
                fprintf(2, 'Exception\n');
                dataset.fitness(i,:) = nan;
                dataset.runningtime(i) = nan;
                continue;
            end;
            a = 1;
            for j = length(res.def{3,4}):-1:1,
                if ~~min(counters+1 == res.def{3,4}{j}.iparams),
                    res = res.def{3,4}{j};
                    a = 0;
                    break;
                end;
            end;
            if a, 
                fprintf(2, 'Oops! No result found!\n'); 
                dataset.fitness(i,:) = nan;
                dataset.runningtime(i) = nan;
                continue; 
            end;
            % assign results
            dataset.fitness(i,:) = fitfnc(res);
            dataset.runningtime(i) = toc;
            fprintf(['fit: [ ',repmat('%5.2f,',1,nfit-1),'%5.2f ] time: %5.2f\n'],dataset.fitness(i,:), dataset.runningtime(i)); 
        end;

    end

end

