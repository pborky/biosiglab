function [ data ] = neuro_classify( data, dataset, hObj )
%NEURO_CLASSIFY Summary of this function goes here
%   Detailed explanation goes here

    if numel(data{1}.data) < 8000, return; end;
    fprintf (2, 'Processing.\n');
    %[ server, data ] = edfdata(server, 3, [], 0 );    
    data = struct(...
        'X', data{1}.data(end-7999:end,:)', ...
        'fsampl', data{1}.head.SampleRate, ...
        'y', zeros(1,8000) );
        
    [ data ] = neuro_bining(data,  dataset.params{2});
    [ data ] = neuro_fourier ( data, dataset.params{3:5} );
    data = struct('X', data.X{1}', 'fsampl', data.fsampl, 'y', data.y);
    
    sD = som_denormalize(dataset.sD{1});
    orig = size(sD.data);
    sD.data = [sD.data; data.X];
    sD = som_normalize(sD,'histD');
    sD.data = sD.data(orig(1)+1:end,1:orig(2) );
    
    [data.y, e] = som_bmus(dataset.sM{1},sD);
    %clc;
    fprintf('Mean err: %.3f\n', mean(e));
    %dataset.sM{1}.labels{data.y};
    data.y = str2num(char(dataset.sM{1}.labels(data.y)));
    y = data.y(end-4:end);
    z = unique(y);
    h = histc(y, z);
    [~,i] = sort(h,1,'descend');
    for j = i(:)', 
        fprintf('%s\t%.2f\n', dataset.labels{z(j)}, h(j)/sum(h)); 
    end;
    fprintf('%s\n', dataset.labels{z(1)});
    set(hObj, 'String', dataset.labels{z(1)});
end

