

%% 

            [ ecnt, erad, evecs, ~, ~, ~, erts] = ellipsoid_fit_new( [maskxup, maskyup, maskzup] );

            [X,Y,Z] = ellipsoid2(erad(1), erad(2), erad(3), ecnt(1), ecnt(2), ecnt(3), erts(1), erts(3), erts(2), nface=round(sqrt(numel(premaskup))), plt=0);

            eft = zeros(size(premaskup));
            [YY,XX,ZZ] = ind2sub(size(premaskup), 1:numel(premaskup)); %find the cartesian coordinates of points in the mask
            fk = [YY', XX', ZZ'];
            qp = [Y(:), X(:), Z(:)]; %[maskyup(:), maskxup(:), maskzup(:)];
            idx = knnsearch(fk, qp);
            eft(idx) = 1;
            stackplt3(cat(5, premaskup, eft));
            eft = logical(imfill(single(eft))); %imfill works for 3d if it's not logical (seems like a bug); if you don't like converting, just imfill each z slice in loop
            stackplt(eft)



            %%

            % Compute major circumferential lines.
            xyzR = erad([2 3 1]);
            th = linspace(0,2*pi,150)'; % column vec
            ex = @(r,c)c+r*cos(th); % r=radius (scalar), c=center (Scalar)
            ey = @(r,c)c+r*sin(th); % r=radius (scalar), c=center (Scalar)
            ez = @(c)repmat(c,size(th)); % c=center (scalar)
            xy = [ex(xyzR(1),ecnt(1)), ey(xyzR(2),ecnt(2)), ez(ecnt(3))        ];
            xz = [ex(xyzR(1),ecnt(1)), ez(ecnt(2)),         ey(xyzR(3),ecnt(3))];
            yz = [ez(ecnt(1)),         ey(xyzR(2),ecnt(2)), ex(xyzR(3),ecnt(3))];


            hfg = figure;
            hax = axes(parent=hfg);
            hold on;
            xlabel('x'); ylabel('y'); zlabel('z')
            plot3(hax, ecnt(1), ecnt(2), ecnt(3), 'ko','MarkerSize',8,'MarkerFaceColor','k')  % center point
            lw = 2; % line widths
            hpl1 = plot3(hax, xy(:,1), xy(:,2), xy(:,3), 'k-','LineWidth',lw);
            hpl2 = plot3(hax, xz(:,1), xz(:,2), xz(:,3), 'k-','LineWidth',lw);
            hpl3 = plot3(hax, yz(:,1), yz(:,2), yz(:,3), 'k-','LineWidth',lw);
            hax.XLim = [1, size(premaskup,2)];
            hax.YLim = [1, size(premaskup,1)];
            hax.ZLim = [1, size(premaskup,3)];
            view(hax, 3)