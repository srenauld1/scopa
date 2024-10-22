function osave(o)
% deprecated because jsonencode does it better, although maybe less readable  

% save all options (struct o, flattened) as txt file (with timestring id)
% this way filenames don't have to contain options, instead they can just share a timestring id with the options txt filename, for lookup when making figures, etc)
% some complex structure is lost in the txt file (e.g. if there are nested cells, they get flattened, although there are no nested cells in default o right now), since i'm not sure it's necessary yet

[tmp, ~, ~] = fileparts(o.id.pth);
filesv = [o.id.recid '_' glb('timestr') '_options_.txt'];
pthsv = fullfile(tmp, filesv);
if numel(o)>1
    error("o must be scalar struct at this point (although it can contain nonscalar substructs)")
end

of = structflat(o);

fid = fopen(pthsv, 'w');
var2txt(of, fid)
fclose(fid);

end

function var2txt(var, fid, nmtmp)

arguments
    var
    fid
    nmtmp = []
end

if ~isstruct(var)
    allvars = whos;
    tmp = cell2struct({allvars.name}.',{allvars.name});
    tmp = rmfield(tmp, {'fid', 'nmtmp'});
    eval(structvars(tmp,0).');
    tmp.(nmtmp) = tmp.var;
    tmp = rmfield(tmp,'var');
    var = tmp;
    tmp = [];
end

fn = fieldnames(var);
for k = 1:numel(fn)
    vtmp = var.(fn{k});
    nmtmp = fn{k};

    fprintf(fid, '%s: ', nmtmp);
    if isstruct(vtmp)
        error("there should not any be structs after calling structflat above; if there are you may have put structs in a cell array, which is currently not supported in a2p")
        var2txt(vtmp, fid)
    else
        if ischar(vtmp) %char check before indexing in case not cell
            vtmp = string(vtmp);
        end
        if iscell(vtmp) && iscell([vtmp{:}]) %if there are any cells within the cell (any nesting)
            vtmp = cellflat(vtmp);  %for now just flatten it and deal with careful formatting later; not sure we even need this level of detail now
        end
        for m = 1:numel(vtmp)
            if isvector(vtmp)
                if iscell(vtmp)
                    vtmp2 = vtmp{m};
                    if ischar(vtmp2) %char check after indexing if cell
                        vtmp2 = string(vtmp2);
                    end
                else
                    vtmp2 = vtmp(m);
                end
            else
                error("should be flatened to vector at this point")
            end
            if m==numel(vtmp)
                delim = '';
            else
                delim = ', ';
            end
            spec = [var2spec(vtmp2) delim];
            fprintf(fid, spec, vtmp2);
        end

        fprintf(fid, '\n');
    end

end

end

function spec = var2spec(var)

if isnumeric(var)
    if mod(var, 1)==0 %if int
        spec = '%d'; %signed int
    else
        spec = '%f'; %float
    end
else
    spec = '%s'; %char or string
end

end

