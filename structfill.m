function sout = structfill(s, sdf)

%{

replace values in struct sdf with values in struct s 
structs can be nested and nonscalar
s field arrangement must be subset (or equal to) sdf field arrangement
  if field is in both s and sdf, assign to sout the value in s; 
  if field is only in sdf, assign to sout the value in sdf; 
  if field in s doesn't exist in sdf, error

%}

arguments
    s struct % struct to be filled with any fields that appear in sdf but not in s
    sdf struct % struct holding all valid fields ('sdf' denotes 'struct defaults')
end

num_sin = numel(s);
num_sdf = numel(sdf);
fn_sin = fieldnames(s);

sout = sdf; %start here by making sout match sdf, then, below, overwrite with anything in s

if num_sin>1 %for nonscalar struct, operate on each index, and also find fields that are struct in one index but empty in another (ie not specified); make make them struct also so they appear in output tmp, then assign tmp to sout
    if ~isequal(num_sin, num_sdf)
        error("sdf must match size of s")
    end
    yesstruct = cellfun(@isstruct, struct2cell(vec(s)));
    notstable = ~all(isequal(yesstruct, yesstruct(:,1)), 2);
    for idx_sin = 1:num_sin
        for k = 1:numel(fn_sin)
            fin2 = fn_sin{k};
            if isequal(yesstruct(k,idx_sin), 0) && isequal(notstable(k), 1)
                s(idx_sin).(fin2) = struct;
            end
        end
    end
    for idx_sin = num_sin:-1:1 %increment backward to preallocate
        tmp(idx_sin) = structfill(s(idx_sin), sout(idx_sin));
    end
    sout = reshape(tmp, size(s));
else
    for k = 1:numel(fn_sin)
        fin2 = fn_sin{k};
        if isfield(sout, fin2)
            if isstruct(s.(fin2))
                fntmp = fieldnames(s.(fin2));
                if all(ismember(fntmp, 'tg')) %isfield(s.(fn_sin{u}), 'tg')%if it's struct tg, don't update anything within
                    sout.(fin2) = s.(fin2);
                else
                    if isstruct(sout.(fin2))
                        sout.(fin2) = structfill(s.(fin2), sout.(fin2));
                    else
                        error(fin2 + " is not a substruct in default struct sdf (at least not where it appears in s)")
                    end
                end
            else
                if ~isempty(s.(fin2)) %in case we're in an index of nonscalar struct where s wasn't specified
                    sout.(fin2) = s.(fin2); %update
                end
            end
        else
            error(fin2 + " is not a field in default struct sdf (at least not where it appears in s)")
        end
    end
end

