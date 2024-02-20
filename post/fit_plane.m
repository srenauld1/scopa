function p = fit_plane(b, s, supp,pthspre)

p = 0;
for i = 1:size(s, 2)
    p = p + b(i) * s(:,i);
end
p = p + b(i+1);

% predresp = b(1) * stim(:,1) + b(2) * stim(:,2) + b(3) * stim(:,3) + b(4) * stim(:,4) + b(5);

end
