function [ data ] = pb_fourier ( data, wnd, nstep, edges )
    
    %% initialize
    step   = floor(wnd/nstep);
    wnd     = step*nstep;    
    [dim, nsamp] = size(data.X);
    nwnd = floor((nsamp - (nstep-1)*step) / wnd);
    nseff = nwnd * wnd;
    
    %% prepare data (reshape to matrix where each vector is one window on time axis)
    XX = zeros(nstep*wnd, nwnd, dim); 
    yy = zeros(nstep*wnd, nwnd);
    
    X = data.X'; % make column vector
    y = data.y';
    for i = 0:nstep-1,
        XX(i*wnd+1:(i+1)*wnd,:,:) = reshape(X(1+(i*step):nseff+(i*step),:), wnd, [], dim );
        yy(i*wnd+1:(i+1)*wnd,:) = reshape(y(1+(i*step):nseff+(i*step),:), wnd, [] );
    end;
    XX = reshape(XX, wnd, [], dim);
    %data.y = reshape(yy, wnd, []);
    data.X = XX - repmat(mean(XX),size(XX,1),1); % subtract mean value from each vector
    %XX = XX - mean(X(:));
    
    data.y = data.y((1:(nstep*nwnd))*step);
    %[~,data.y] = max(histc(data.y, unique(data.y)));
    
    %% trnasform and filter data
    data.X = abs(fft(data.X));
    [wnd, ~] = size(data.X); 
    data.freqs = (1:wnd) * data.fsampl / wnd;
    
    [~,nbounds] = size(edges);

    X = cell(1, nbounds);
    for i = 1:nbounds,
        X{i} = data.X(data.freqs>edges(1,i) & data.freqs<=edges(2,i),:);
    end;
    data.X = X;