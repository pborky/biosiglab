function [ data ] = neuro_som_val( data, nfolds, normmethod, algo, lattice, mapsize  )
    
    % prepare data
    X = data.X{1}; y = data.y;
    [ ~, nsamp ] = size(X);
    [itrn,itst] = crossval(nsamp, nfolds);
    sErr = zeros(1, nfolds);
    
    %% normalise data
    sD = som_data_struct(X', 'labels', num2str(reshape(y, [], 1)));
    sD = som_normalize(sD, normmethod);
    
    for f = 1:nfolds,
        sDtrn = sD; 
        sDtrn.data = sDtrn.data(itrn{f},:);
        sDtrn.labels = sDtrn.labels(itrn{f});
        
        sDtst = sD;
        sDtst.data = sDtst.data(itst{f},:);
        sDtst.labels = sDtst.labels(itst{f});
    
        %% SOM
        sM = som_supervised(sD,...
            'algorithm', algo, ...
            'mapsize', mapsize, ...
            'lattice', lattice, ... 
            'tracking', 0, ...
            'neigh',  'ep');
        [sBmus, e] = som_bmus(sM, sDtrn);
        sErr(f) = sum(~strcmp(sM.labels(sBmus), sDtrn.labels))/length(sBmus);
        
    end;
    %fprintf('Mean validation err: %.3f\n', mean(sErr));
    d = struct();
    d.params = data.params;
    d.iparams = data.iparams;
    d.labels = data.labels;
    d.fsampl = data.fsampl;
    
    sM = som_supervised(sD,...
        'algorithm', algo, ...
        'mapsize', mapsize, ...
        'lattice', lattice, ... 
        'tracking', 0, ...
        'neigh',  'ep');
    [mqe,tge] = som_quality(sM, sD);
    d.eval = [mean(sErr) mqe tge];
    data = d;
    
    