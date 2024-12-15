function ftsyn = mfit_synpars(x0, lb, ub, syntype)

arguments
    x0
    lb
    ub
    syntype = 'random'
end

dummybnd = 10;

switch syntype
    case 'random'
        fprintf("synthesizing params with random method, within bounds, or if Inf, within dummy bounds +/-" + num2str(dummybnd) + newline)
        ub(isinf(ub)&ub>0) = dummybnd; %replace inf with a (relatively) big number
        ub(isinf(ub)&ub<0) = -dummybnd; %replace -inf with a (relatively) small number
        lb(isinf(lb)&lb>0) = dummybnd; %replace inf with a (relatively) big number
        lb(isinf(lb)&lb<0) = -dummybnd; %replace -inf with a (relatively) small number
        ftsyn = lb + (ub-lb).*rand(size(x0)); %synthetic params (random, within bounds), to generate synthetic depv in case testing optimization code
end


end