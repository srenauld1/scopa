

epochtmp = 6; 
inc = 5;
te2 = find(daq.a3.epochts==epochtmp);
te2 = te2(1):te2(find(diff(te2)~=1, 1)); %one bout of epoch epochtmp . . . 
te2 = [te2(1)-numel(te2):te2(end)]; % . . . and preceding bout of closed loop
te2 = te2(1) : inc : te2(end);
stackplt3(stack, it=te2, style='MaximumIntensityProjection')