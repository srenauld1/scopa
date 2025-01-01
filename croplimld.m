function [croplim, croplimstr] = croplimld(pthcroplim)

arguments
    pthcroplim
end

pthcroplim = rdir(pthcroplim);

if isempty(pthcroplim)
    fprintf("NO CROPLIM FILE: " + newline + pthcroplim + newline + ", YOU WILL BE PROMPTED TO DEFINE CROPLIM" + newline)
    croplim = [];
    croplimstr = '';
elseif numel(pthcroplim)>1
    error(sprintf("ERROR, MULTIPLE CROPLIM FILES"))
elseif numel(pthcroplim)==1
    fprintf("FOUND ONE CROPLIM FILE FOR REGIONEX: " + newline + pthcroplim + newline)
    [~, fncr, ~] = fileparts(pthcroplim.name);
    spl = strsplit(fncr, '_');
    insloc = find(strcmp(spl, regionex));
    croplimstr = strjoin(spl(insloc+1:insloc+10), '_');
    croplimtmp = str2double(strsplit(croplimstr, '_'));
    croplim = croplimtmp(vec([1:2]'+2*([3 2 4 1 5]-1)));
    if all(isnan(croplim(end-1:end))) %in case it's an old croplim file (no channel)
        numchan = 1;
        croplimstr = strjoin(spl(insloc+1:insloc+8), '_');
        croplimtmp = str2double(strsplit(croplimstr, '_'));
        croplim = croplimtmp(vec([1:2]'+2*([3 2 4 1]-1)));
        croplimstr = [croplimstr '_1_' num2str(numchan)];
        croplim = [croplim 1 numchan];
    end
end

end