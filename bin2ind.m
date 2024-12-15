function tscnt = bin2ind(tsbin)

% convert binary timeseries to cumulative count 

arguments
    tsbin {mustBeVector}
end

if isrow(tsbin)
    tsbin = tsbin';
end

if tsbin(1) == 0
    first_sample_insert = 0;
else
    first_sample_insert = 1;
end
tscnt = [first_sample_insert; diff(tsbin)];
tscnt(tscnt<0)=0;
tscnt = cumsum(tscnt);
tscnt(tsbin==0)=0;