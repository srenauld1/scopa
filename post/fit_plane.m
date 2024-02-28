function p = fit_plane(b, s, supp,pthspre)

p = 0;
for i = 1:size(s, 2)
    p = p + b(i) * s(:,i);
end
p = p + b(i+1);

% preddepv = b(1) * indv(:,1) + b(2) * indv(:,2) + b(3) * indv(:,3) + b(4) * indv(:,4) + b(5);

end
