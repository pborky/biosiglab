function [ winner, wfitness, timeline, dataset ] = neuro_search_ea( data, dataset, varargin )
%NEURO_SEARCH_EA Summary of this function goes here
%   Detailed explanation goes here

    %% Parse arguments
    required = {'popsize', 'fitfnc', 'crossfitfnc', 'mutatefitfnc', 'stopcond',...
                'execprofile', 'mutateoffsfnc', 'mutatebitfnc'};
    defaults = struct('verbose', 0);
    defaultnames = fieldnames(defaults);
      
    i = 1;  
    while (i <= length(varargin)),
        name = lower(varargin{i});
        required(strcmp( name , required)) = [];
        defaultnames(strcmp( name , defaultnames)) = [];
        switch name,
            case 'popsize' 
                i = i + 1;
                popsize = varargin{i};
            case 'fitfnc' 
                i = i + 1;
                fitfnc = varargin{i};
            case 'crossfitfnc' 
                i = i + 1;
                crossfitfnc = varargin{i};
            case 'mutatefitfnc' 
                i = i + 1;
                mutatefitfnc = varargin{i};
            case 'mutatebitfnc' 
                i = i + 1;
                mutatebitfnc = varargin{i};
            case 'mutateoffsfnc'
                i = i + 1;
                mutateoffsfnc = varargin{i};                
            case 'stopcond' 
                i = i + 1;
                stopcond = varargin{i};
            case 'verbose' 
                i = i + 1;
                verbose = varargin{i};
            case 'initialpop' 
                i = i + 1;
                init = varargin{i};
            case 'execprofile' 
                i = i + 1;
                profile = { varargin{i}, [] };     
            case 'convergencecurve'
                i = i + 1;
                convergencecurve = varargin{i};      
            otherwise
                fprintf(2, 'Ignoring unrecognized argument (%s)\n', name);
        end;
        i = i + 1;
    end;
    if ~isempty(defaultnames),
        for i = 1:length(defaultnames),
            required(strcmp( defaultnames{i} , required)) = [];
            switch defaultnames{i},
                case 'verbose'
                    verbose = defaults.(defaultnames{i});
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
    
    %%
    fnc = struct;
    fnc.fps = @fps;
    fnc.sus = @sus;
    fnc.deduplicate = @deduplicate;
    fnc.p2g = @phenotype2genotype;
    fnc.g2p = @genotype2phenotype;
    fnc.num2gene = @num2gene;
    fnc.gene2num = @gene2num;
    
    %% initialize dataset and execution profile
    ngenes = length(profile{1}.params)+1;
    genesizes = zeros(1, ngenes);
    if iscell(profile{1}.dag),
        genesizes(1) = ceil(log2(length(profile{1}.dag)));
    else
        genesizes(1) = 0;
    end;
    for g = 2:ngenes,
        genesizes(g) = ceil(log2(size(profile{1}.params{g-1}, 2)));
    end;
    dataset = initdataset(dataset, genesizes);
    
    %% initial random population, possibily uniformly distributed
    if exist('init'),
        populations = init;
    else
        populations = initpop(genesizes, popsize);
    end;
    generations = zeros(size(populations,1),1);
    fitness = -inf(size(populations,1),1);
    runingtime = inf(size(populations,1),1);
    gen = 0;
    go = 1;
    
    %%
    while (go),
        %% initialize
        fitness(end+1:size(populations,1)) = -inf;
        runingtime(end+1:size(populations,1)) = inf;
        generations(end+1:size(populations,1)) = gen;
        ipopulation = generations==gen;
        popcount = sum(ipopulation);
        printlog(verbose,'\n####\tgen: %.0f count: %.0f\n\n', gen, popcount);
        %% calculate fitness for actual gen
        for i = find(ipopulation)',
            printlog(verbose,[' ***\tspecie: [ ' repmat('%2i,',1,ngenes-1) '%2i ]\t'], populations(i,:));
            [ fit, rt ] = getdataset ( dataset, populations(i,:) );
            if (isempty(fit) || isempty(rt)),
                profile(3:3-1+ngenes) = num2cell(populations(i,:)+1);
                tic;
                try                 
                    res = neuro_exec(data, profile{:});
                catch e,
                    fprintf(2, 'Exception\n');
                    runingtime(i) = NaN;
                    fitness(i) = NaN;
                    [ dataset ] = putdataset ( dataset, populations(i,:), NaN, NaN );
                    continue;
                end;
                rt = toc;
                resultfound = 0;
                for j = length(res.def{res.resultsetidx,4}):-1:1,
                    if ~~min(populations(i,:)+1 == res.def{res.resultsetidx,4}{j}.iparams),
                        res = res.def{res.resultsetidx,4}{j};
                        fit = [res.eval res.params{3}/res.fsampl];
                        resultfound = 1;
                        break;
                    end;
                end;
                if ~resultfound,
                    runingtime(i) = NaN;
                    fitness(i) = NaN;
                    [ dataset ] = putdataset ( dataset, populations(i,:), NaN, NaN );
                    continue;
                end;
                [ dataset ] = putdataset ( dataset, populations(i,:), fit, rt );
            end;
            if ~(isempty(fit) || isempty(rt)),
                runingtime(i) = rt;
                fitness(i) = fitfnc(fit,rt);
                printlog(verbose,['eval: [ ',repmat('%5.2f,',1,length(fit)),'%6.2f ] fitness: %5.2f\n'], fit, runingtime(i), fitness(i));
            else                
                printlog(verbose,2, 'Oops! No result found!\n');
                runingtime(i) = NaN;
                fitness(i) = NaN;
            end;
        end;
        %% preselection 
        % prefilter long running and failing configurations
        iprefilter = ipopulation & ~isnan(fitness);% & ~(runingtime > maxtime);
        % if no one survived give another chance or end with error
        if max(iprefilter)==0,
            if gen == 0,
                gen = gen + 1;
                printlog(verbose,2, '\n####\tInitialization failed, no configuration passed timing constraint. Giving another chance..');
                populations = [populations; initpop(genesizes, popsize)];
                continue;
            else
                printlog(verbose, 2, '\n####\tNo configuration passed timing constraint, try raise limit. Breaking..');
                winner = [];
                wfitness = 0;
                timeline = struct(  'phenotypes', populations, ...
                                    'generations', generations, ...
                                    'fitness', fitness, ...
                                    'runingtime', runingtime );
                return;
            end;
        end;
        %% selection on rest
        iselected = ~~zeros(size(iprefilter));
        % Stochastic universal sampling
        iselected(sus(fitness, iprefilter, popsize)) = 1;
        % Fitness proportionate selection
        % iselected(fps(fitness, iprefilter, popsize)) = 1;        
        
        printlog(verbose, '\n####\t%.0f of %.0f species survived.\n', sum(iselected), popcount);
        
        %% check finishing condition  
        t = struct;
        t.generations = generations;
        t.runingtime = runingtime;
        t.fitness = fitness;
        if stopcond(fitness(iselected), gen, fnc, t),           
            printlog(verbose, '\n####\tStop condition reached.\n\n');
            wfitness = max(fitness(iselected));            
            winner = populations((fitness == wfitness) & iselected,:);
            timeline = struct(  'populations', populations, ...
                                'generations', generations, ...
                                'fitness', fitness, ...
                                'runingtime', runingtime );
            draw_curve(convergencecurve, timeline);
            return;
        end;
        %% crossover
        nextpopulation = [];
        a = find(iselected);
        ifitest = a(crossfitfnc(fitness(a), gen, fnc, t));
        ilesser = a(mutatefitfnc(fitness(a), gen, fnc, t));
        ipass = iselected; ipass(ilesser) = 0;
        nextpopulation = [nextpopulation; populations(ipass,:)];
        nfitest = length(ifitest);
        printlog(verbose, '####\t%.0f species selected for crossover.\n\n', nfitest);
        offspring = [];
        if nfitest > 1,
            for i = 1:nfitest,
                
                j = i;
                while (j ==i),
                    j = randi([1,nfitest], [1,1], 'uint8');
                end;

                parents = populations(ifitest([i,j]),:);
                difer = find(parents(1,:) ~= parents(2,:));
                ndifer = length(difer);
                if ndifer < 2, continue; end;
                
                printlog(verbose, [' ***\tparents: [ ' repmat('%2i,',1,ngenes-1) '%2i ], [ ' repmat('%2i,',1,ngenes-1) '%2i ] -> '], parents(1,:),parents(2,:));
                
                a = []; b = [];
                while isempty(a) || isempty(b), % we want at least one flip
                    mask = ~~randi([0,1], [1,ndifer]);
                    a = difer(mask);
                    b = difer(~mask);
                end;
                mask = ~~zeros(size(parents));
                mask(1, :) = 1;
                mask(1, b) = 0;
                mask(2, b) = 1;
                
                % offsprings
                o = [parents(mask), parents(~mask)];
                offspring = [offspring; o'];
                printlog(verbose, ['offspring: [ ' repmat('%2i,',1,ngenes-1) '%2i ], [ ' repmat('%2i,',1,ngenes-1) '%2i ]\n'], o);
            end;            
        end;
        
        %% mutations 
        noffsprings = size(offspring,1);
        if noffsprings > 0,                
            a = ~~zeros(noffsprings,1);            
            a(rand(size(a)) < mutateoffsfnc(fitness(a), gen, fnc, t)) = 1; % mutate offsprings with Pr = muteoffsrate
            printlog(verbose, '\n####\t%.0f offspring selected for mutations.', sum(a));    
            nextpopulation = [nextpopulation;offspring(~a,:)];
            mutate = [ populations(ilesser,:); offspring(a,:) ];
        else
            mutate = populations(ilesser,:);
        end;
        nmutate = size(mutate,1);
        printlog(verbose, '\n####\ttotal %.0f species selected for mutations.\n\n', nmutate);
        for i = 1:nmutate,            
            printlog(verbose, [' ***\tmutating: [ ' repmat('%2i,',1,ngenes-1) '%2i ] -> '], mutate(i,:));
            
            genes = phenotype2genotype(mutate(i,:), genesizes);
            for j = 1:length(genes),
                if isempty(genes{j}), continue; end;
                % mutebitrate probability of flip particular bit             
                genes{j} = xor(genes{j}, randi([1 100], [1,length(genes{j})]) < mutatebitfnc(fitness(a), gen, fnc, t)*100);
            end;
            mutate(i,:) = genotype2phenotype(genes);
            
            printlog(verbose, ['[ ' repmat('%2i,',1,ngenes-1) '%2i ]\n'], mutate(i,:));
        end;
        nextpopulation = [nextpopulation;mutate];
        
        %% finalize
        % in next population, there is one specie that not lived before
        nextpopulation = deduplicate(nextpopulation);
        nextfitness = zeros(size(nextpopulation,1),1);
        nextruningtime = inf(size(nextpopulation,1),1);
        
        populations = [populations; nextpopulation];
        fitness = [fitness; nextfitness];
        runingtime = [runingtime; nextruningtime];
        gen = gen+1;
        
    end;
        
    function printlog(verbose,  varargin)
        if verbose,
            fprintf(varargin{:});
        end;
    end
    
    %% fitness proportionate selection
    function [iselected] = fps(fitness, ifilter, rounds)
        fitness(~ifilter) = -inf;
        [fitness, ifitness] = sort(fitness, 'descend');
        ifitness(fitness==-inf) = [];
        fitness(fitness==-inf) = [];
        fitness = (fitness - min(fitness));
        fitness = fitness / sum(fitness);
        bounds = cumsum(fitness);
        bounds = [[0;bounds(1:end-1)],bounds];
        iselected = [];
        while rounds > 0,
            rounds = rounds-1;
            ptr = rand;
            ptr = ~xor(ptr>=bounds(:,1),ptr<bounds(:,2));
            if max(ptr) == 0, continue; end;
            iselected(end+1) = find(ptr);
        end;
        iselected = ifitness(unique(iselected));
    end
    
    %% stochastic universal sampling
    function [iselected] = sus(fitness, ifilter, nselect)        
        fitness(~ifilter) = -inf;
        [fitness, ifitness] = sort(fitness, 'descend');
        ifitness(fitness==-inf) = [];
        fitness(fitness==-inf) = [];
        fitness = (fitness - min(fitness));
        fitness = fitness / sum(fitness);
        bounds = cumsum(fitness);        
        S = sum(fitness);
        N = length(fitness);
        if nselect > N, nselect = N; end;
        mdistance = S/nselect;
        start = rand*mdistance;
        ptrs = repmat ( start + (0:nselect-1).*mdistance, [N,1] );
        boundsl = repmat( [0;bounds(1:end-1)] , [1, nselect]);
        boundsu = repmat( bounds , [1, nselect]);
        iselected = max(~xor(ptrs>boundsl, ptrs<=boundsu),[],2);
        iselected = ifitness(iselected);
    end

    %% generate initial population
    function [ population ] = initpop(genesizes, popcount, maxtries)        
        if nargin < 3, maxtries = 10; end;
        population = zeros(popcount, length(genesizes));
        from = 0;
        while popcount ~= from && maxtries ~= 0,
            maxtries = maxtries - 1;
            % uniformly disttributed genes
            for c = 1:length(genesizes),
                range = [0 2.^genesizes(c)-1];
                population(from+1:popcount,c) = randi(range,[popcount-from,1],'uint8');
            end;
            population  = deduplicate( population );
            from = size(population,1);
        end;
    end

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
        
    function [ chromosome ] = phenotype2genotype(nums, sizes)
        chromosome = cell(1, length(sizes));
        for c = 1:length(sizes),
            chromosome{c} = num2gene ( nums(c), sizes(c) );
        end;
    end

    function [ nums, sizes ] = genotype2phenotype(chromosome)
        nums = zeros(1, length(chromosome));
        sizes = zeros(1, length(chromosome));
        for c = 1:length(chromosome),
            nums(c) = gene2num(chromosome{c});
            sizes(c) = length(chromosome{c});
        end;
    end

    function [ gene ] = num2gene ( num, gsize )
        gene = dec2bin(num, gsize)=='1';
    end

    function [ num ] = gene2num ( gene )
        s = length(gene);
        num = sum(2.^(s-1:-1:0).*gene);    
    end

    function [ fitness, runningtime ] = getdataset ( dataset, chromosome )
        if isempty(dataset) || isempty(dataset.chromosomes),
            fitness = [];
            runningtime = [];
            return;
        end;
        [ nspecies, ~ ] = size(dataset.chromosomes);
        imatched = find(min(repmat(chromosome, nspecies, 1) == dataset.chromosomes, [], 2));
        nmatched = length(imatched);

        if (nmatched == 0),
            fitness = [];
            runningtime = [];
        else
            fitness = dataset.fitness(imatched,:);
            runningtime = dataset.runningtime(imatched);
        end;
    end

    function [ dataset ] = putdataset ( dataset, chromosome, fitness, runningtime )
        if isempty(dataset),
            dataset = struct;
            dataset.fitness = [];
            dataset.runningtime = [];
            dataset.chromosomes = [];
            dataset.genesizes = [];
            nmatched = 0;
        elseif isempty(dataset.chromosomes),
            nmatched = 0;
        else
            [ nspecies, ~ ] = size(dataset.chromosomes);
            imatched = find(min(repmat(chromosome, nspecies, 1) == dataset.chromosomes, [], 2));
            nmatched = length(imatched);
        end;

        if (nmatched == 0),
            dataset.chromosomes(end+1,:) = chromosome;
            dataset.fitness(end+1,:) = fitness;
            dataset.runningtime(end+1,:) = runningtime;
        end;
    end

    function [ dataset ] = initdataset ( dataset, genesizes )
        if isempty(dataset),
            dataset = struct;
            dataset.fitness = [];
            dataset.runningtime = [];
            dataset.chromosomes = [];
            dataset.genesizes = genesizes;
        else
            dataset.genesizes = genesizes;
        end;
    end

    function draw_curve(fig, timeline)
        gener = unique(timeline.generations);
        f = zeros(size(gener));
        f = struct('mean', f, 'std', f, 'max', f, 'min', f );
        k = 1;
        for ge = gener',
            fi = timeline.fitness(timeline.generations == ge);
            fi(isnan(fi)) = [];
            f.mean(k) = mean(fi);
            f.std(k) = std(fi);
            f.max(k) = max(fi);
            f.min(k) = min(fi);
            k = k+1;
        end;
        figure(fig);
        plot(gener,f.mean,'b');
        hold on;
        plot(gener,f.mean+f.std,'y');
        plot(gener,f.mean-f.std,'y');
        plot(gener,f.max,'g');
        plot(gener,f.min,'r');
        hold off;
        title('Convergence curve');
        h= legend('mean','mean+std','mean-std', 'max','min');
        h1 = findobj(get(h,'Children'),'String','mean'); set(h1,'String','$\mu$','Interpreter','latex');
        h1 = findobj(get(h,'Children'),'String','mean+std'); set(h1,'String','$\mu$ + $\sigma$','Interpreter','latex');
        h1 = findobj(get(h,'Children'),'String','mean-std'); set(h1,'String','$\mu$ - $\sigma$','Interpreter','latex');
        xlabel('epoch');
        ylabel('fitness');
    end
end

