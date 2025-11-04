function optout = odist(optin)

%{

for each substruct within struct optin . . . 
for any cell-valued field (option) . . . 
create new struct for each cell element ('distribute')
    copy non-cell fields (options) to all new structs
    give temporary names to the new structs and delete the original struct
    if there are multiple cell-valued fields (options), create all combinations of their elements with the new structs
odist.m is similar to odist.py; the main difference is:
    odist.m has 'any'/'each' functionality: distribute options ('any') within each mosc ('each') 
    odist.py just has 'any' functionality (not 'each')

%}

arguments
    optin (1,1) struct %scalar struct to be "distributed"
end

delimflat = glbfile('delimflat');

%%%% DISTRIBUTE NON-SINGLETON CELLS INTO NEW MOSC (SUBSTRUCTS) %%%%


fn = fieldnames(optin);
for k = 1:numel(fn)
    
    tmp = []; %clear because we are not accumulating in tmp (we do that in optout)

    mosc_tmp = fn{k};
    mos_struct = optin.(mosc_tmp);
    mos_struct_flat = structflat(mos_struct, delim=delimflat); % prefix=mosc_tmp);
    fnflat = fieldnames(mos_struct_flat);

    mos_struct_flat_cell = struct2cell(mos_struct_flat);
    
    idx_dist = cellfun(@iscell, mos_struct_flat_cell) & cellfun(@(x) numel(x)>1, mos_struct_flat_cell); %find fields with nonscalar cells
    idx_dist = idx_dist; 
    if any(idx_dist) %if there are any fields to be distributed
        fndist = fnflat(idx_dist);
        mos_struct_flat_cell = mos_struct_flat_cell(idx_dist);
        for m = 1:numel(mos_struct_flat_cell)
            if ~isvector(mos_struct_flat_cell{m})
                error("mos_struct_flat_cell{m} must be vector")
            end
            dmvec = find(size(mos_struct_flat_cell{m})==max(size(mos_struct_flat_cell{m}))); %find non-singleton vector dimension (column vec = 1, row vec = 2), required for function uniquearray
            utmp = uniquearray(mos_struct_flat_cell{m}, dmvec); %this fex function works on cells with elements of any class
            if ~isequal(numel(utmp), numel(mos_struct_flat_cell{m}))
                error("all elements of cell-valued options must be unique")
            end
        end
        combos = combinations(mos_struct_flat_cell{:}); %make all combinations of the nonscalar cells
        for m = 1:size(combos,1) %and put each in a new substruct
            mosc_new = [mosc_tmp '_' num2str(m)];
            for mm = 1:numel(fndist)
                tmp.(mosc_new).(fndist{mm}) = combos{m,mm}{1};
            end
        end

    else %if there are not any fields to be distributed

        mosc_new = [mosc_tmp '_' num2str(1)];
        tmp.(mosc_new) = struct;

    end


    %%%% ADD ALL FIELDS THAT ARE NOT CELLS, OR SINGLETON CELLS (AND REMOVE SINGLETONS FROM CELL) %%%%

    for m = 1:numel(fnflat)
        if ~idx_dist(m)
            mosc_new = fieldnames(tmp);
            for q = 1:numel(mosc_new)
                if iscell(mos_struct_flat.(fnflat{m})) %cell-valued fields must be scalar cells by this point, and get taken out of their cells
                    if isscalar(mos_struct_flat.(fnflat{m}))
                        tmp.(mosc_new{q}).(fnflat{m}) = mos_struct_flat.(fnflat{m}){1}; %since singleton, take it out of cell
                    else
                        error("after distribution all cells must be scalar")
                    end
                else %if not cell, just copy over into output (do not modify)
                    tmp.(mosc_new{q}).(fnflat{m}) = mos_struct_flat.(fnflat{m});
                end
            end
        end
    end

    if k==1
        optout = tmp;
    else
        optout = cell2struct([struct2cell(optout); struct2cell(tmp)], [fieldnames(optout); fieldnames(tmp)]); %combine
    end

end

fn = fieldnames(optout);
for k = 1:numel(fn)
    optout.(fn{k}) = structunflat(optout.(fn{k}), delim=delimflat);
end

optout = structsort(optout, vectype='row');


end

