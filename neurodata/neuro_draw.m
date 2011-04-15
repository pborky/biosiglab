function [ data ] = pb_draw( data )

    %% draw normalised data
    for i = 1:length(data.sM),
        % prepare
        colors2 = double([data.y == 1;data.y==2;data.y==3]');
        a = data.sM{i}.labels;
        a(strcmp('', a))={'0'};
        a = str2num(char(a));
        colors = double([a == 1,a==2,a==3]);
        a(a==0) = 1;

        % SOM
        figure;
        h = som_show(data.sM{i},'umat','all', 'color', { colors, 'Labels'}, 'norm', 'n' ); 

        % Topological structure of som neurons and features in reduced space
        figure('Name', 'PCA projection of topological structure and features.');
        [Pd, V, me] = pcaproj(data.sD{i}, 3);
        som_grid(data.sM{i}, 'Coord', pcaproj(data.sM{i}, V, me), 'Marker', 'o', 'MarkerSize', 10, 'MarkerColor', colors, 'LineColor', 'k');
        hold on; grid on;
        som_grid('hexa', [1 length(data.y)] ,'Coord', Pd, 'Marker', 'x', 'MarkerSize', 6, 'MarkerColor', colors2, 'Line', 'none');

        % samomns projection
        figure('Name', 'Sammon projection of topologicdaal structure.');
        som_grid(data.sM{i},  'Coord', sammon(data.sM{i}, 3), 'Marker', 'o', 'MarkerSize', 10, 'MarkerColor', colors, 'LineColor', 'k');
    end;
