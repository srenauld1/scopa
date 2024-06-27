function varargout = insert_nan_for_polar_wrap(varargin)

%replace diffs greater than pi with nan in the wrapped plot because the lines make it difficult to read

diff_rep_thresh = pi;
diffspace1 = 1;
filt1 = [zeros(1,diffspace1-1) 1 zeros(1,diffspace1-1) -1]; %find diffs across larger num samples since sometimes it takes more than 2 samples to go from max to min (-pi to pi)
% diffspace2 = 2;
% filt2 = [zeros(1,diffspace2-1) 1 zeros(1,diffspace2-1) -1]; %find diffs across larger num samples since sometimes it takes more than 2 samples to go from max to min (-pi to pi)

for j = 1:numel(varargin)

    varargout{j} = varargin{j};

    diffsignal = conv(varargin{j}, filt1, 'full');
    diffsignal = diffsignal((length(filt1) - 1)+1:end-(length(filt1) - (1 + (diffspace1-1))));
    diffsignal1 = [zeros((diffspace1-1)+1, 1) diffsignal];

    % diffsignal = conv(varargin{j}, filt2, 'full');
    % diffsignal = diffsignal((length(filt2) - 1)+1:end-(length(filt2) - (1 + (diffspace2-1))));
    % diffsignal2 = [zeros((diffspace2-1)+1, 1) diffsignal];

    excludeinds = abs(diffsignal1)>diff_rep_thresh; %| abs(diffsignal2)>diff_rep_thresh;
    varargout{j}(excludeinds) = nan;

end

end