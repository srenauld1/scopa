figsidelength = 1;
pos_intended = [0 0 1 1];
tmptmp = [0 0];
while ~isequal(pos_intended(3:4), tmptmp)
    if aspect_screen>1
        pos_intended = [0 0 figsidelength/aspect_screen figsidelength]; %make square inner size (excludes top menu bar), plot in bottom left
    else
        pos_intended = [0 0 figsidelength figsidelength/aspect_screen]; %make square inner size (excludes top menu bar), plot in bottom left
    end
    hfg.Position = pos_intended; %make square inner size (excludes top menu bar), plot in bottom left
    pause(0.2)
    tmptmp=hfg.Position(3:4);
    figsidelength = figsidelength-0.05;
end