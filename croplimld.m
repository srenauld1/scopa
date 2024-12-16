function [croplim, croplimstr] = croplimld(dirstack, recid, regionex_nounderscore, numchan)

arguments
    dirstack
    recid
    regionex_nounderscore
    numchan = 1
end

pthall = rdir([dirstack recid '_' regionex_nounderscore '_*_croplim_.*']); %croplim file can be mat of npy, just need to read filename for croplim info

if isempty(pthall)
    fprintf("NO CROPLIM FILE FOR REGIONEX: " + regionex_nounderscore + ", YOU WILL BE PROMPTED TO DEFINE CROPLIM" + newline)
    croplim = [];
    croplimstr = 'nocroplimhold';
elseif length(pthall)>1
    error(sprintf("ERROR, MULTIPLE CROPLIM FILES FOR REGIONEX: " + regionex_nounderscore + ", CHOOSE THE ONE THAT MATCHES SIZE OF *roi2d_.mat"))
elseif length(pthall)==1
    fprintf("FOUND ONE CROPLIM FILE FOR REGIONEX: " + regionex_nounderscore + newline)
    [~, fncr, ~] = fileparts(pthall.name);
    spl = strsplit(fncr, '_');
    insloc = find(strcmp(spl, regionex_nounderscore));
    croplimstr = strjoin(spl(insloc+1:insloc+10), '_');
    croplimtmp = str2double(strsplit(croplimstr, '_'));
    croplim = croplimtmp(vec([1:2]'+2*([3 2 4 1 5]-1)));
    if all(isnan(croplim(end-1:end))) %in case it's an old croplim file (no channel)
        croplimstr = strjoin(spl(insloc+1:insloc+8), '_');
        croplimtmp = str2double(strsplit(croplimstr, '_'));
        croplim = croplimtmp(vec([1:2]'+2*([3 2 4 1]-1)));
        croplimstr = [croplimstr '_1_' num2str(numchan)];
        croplim = [croplim 1 numchan];
    end
end

end