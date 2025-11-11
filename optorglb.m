function opt = optorglb(opt, df)

%{

handle function inputs that are both name-value arguments and globals in function glb;
a2p uses a few global variables (in glb) that get set early
some functions (eg, structfile, vget, rgmake) that are likely to be used outside a2p have these variables as name-value arguments also 
when running a2p, the globals are used instead of their name-value counterparts (the name-value argument is omitted by a2p)
but if the user wants to run these functions outside a2p, optorglb handles any conflicts, in case the user wants to set the name-value arguments, but still has the variables set in glb 
if name-value argument is nonempty and its counterpart in glb is empty, use the name-value argument
if name-value argument is empty and its counterpart in glb is nonempty, use the glb variable
if name-value argument and its counterpart in glb are both nonempty, error if they're different; if they're the same, use their value
if name-value argument is empty and its counterpart is empty, do nothing

%}

arguments
    opt % the name-value argument being compared with possible counterpart in glb
    df = [] %default value for the argument, in case name-value argument and glb counterpart are both empty 
end

nm = inputname(1);

glb_var = glb(nm);
if isempty(opt)
    if isempty(glb_var)
        opt = df;
    else
        opt = glb_var;
    end
else
    if ~isempty(glb_var) && ~isequal(opt, glb_var)
        error("you have set name-value argument '" + nm + "' and glb('" + nm  + "') to different values; remove glb('" + nm  + "'), or don't pass in name-value argument argument '" + nm + "', or make them match")
    end
end
