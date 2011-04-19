function [ data ] = neuro_draw( data, figures )

    %% draw normalised data
    for i = 1:length(data.sM),
        if isempty(figures),
            figures = [...
                figure('Name', 'Umatrix and BMUs labeling'),  ...
                figure('Name', 'PCA projection of topological structure and features')];
        end;
        
        % prepare
        c = [1 0 0 ; 0 1 0; 0 0 1; 1 1 0; 1 0 1; 0 1 1; .5 .5 .5; 1 1 1; ];
        colors2 = c(data.y,:); 
        a = data.sM{i}.labels;
        a(strcmp('', a))={'0'};
        a = str2num(char(a));
        colors =  c(a, :); 
        a(a==0) = 1;

        % SOM
        figure(figures(1));
        h = som_show(data.sM{i},'umat','all', 'color', { colors, 'Labels'}, 'norm', 'n' ); 

        % Topological structure of som neurons and features in reduced space
        figure(figures(2));
        [Pd, V, me] = pcaproj(data.sD{i}, 3);
        hold off; grid off;
        som_grid(data.sM{i}, 'Coord', pcaproj(data.sM{i}, V, me), 'Marker', 'o', 'MarkerSize', 10, 'MarkerColor', colors, 'LineColor', 'k');
        hold on; grid on;
        som_grid('hexa', [1 length(data.y)] ,'Coord', Pd, 'Marker', 'x', 'MarkerSize', 6, 'MarkerColor', colors2, 'Line', 'none');

        % samomns projection
%         figure('Name', 'Sammon projection of topologicdaal structure.');
%         som_grid(data.sM{i},  'Coord', sammon(data.sM{i}, 2), 'Marker', 'o', 'MarkerSize', 10, 'MarkerColor', colors, 'LineColor', 'k');
    end;
