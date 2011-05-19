function [ win ] = bsl_demo_ea ( data )
    bsl_path;
    % neurodata('Actions', {'relax', 'eyes', 'right', 'left'}, ...
    %           'Server',  {'host','localhost', 'port' ,8336});
    
    % precalculated parameter space
    load dataset.mat;
    
    %% initialize dataset and execution profile
    d = struct();
    d.labels = data.dataset.classes;
    d.X = data.dataset.X';
    d.y = data.dataset.y';
    d.fsampl = data.dataset.edf{1}.head.SampleRate;
    data = d;
    fig = [ ];
    exec = neuro_mk_exec_plan ({
            @neuro_bining,     {},     [1],       []; 
            @neuro_fourier,    {},     [2 3 4],   [];
            @neuro_som_train,  {},     [5 6 7 8], [];
            @neuro_draw,       {fig},  [],        []
        }, { [
            0 1 0 0 0;
            0 0 1 0 0;
            0 0 0 1 0;
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
        } ,3);    
    % winner = {4000, 2000, 2, [20;200], 'histD', 'batch', 'rect', 'normal'}
    % winner = {1333, 800, 8, [20;200], 'logistic', 'batch', 'rect', 'normal'}

    
    cfg1 = struct( 'popsize',      25, ...
                    'crossfitfnc',	@(fit, g, fc, t) fit >= prctile(fit, 70), ...
                    'mutatefitfnc',	@(fit, g, fc, t) fit <= prctile(fit, 30), ...
                    'mutateoffsrate', 0.3, ...
                    'mutatebitrate',	0.2, ...
                    'fitfnc',       @(d,t) -log(d(1)+.0001) - log(d(4)+.6) - log(d(3)+.5) - 5./(1+10*exp(6-.15*t)), ...
                    'stopcond',     @(fit, g, fc, t) stopcond(fit, g, fc, t, 40) ...
                    );
    cfg2 = struct(  'popsize',      20, ...
                    'crossfitfnc',	@(fit, g, fc, t) unique(fc.fps(fit, [], ceil(.35*length(fit)))) , ...
                    'mutatefitfnc',	@(fit, g, fc, t) unique(fc.fps(-fit, [], ceil((0.05+0.25./(1+10*exp(.11*g-7)))*length(fit)))), ...
                    'mutateoffsfnc',@(fit, g, fc, t) .05+.25./(1+10*exp(.11*g-7)), ...
                    'mutatebitfnc',	@(fit, g, fc, t) .2, ... % .05+.25./(1+50*exp(-.4*(g))), ...
                    'stopcond',     @(fit, g, fc, t) g == 100, ... %stopcond(fit, g, fc, t, 30), ...
                    'fitfnc',       @(d,t) -log(d(1)+1E-2) - log(d(4)+.5) - (.7*d(3)-.7) - 5./(1+10*exp(6-.15*t)), ...
                    'verbose',      0 ... %     val. err.       win. size       top. err.         exec. time
                    );

    %% run genetic algorithm
    win = [];
    pop = [];
    gen = 0;
    f = -inf;
    fm = [];
    for i = 1:50,
        fprintf('########## iteration %i\n', i);
        [ winner, fitness, timeline, dataset ] = bsl_ea( dataset, cfg2, [] );
        
        if f < max(fitness),
            f = max(fitness);
            win = winner(f == fitness,:);
        else 
            win = [win; winner(f == fitness,:)];
        end;
        
        pop = [pop;timeline.populations];
        gen = gen + max(timeline.generations);
        win = deduplicate(win);
        pop = deduplicate(pop);
        
        [nv, nr] = size(fm);
        g = unique(timeline.generations(:));
        fitness = zeros(size(g));
        for j = g',
            fitness(j+1) = max(timeline.fitness(timeline.generations==j));
        end;
        nf = length(fitness);
        if nv < nf,
            fm = [[fm;nan(nf - nv, nr)],fitness];            
        elseif nv > length(fitness),
            fm = [fm,[fitness;nan(nv - nf, 1)]];
        else
            fm = [fm,fitness];
        end;
    end;
    
    fprintf('after %i generations, %i states visited, winner`s fitness: %.3f\n', ...
        gen, size(pop, 1), f);
    
    %% visualise
    
    figure;
    x = 0:size(fm,1)-1;
    plot(x,mean(fm,2),'b');
    hold on;
    plot(x,mean(fm,2)+std(fm,0,2),'y');
    plot(x,mean(fm,2)-std(fm,0,2),'y');
    plot(x,max(fm,[],2),'g');
    plot(x,min(fm,[],2),'r');
    hold off;
    title('');
    h= legend('mean','mean+std','mean-std', 'max','min');
    h1 = findobj(get(h,'Children'),'String','mean'); set(h1,'String','$\mu$','Interpreter','latex');
    h1 = findobj(get(h,'Children'),'String','mean+std'); set(h1,'String','$\mu\texttt{+}\sigma$','Interpreter','latex');
    h1 = findobj(get(h,'Children'),'String','mean-std'); set(h1,'String','$\mu\texttt{-}\sigma$','Interpreter','latex');
    xlabel('generation');
    ylabel('fitness');
    
    nwin = size(win,1);
    profile = [repmat({exec, 1, 1}, nwin, 1) num2cell(win+1)];
    for i = 1:nwin,
        fprintf('winner: %i %i %i %i %i %i %i %i\n', win(i,:));
        res = neuro_exec(data, profile{i,:}); 
    end;

    %% deduplicate data    
    function [ population ]  = deduplicate( population )
        
        nspecies = size(population, 1);
        duplicates = ~~zeros(nspecies,1);
        for c = 1:nspecies,
            if duplicates(c), continue; end;
            m = find(min(repmat(population(c,:), [ size(population,1), 1]) == population, [], 2));
            m(1) = [];
            duplicates(m) = 1;
        end;
        population(duplicates,:) = [];
    end
    %% stop condition
    function [cnd ] = stopcond(fit, gen, fc, t, plateau)
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
