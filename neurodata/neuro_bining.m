function [ data ] = pb_bining(data, fred)

    %% binning samples to reduce  sampling frequenc
    % TODO try other methods of extracting features 

    [~, nsamp] = size(data.X);
    redrate = floor(data.fsampl / fred);
    data.fsampl = data.fsampl / redrate;
    data.X = mean(reshape(data.X(:,1:nsamp-mod(nsamp, redrate))',redrate, []));
    data.y = reshape(data.y(1:nsamp-mod(nsamp, redrate))',redrate, []);
    [~,data.y] = max(histc(data.y, unique(data.y)));
    