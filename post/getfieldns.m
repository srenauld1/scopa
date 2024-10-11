function out = getfieldns(s,field)

%get field values in nonscalar struct

out = {s.(field)};

end
