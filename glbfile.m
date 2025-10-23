function glbf = glbfile(field)

%{

read data from file 'glbf.txt'
glbf stands for "globals file"
glbf.txt stores global variables for a2p that are valid for all users, and that should never be changed
    as opposed to function 'glb', which stores globals that can be changed frequently
    or function userdatfile, which reads/writes to userdat.txt, which stores user-specific data that should be changed infrequently or never 
glbfile(field) will output variable named field
glbfile() will output all variables in glbf.txt

%}

arguments
    field {mustBeTextScalar} = ''
end

pthglbf = [pthscopaget() 'glbf.txt'];

if isfile(pthglbf)
    glbf = structld(pthglbf);
else
    error(pthglbf + " does not exist on this filesystem; did you delete it? you can copy it from main branch")
end

if ~isempty(field)
    if isfield(glbf, field)
        glbf = glbf.(field);
        if isempty(glbf)
            error("requested field '" + field + "' has not been set glbf.txt")
        end
    else
        error("'" + field + "' is not field in " + pthglbf)
    end
end
