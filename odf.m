function [dall, pthopt] = odf(pthopt, dowrite)
 
%{

default options for a2p modules and child modules
    child module: a module that is only ever called from within a module in a2p; eg, roimauto (mos ma) is only ever called from roimake (mos roi)

running odf writes all options to txt file in scopa using jsonencode (written to file for stability)  
each section contains options for a module called in a2p (section header is mos name, then module name in parentheses, then brief description of module)

du fieldnames (mos) are ordered below by order of appearance in a2p
du2 mirrors du, but derives options from arguments block of each module (by calling module and outputting its name-value arguments struct opt); 
    du2 is compared with du, any mismatch causes error; 
    the purpose is to have all module options visible below in du, while letting each module's arguments block enforce argument validation

'mostree' is hard-coded (rather than derived from du) because submodule options are empty within the supermodule arguments block (by default submodules are skipped); 
    so du below lists top-level submodules as options (eg, du.bmp.mdl = [], but does not list submodules for module option, eg mdl.opg); 
    so mostree shows all possible module nestings; deriving mostree from du would only go one level deep

NOTE: module options are validated in each module's arguments block; 
    however, here, below, there is no argument validation; 
    the purpose of this list is to have all options and modules listed in one place for convenience and clarity 
    but this list is not functional (since any mismatch between these options and the corresponding module arguments block causes error)    

NOTE: if you change a default argument here, you must also change it in the corresponding arguments block

%}

arguments
    pthopt {mustBeTextScalar, mustBeNonempty} = [pthscopaget() 'optdf.txt'] %path to file holding all module default options
    dowrite {mustBeBinary} = 0 %write to file if 1
end


%% mosh struct holds function handles for all a2p modules;

mosh.s = @smakew; %wrapper
mosh.dq = @dqmakew; %wrapper
mosh.roi = @roimakew; %wrapper
mosh.cm = @roifauto;
mosh.ma = @roimauto;
mosh.qc = @roiqc;
mosh.nrm = @roinorm;
mosh.bmp = @bmpmakew; %wrapper
mosh.mdl = @mdlmakew; %wrapper
mosh.opl = @oplmake;
mosh.opg = @opgmake;
mosh.fmf = @fmfmakew; %wrapper


%% mostree (all mos and polymos currently supported in options struct o; oset ensures all mostree are populated in o; note some mos only appear nested within others (e.g. 'ma' only exists within 'roi'), but defaults for nested mos can still be retrieved using ofill, for example ofill('ma', unpack=1)

mostree = [  %in matlab sort order; in polymos, each is filled as in du below (ie roi.ma means roi gets filled, and ma gets filled below roi), as opposed to roi having nothing below but ma
    "bmp.mdl.opg", "bmp.mdl.opl", ...
    "dq", ...
    "fmf", ...
    "mdl.opg", "mdl.opl", ...
    "roi.cm", "roi.ma", "roi.nrm", "roi.qc", ...   
    "s", ...
    ];


fnmh = fieldnames(mosh);
for k = 1:numel(fnmh)
    [~, dutmp] = mosh.(fnmh{k})('', runtype=1); %call function handle with name-value agument runtype=1, which outputs only module options from each module's arguments block
    if any(structfun(@iscell, dutmp))
        error("at least one of the default values above is a cell; cells are not allowed to be default values because cells are used in oid.m to distribute options into unique sets")
    end
    if any(structfun(@(x) isstruct(x) & ~isempty(x), dutmp))
        error("at least one of the default module options in du is a nonempty struct; options in du cannot themselves be structs, unless they are empty structs (placeholder for nondefault options structs for child mos); child mos can appear in d (nested version of du) but only if their nesting is listed in mostree")
    end
    du.(fnmh{k}) = dutmp;
end



%% create d (nested version of du, nested according to mostree)

mostree_open = {};
cnt = 0;
for k = 1:numel(mostree)
    spl = strsplit(mostree{k}, '.');
    for q = 1:numel(spl)
        cnt = cnt+1;
        mostree_open{cnt} = strjoin(spl(1:q), '.');
    end
end
mostree_open = sort(convertCharsToStrings(unique(mostree_open))); %sort so we ascend, shallowest to deepest, since d is recursive fill of all mos

d = struct;
for k = 1:numel(mostree_open)
    spl = strsplit(mostree_open{k}, '.');
    stind = structind(mostree_open{k});
    d = setfield(d, stind{:}, du.(spl{end})); %set deepest to the unnested mos from du
end



%% check for problems

fnd = fieldnames(du);
mostree_flat = unique(cellflat(cellfun(@(x,y) strsplit(x,y), mostree, repelem({'.'}, numel(mostree)), 'un', false)));
fninvalid = fnd(~ismember(fnd, mostree_flat));
if ~isempty(fninvalid)
    error("the following fields are in du, but not listed in mostree: " + cell2charv(fninvalid) )
end

mostree_invalid = mostree_flat(~ismember(mostree_flat, fnd));
if ~isempty(mostree_invalid)
    error("the following fields are listed in mostree, but are not fields in du: " + cell2charv(mostree_invalid) )
end

if ~strcmp(du.mdl.slvrl, 'fmincon')
    error("mdlmake currently only supports local solver fmincon")
end
if ~strcmp(du.mdl.slvrg, 'globalsearch')
    error("mdlmake currently only supports lobal solver globalsearch")
end

delimflat = glbfile('delimflat');
d_flat = structflat(d, delim=delimflat);
fn_d_flat = fieldnames(d_flat);
spl = cellfun(@(x) strsplit(x, delimflat), fn_d_flat, UniformOutput=false);
if any(cell2mat(cellfun(@(x) ~isequal(numel(x), numel(unique(x))), spl, UniformOutput=false)))
    error("there is a repeated fieldname in a vertical path through default options struct (could be an mos or an option, or an option with the same name as a mos; repeated names in a vertical path are currently not allowed")
end


%% derive mostrees

[mostree_d, mostree_open_d, mostree_top_d, options_d] = mostreeget(d, du); 
mostree_d_no_idx = regexprep(mostree_d, '\(\d+\)', '');
if ~isequal(mostree, mostree_d_no_idx)
    error("mostree and mostree_d (derived mostree from mostreeget) do not match")
end
mostree_open_d_no_idx = regexprep(mostree_open_d, '\(\d+\)', '');
if ~isequal(mostree_open, mostree_open_d_no_idx)
    error("mostree_open and mostree_d (derived mostree from mostreeget) do not match")
end
options_invalid = options_d(ismember(options_d, fnd));
if ~isempty(options_invalid)
    error("the following options have the same names as mos (not allowed): " + newline + sprintf('%s\n', options_invalid{:}))
end
options_invalid = options_d(strcmp(options_d, glbfile('fnvget')));
if ~isempty(options_invalid)
    error("in du there is an option named " + glbfile('fnvget') + ", this is not allowed because it is reserved as a struct name for function vget")
end


%% write to file

dall.d = d;
dall.du = du;
dall.mostree = mostree_d;
dall.mostree_open = mostree_open_d;
dall.mostree_top = mostree_top_d;

fnmh = fieldnames(mosh);
for k = 1:numel(fnmh)
    dall.mosh.(fnmh{k}) = func2str(mosh.(fnmh{k})); %write char, later must use str2func to use it (eg in ofill)
end

if dowrite
    fprintf("writing default options to: " + pthopt + newline)
    structsv(dall, pthopt, overwrite=1, readonly=1, dosort=1)
end








