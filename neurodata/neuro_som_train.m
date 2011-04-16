function [ data ] = neuro_som_train( data )
    
    for i = 1:length(data.X),
        %% normalise data
        data.sD{i} = som_data_struct(data.X{i}', ...
            'labels', num2str(reshape(data.y, [], 1)));
        data.sD{i} = som_normalize(data.sD{i},'histD');
    
        %% SOM
        data.sM{i} = som_supervised(data.sD{i},...
            'algorithm', 'batch', ...
            'mapsize', 'normal', ...
            'lattice', 'hexa', ...
            'neigh',  'ep');
        [sBmus, e] = som_bmus(data.sM{i}, data.sD{i});
        fprintf('Mean err: %.3f\n', mean(e));
        data.sErr{i} = sum(~strcmp(data.sM{i}.labels(sBmus), data.sD{i}.labels))/length(sBmus);
    end;
    data.sErr
    