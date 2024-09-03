function cmap = colormap_custom(opt)

arguments
    opt.ncol_each = 128
    opt.colnodes = [0 0 0; 1 1 1]
    opt.satfac = 1
    opt.method = '1d'
end
method = opt.method;
ncol_each = opt.ncol_each;
colnodes = opt.colnodes;
satfac = opt.satfac;

assert(isequal(numel(ncol_each), size(colnodes,1)-1, numel(satfac)))

numnodes = size(colnodes,1);

switch method
    case '1d' %1d interp (linspace) makes straight line from start to end for each color, with ncol steps

        cmap = [];
        for k = 2:numnodes
            if mod(k-1,2)==0
                ncol_adj = ncol_each(k-1)+1; %for overlapping nodes
            else
                ncol_adj = ncol_each(k-1); %for overlapping nodes
            end
            colstart = colnodes(k-1,:);
            colend = colnodes(k,:);
            cmaptmp = repmat(colend, [ncol_adj 1]);
            ncol_sat = round(ncol_adj*satfac(k-1));
            r = linspace(colstart(1),colend(1),ncol_sat);
            g = linspace(colstart(2),colend(2),ncol_sat);
            b = linspace(colstart(3),colend(3),ncol_sat);
            cmaptmp(1:numel(r),:) = [r(:), g(:), b(:)];
            if mod(k-1,2)==0
                cmap = [cmap; cmaptmp]; %for overlapping nodes
            else
                cmap = [cmap; cmaptmp(1:end-1,:)]; %for overlapping nodes
            end
        end

    case '2d' %2d interp makes straight line through 2d colorwheel from one color to next

        if numnodes>2
            error("2d not written for >2 nodes yet")
        end

        ncol_each = ncol_each*2;
        cmap(1,:) = [1 0 0];
        cmap(2,:) = [1 1 1];
        cmap(3,:) = [0 0 1];

        [xx,yy] = meshgrid([1:3],[1:ncol_each]);

        cmap = interp2(xx([1,ceil(ncol_each/2),ncol_each],:),yy([1,ceil(ncol_each/2),ncol_each],:),cmap,xx,yy);

end