function xv = cell2vec(x)

xv = cell(length(x),1);
for ii = 1:length(x)
  xv{ii} = x{ii}(:);
end
xv = vertcat( xv{:} );