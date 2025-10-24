function vecout = binary2count(vecin)

% convert binary vector to cumulative count; vecin orientation matches vecout

arguments
    vecin {mustBeVector}
end

wasrow = 0;
if isrow(vecin)
    wasrow = 1;
    vecin = vecin';
end

if vecin(1) == 0
    first_sample_insert = 0;
else
    first_sample_insert = 1;
end
vecout = [first_sample_insert; diff(vecin)];
vecout(vecout<0) = 0;
vecout = cumsum(vecout);
vecout(vecin==0) = 0;

if wasrow
    vecout = vecout';
end