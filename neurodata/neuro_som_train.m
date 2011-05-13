function [ data ] = neuro_som_train( data, normmethod, algo, lattice, mapsize )
    
    for i = 1:length(data.X),
        %% normalise data
        data.sD{i} = som_data_struct(data.X{i}', ...
            'labels', num2str(reshape(data.y, [], 1)));
        data.sD{i} = som_normalize(data.sD{i},normmethod);
    
        %% SOM
        data.sM{i} = som_supervised(data.sD{i},...
            'algorithm', algo, ...
            'mapsize', mapsize, ...
            'lattice', lattice, ...
            'tracking', 0, ...
            'neigh',  'ep');
        [sBmus, e] = som_bmus(data.sM{i}, data.sD{i});
        data.sErr{i} = sum(~strcmp(data.sM{i}.labels(sBmus), data.sD{i}.labels))/length(sBmus);
    end;
    data.sErr
    