function vecout = binary2count(vecin)

% convert binary vector (0s and/or 1s only) to cumulative count; vecin and vecout orientations match

arguments
    vecin {mustBeVector, mustBeBinary}
end


wasrow = 0;
if isrow(vecin)
    wasrow = 1;
    vecin = vecin';
end

vecout = [vecin(1); diff(vecin)];
vecout(vecout<0) = 0;
vecout = cumsum(vecout);
vecout(vecin==0) = 0;

if wasrow
    vecout = vecout';
end