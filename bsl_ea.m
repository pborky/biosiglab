function [ winner, wfitness, timeline, dataset ] = bsl_ea( dataset, cfg,init )
%BSL_EA2 Summary of this function goes here
%   Detailed explanation goes here

    
    fnc = struct;
    fnc.fps = @fps;
    fnc.sus = @sus;
    fnc.findbounds = @findbounds;
    fnc.deduplicate = @deduplicate;
    fnc.p2g = @phenotype2genotype;
    fnc.g2p = @genotype2phenotype;
    fnc.num2gene = @num2gene;
    fnc.gene2num = @gene2num;
    
    %% initialize dataset and execution profile  
    if isfield(cfg,'verbose'),
        verbose = cfg.verbose;
    else
        verbose = ~~0;
    end;
    
    popsize = cfg.popsize;
    fitfnc = cfg.fitfnc;
    crossfitfnc = cfg.crossfitfnc;
    mutatefitfnc = cfg.mutatefitfnc;
    stopcond = cfg.stopcond;
    
    if isfield(cfg,'mutateoffsfnc'),
        mutateoffsfnc = cfg.mutateoffsfnc;
    else
        mutateoffsfnc = @(fit, gen, fnc, t) cfg.mutateoffsrate;
    end;
    if isfield(cfg,'mutatebitfnc'),
        mutatebitfnc = cfg.mutatebitfnc;
    else
        mutatebitfnc = @(fit, gen, fnc, t) cfg.mutatebitrate;
    end;
    
    genesizes = dataset.genesizes;
    ngenes = length(genesizes);
    
    %% initial random population, possibily uniformly distributed
    if nargin > 4 || ~isempty(init),
        populations = init;
    else
        populations = initpop(genesizes, popsize);
    end;
    generations = zeros(size(populations,1),1);
    fitness = zeros(size(populations,1),1);
    runingtime = inf(size(populations,1),1);
    gen = 0;
    go = 1;
    
    %%
    while (go),
        %% initialize
        fitness(end+1:size(populations,1)) = 0;
        runingtime(end+1:size(populations,1)) = inf;
        generations(end+1:size(populations,1)) = gen;
        ipopulation = generations==gen;
        popcount = sum(ipopulation);
        printlog(verbose,'\n####\tgen: %.0f count: %.0f\n\n', gen, popcount);
        %% calculate fitness for actual gen
        for i = find(ipopulation)',
            printlog(verbose,[' ***\tspecie: [ ' repmat('%2i,',1,ngenes-1) '%2i ]\t'], populations(i,:));
            [ fit, rt ] = getdataset ( dataset, populations(i,:) );
            if ~(isempty(fit) || isempty(rt)),
                runingtime(i) = rt;
                fitness(i) = fitfnc(fit,rt);
                printlog(verbose,['eval: [ ',repmat('%5.2f,',1,length(fit)),'%6.2f ] fitness: %5.2f\n'], fit, runingtime(i), fitness(i));
            else
                printlog(verbose,2, 'Oops! No result found!\n'); 
                runingtime(i) = NaN;
                fitness(i) = NaN;
                continue; 
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
            winner = populations(iselected,:);
            wfitness = fitness(iselected);
            timeline = struct(  'populations', populations, ...
                                'generations', generations, ...
                                'fitness', fitness, ...
                                'runingtime', runingtime );
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
        % TODO: assign known data from previous loop
        
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
    
    %% localize bounds for stochastic universal sampling
    function [ ibounds ] = findbounds(ptrs, bounds)
        
        [nbounds,~] = size(bounds);
        [~,nptrs] = size(ptrs);
        lower = repmat(bounds(:,1), [1, nptrs]);
        upper = repmat(bounds(:,2), [1, nptrs]);
        p = repmat(ptrs, [nbounds, 1]);
        ibounds = find(max((p>lower) & (p<=upper),[],2));
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
        if isempty(dataset),
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


end