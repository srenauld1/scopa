function rank = percentrank(array, probes)

rank = reshape( mean( bsxfun(@le, array(:), probes(:).') ) * 100, size(probes) );

end
