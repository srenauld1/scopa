function o = transform_user_input_a2p(o)

% some params are set in user-input-friendly format and need to be transformed into format that simplifies the downstream code

if ~iscell(o.mn.pthstacks)
    o.mn.pthstacks = {o.mn.pthstacks};
end

for k = 1:numel(o.mn.regionexs)

    regionex = o.mn.regionexs{k};

    if ~isfield(o.mroi.auto.numroi, regionex)
        numroiautotmp.(regionex) = 0;
    else
        numroiautotmp.(regionex) =  o.mroi.auto.numroi.(regionex);
    end
    if any(strcmp(o.mroi.dodraw, regionex))
        dodraw_tmp.(regionex) = 1;
    else
        dodraw_tmp.(regionex) = 0;
    end
    if any(strcmp(o.mroi.auto.usehires, regionex))
        usehires_tmp.(regionex) = 1;
    else
        usehires_tmp.(regionex) = 0;
    end
    if ~isfield(o.pf.bump.numcluster_for_bump_domain_resample, regionex)
        numcluster_for_bump_domain_resample_tmp.(regionex) = 0;
    else
        numcluster_for_bump_domain_resample_tmp.(regionex) = o.pf.bump.numcluster_for_bump_domain_resample.(regionex);    
    end

end

o.mroi.auto.numroi = numroiautotmp;
o.mroi.dodraw = dodraw_tmp;
o.mroi.auto.usehires = usehires_tmp;
o.pf.bump.numcluster_for_bump_domain_resample = numcluster_for_bump_domain_resample_tmp;

end