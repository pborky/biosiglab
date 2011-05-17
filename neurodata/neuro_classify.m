function [ data ] = neuro_classify( data, dataset, hObj )
%NEURO_CLASSIFY Summary of this function goes here
%   Detailed explanation goes here

    if ~isfield(data,'X'),
        if numel(data{1}.data) < 8000, return; end;
        fprintf (2, 'Processing.\n');
        %[ server, data ] = edfdata(server, 3, [], 0 );
        data = struct(...
            'X', data{1}.data(end-7999:end,:)', ...
            'fsampl', data{1}.head.SampleRate, ...
            'y', zeros(1,8000) );
    else
        data.fsampl = data.edf{1}.head.SampleRate;
        data.X = data.X';
        data.y = data.y';
    end;
        
    [ data ] = neuro_bining(data,  dataset.params{2});
    [ data ] = neuro_fourier ( data, dataset.params{3:5} );
    data = struct('X', data.X{1}', 'fsampl', data.fsampl, 'y', data.y);
    
    %TODO following is very costy. problem is that histD normalization is
    %not linear and depends on distribution of data. Thus it provides
    %different results as in training set. 
%     sD = som_denormalize(dataset.sD{1});
%     orig = size(sD.data);
%     sD.data = [sD.data; data.X];
%     sD = som_normalize(sD,'histD');
%     sD.data = sD.data(orig(1)+1:end,1:orig(2) );
    sD = som_data_struct(data.X);
    sD = som_normalize(sD, dataset.sD{1}.comp_norm);
    
    [data.yc, e] = som_bmus(dataset.sM{1},sD);
    %clc;
    fprintf('Mean quantization error: %.3f\n', mean(e));
    %dataset.sM{1}.labels{data.y};
    data.yc = str2num(char(dataset.sM{1}.labels(data.yc)));
    if ~isempty(hObj),
        if length(data.y) <= 20, 
            y = data.y;
        else
            y = data.y(end-20:end);
        end;
        z = unique(y);
        h = histc(y, z);
        [~,i] = sort(h,1,'descend');
        fprintf('Classifier weights:\n');
        for j = i(:)', 
            fprintf('\t%s\t%.2f\n', dataset.labels{z(j)}, h(j)/sum(h)); 
        end;
        fprintf('Best matching: %s\n', dataset.labels{z(i(1))});
        set(hObj, 'Value', z(i(1)));
    else
        data.err = sum(data.yc(:) ~= data.y(:)) / length(data.y);
    end;
end

