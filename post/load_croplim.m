function [croplim, croplimstr] = load_croplim(fldr, recid, regionex_nounderscore )

pthcroplimall = rdir([fldr recid '_' regionex_nounderscore '_*_croplim_.*']); %croplim file can be mat of npy, just need to read filename for croplim info 

if isempty(pthcroplimall)
    sprintf("NO CROPLIM FILE FOR REGIONEX: " + regionex_nounderscore + ", YOU WILL BE PROMPTED TO DEFINE CROPLIM ")
    croplim = [];
    croplimstr = 'nocroplimhold';
elseif length(pthcroplimall)>1
    error(sprintf("ERROR, MULTIPLE CROPLIM FILES FOR REGIONEX: " + regionex_nounderscore + ", CHOOSE THE ONE THAT MATCHES SIZE OF *roi2d_.mat"))
elseif length(pthcroplimall)==1
    sprintf("FOUND ONE CROPLIM FILE FOR REGIONEX: " + regionex_nounderscore)
    [~, fncr, ~] = fileparts(pthcroplimall.name);
    spl = strsplit(fncr, '_');
    insloc = find(strcmp(spl, regionex_nounderscore));
    croplimstr = strjoin(spl(insloc+1:insloc+10), '_');
    croplimtmp = str2double(strsplit(croplimstr, '_'));
    croplim = croplimtmp(vec([1:2]'+2*([3 2 4 1 5]-1)));
end

end