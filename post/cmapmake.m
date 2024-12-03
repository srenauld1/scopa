function cmap = cmapmake(opt)

arguments
    opt.ncol = 128
    opt.nodes = [0 0 0; 1 1 1]
    opt.satfac = 1
    opt.method = '1d'
end
method = opt.method;
ncol = opt.ncol;
nodes = opt.nodes;
satfac = opt.satfac;

if iscell(nodes)
    if iscellstr(nodes)
        numnodes = numel(nodes);
        if numnodes<2
            error("numnodes must be greater than 1")
        end
        for k = 1:numnodes
            switch nodes{k}
                case {'k', 'black'}
                    nodes{k} = [0 0 0];
                case {'r', 'red'}
                    nodes{k} = [1 0 0];
                case {'g', 'green'}
                    nodes{k} = [0 1 0];
                case {'b', 'blue'}
                    nodes{k} = [0 0 1];
                case {'c', 'cyan'}
                    nodes{k} = [0 1 1];
                case {'m', 'magenta'}
                    nodes{k} = [1 0 1];
                case {'y', 'yellow'}
                    nodes{k} = [1 1 0];
                case {'w', 'white'}
                    nodes{k} = [1 1 1];
            end
        end
        nodes = cell2mat(nodes');
    else
        error("if nodes is cell or string, must be string or char denoting colors or color shortcuts (krgbcmyw)")
    end
    if size(nodes,1)~=numnodes
        error("if nodes is cell, must be length number nodes")
    end
end

numnodes = size(nodes,1);

if numel(ncol)==1
    ncol = repelem(ncol, numnodes-1);
end
if numel(satfac)==1
    satfac = repelem(satfac, numnodes-1);
end

if ~isequal(numel(ncol), size(nodes,1)-1, numel(satfac))
    error("these quantities are not all equal, but should be: numel(ncol), size(nodes,1)-1, numel(satfac)")
end


switch method
    case '1d' %1d interp (linspace) makes straight line from start to end for each color, with ncol steps

        cmap = [];
        for k = 2:numnodes
            if mod(k-1,2)==0
                ncol_adj = ncol(k-1)+1; %for overlapping nodes
            else
                ncol_adj = ncol(k-1); %for overlapping nodes
            end
            colstart = nodes(k-1,:);
            colend = nodes(k,:);
            cmaptmp = repmat(colend, [ncol_adj 1]);
            ncol_sat = round(ncol_adj*satfac(k-1));
            r = linspace(colstart(1),colend(1),ncol_sat);
            g = linspace(colstart(2),colend(2),ncol_sat);
            b = linspace(colstart(3),colend(3),ncol_sat);
            cmaptmp(1:numel(r),:) = [r(:), g(:), b(:)];
            if mod(k-1,2)==0
                cmap = [cmap; cmaptmp]; %for overlapping nodes
            else
                if numnodes==2
                    cmap = cmaptmp; %for overlapping nodes
                else
                    cmap = [cmap; cmaptmp(1:end-1,:)]; %for overlapping nodes
                end
            end
        end

    case '2d' %2d interp makes straight line through 2d colorwheel from one color to next

        if numnodes>3
            fprintf("you requested method 2d for more than 3 nodes in cmapmake; does it work (not tested)??")
        end

        for k = 1:numnodes
            cmap(k,:) = nodes(k,:);
        end

        ncol_adj = ncol*2;

        [xx,yy] = meshgrid([1:size(cmap,1)],[1:ncol_adj]);

        cmap = interp2(xx([1,ceil(ncol_adj/2),ncol_adj],:),yy([1,ceil(ncol_adj/2),ncol_adj],:),cmap,xx,yy);

end