function s = stateset(nm, val, opt)

%struct cb holds state switches

arguments
    nm = [] %cell array of char vectors or char vector or string array; names of switches to be set; if nm and val are both empty, cb struct is reset to empty and persistent variables are cleared
    val = [] %state, if empty, true is assumed, false or 0 must be passed in to set switches to false (only necessary when me=0 when init=0)
    opt.init = [] %1 to initialize struct with switches named in nm, if init=0 (or init is not specified in function call, same as init=0) nm is name of flag(s) to be set to true, must come from nm set passed in when init=1
    opt.me = [] %1 to make switches mutually exclusive
end

persistent cbtmp
persistent valtmp
persistent me

if isempty(nm)
    if ~isempty(val) || any(~structfun(@isempty, opt))
        error("if first argument is empty, you cannot pass in second argument val, or any name-value arguments")
    end
    me = [];
    cbtmp = struct;
    s = cbtmp;
else
    if isempty(opt.init)
        opt.init = 0;
    end
    if isnumeric(nm) || islogical(nm)
        if isempty(fieldnames(cbtmp))
            error("first argument (nm) can only be 0 or 1 if you have previously initialized (init=1) with some switches named in nm")
        end
        if opt.init
            error("first argument (nm) can only be 0 or 1 if init=0")
        end
        if ~isempty(val)
            error("first positional argument can only be 0 or 1 if it is the only positional argument")
        end
        val = nm;
        nm = [];
    else
        nm = convertStringsToChars(nm);
        if ~iscell(nm)
            nm = {nm};
        end
    end

    if isempty(val)
        error("you must pass in numeric second argument if first argument is not numeric")
    end

    if opt.init
        if isempty(opt.me)
            error("when init is true, you must set value for 'me' also")
        else
            me = logical(opt.me); %set to default false if init
        end
        if numel(val)<2
            error("val must have at least 2 values when init=1 (otherwise this function has no purpose)")
        else
            valtmp = val;
        end
        if isempty(nm)
            error("must pass in cbflag names to initialize (ie when init=1)")
        else
            cbtmp = [];
            for k = 1:numel(nm)
                cbtmp.(nm{k}) = val(1); %initialize all to first value in val
            end
        end
        s = cbtmp;
    else
        if any(~ismember(val, valtmp))
            error("val is not one of the val set passed in when init=1")
        end
        if ~isempty(opt.me)
            error("when init is false, you cannot set value for 'me' (you already set it when init was true)")
        end


        % below commented out is a catch for one-to-all mutual exclusivity, not input vs others mutual exclusivity, the latter is more general so we go with that for now
        % if isequal(opt.init,0) && isequal(me,1) && numel(nm)>1
        %     error("you set me=1 when init=1, so you cannot pass in multiple cbflags (they are mutually exclusive)")
        % end

        fn = fieldnames(cbtmp);
        if isempty(nm) %we only get here with empty nm if passing in single numeric positional argument
            nm = fn;
        end
        if any(ismember(fn, nm))
            for k = 1:numel(fn)
                if ismember(fn{k}, nm)
                    s.(fn{k}) = val;
                else
                    if me
                        s.(fn{k}) = valtmp(1);
                    else
                        s.(fn{k}) = cbtmp.(fn{k});
                    end
                end
            end
        else
            error("cbflags you passed in are not part of the set you passed in during initialization (when init=1)")
        end
    end

end
