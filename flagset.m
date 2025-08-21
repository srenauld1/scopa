function s = flagset(nm, val, opt)

%{

create struct s, fieldnames are "flags", values are states
initialize set of flags and states when name-value argument init=1, 
and subsequent calls to flagset use these flags and states (until next initialization)

s = flagset(nm,val,init=1)
    will initialize all nm with first element of val, use name-value argument me=1 to make nm mutually excclusive (see below) 
s = flagset(val)
    will set all nm from initialization to val
s = flagset()
    will remove all nm and val from memory and return empty struct s

name-value arguments are required when initializing, but should be omitted when not initializing 

%}

arguments
    nm = [] % flag names (fieldnames) to be set; cell array of char vectors or char vector or string array; if nm and val are both empty, s struct is reset to empty and persistent variables are cleared
    val = [] % state(s) (value(s) given to fieldnames nm); numeric, char, or string; vector or cell with at least 2 elements when init=1, scalar vector or cell when init=0; val is all permissible states in future flagset calls when not initializing (when init~=1); when init=1, first element of val is the "zero state" to which all nm are initialized; to use empty array as val, must put in cell (e.g., {[]}) 
    opt.init = [] % 1 to initialize struct with flags named in nm, if init=0 (or not specified) nm is name of flag(s) to be set to val, and nm must come from nm set passed in when init=1;
    opt.me = [] % 1 to make flags mutually exclusive, where all nm passed in (when init is not 1) are set to val and all nm not passed in (but "remembered" from when init=1) are set to "zero state" (first element of val passed in when init=1)
end

persistent stmp
persistent valtmp
persistent me

if isempty(nm) && isempty(val) %reset with flagset() syntax 

    if any(~structfun(@isempty, opt))
        error("cannot pass in name-value arguments if positional arguments are empty")
    end
    me = [];
    stmp = struct;
    s = stmp;

else %otherwise check arguments

    if isempty(opt.init)
        opt.init = 0;
    else
        if ~ismember(opt.init, [0,1])
            error("init can only be 0 or 1")
        end
    end
    if nargin==2 && isempty(val)
        error("flagset(nm, []) is not valid syntax")
    end
    if nargin==1 || ( isempty(nm) && ~isempty(val) )
        if isempty(stmp) || isempty(fieldnames(stmp))
            error("you can only use flagset(val), or flagset([], val), syntax if you have previously initialized with flagset(state,value,opt) syntax; there are no stored nm or val, so you either didn't initialize or an error cleared the persistent variables, so you must initialize")
        end
        if opt.init
            error("flagset(val,init=1) is not valid syntax, flagset(val) syntax can only be used when not initializing")
        end
        if nargin==1 %if flagset(val), swap nm and val here 
            val = nm;
            nm = [];
        end
    else
        nm = convertStringsToChars(nm);
        if ~iscell(nm)
            nm = {nm};
        end
    end

    if ~isvector(val)
        error("val must be vector")
    end
    if ~iscell(val)
        val = num2cell(val); %put in cell since val can be various classes, this works for numeric, char, and string vectors
    end



    if opt.init %initialize

        if any(structfun(@isempty, opt))
            error("when init is true, you must set all name-value arguments")
        end
        me = logical(opt.me);

        if numel(val)<2
            error("val must have at least 2 values when init=1 (purpose of flagset is to set states)")
        end
        valtmp = val;

        if isempty(nm)
            error("must pass in cbflag names to initialize (ie when init=1)")
        end
        stmp = [];
        for k = 1:numel(nm)
            stmp.(nm{k}) = val{1}; %initialize all to first element of val ("zero state")
        end
        s = stmp;

    else %if not initializing

        nmtmp = fieldnames(stmp);
        if isempty(nm) 
            nm = nmtmp;
        end

        if ~any(ismember(nmtmp, nm))
            error("nm has elements not from original nm set during initialization (when init=1)")
        end

        if all(cellfun(@isstring, valtmp))
            if ~all(cellfun(@isstring, val))
                error("val is not string, but was string array during initialization")
            else
                if any(~ismember(cellstr(val), cellstr(valtmp)))
                    error("val has elements not from original val set during initialization (when init=1)")
                end
            end
        else
            if all(cellfun(@isstring, val))
                error("val is a string, but was not a string array during initialization")
            else
                if all(cellfun(@isempty, val))
                    if ~any(cellfun(@isempty, valtmp)) 
                        error("val is empty array, but no empty arrays were used in val during initialization")
                    end
                else
                    valtmp_nonempty = valtmp(~cellfun(@isempty,valtmp));
                    if any(~ismember(cell2mat(val), cell2mat(valtmp_nonempty)))
                        error("val has elements not from original val set during initialization (when init=1)")
                    end
                end
            end
        end
        if numel(val)>1
            error("val must be scalar if not initializing")
        end
        if sum(~structfun(@isempty, opt))>1 %opt.init is forced to be nonempty above, so greater than 1 means another opt is nonempty
            error("you can only set name-value arguments during initialization (when init=1)")
        end

        for k = 1:numel(nmtmp)
            if ismember(nmtmp{k}, nm)
                s.(nmtmp{k}) = val{1};
            else
                if me
                    s.(nmtmp{k}) = valtmp{1};
                else
                    s.(nmtmp{k}) = stmp.(nmtmp{k});
                end
            end
        end

    end

end
