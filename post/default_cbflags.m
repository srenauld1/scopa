function cbflags = default_cbflags(cbflags, varargin)

if isempty(cbflags)
    if ~all(strcmp('all', varargin))
        error("if cbflags is empty, reset scope must be 'all'")
    end
end

if any(strcmp('restart', varargin)) || any(strcmp('all', varargin))
    cbflags.restart.v = [];
    cbflags.restart.t = [];
end

if any(strcmp('val', varargin)) || any(strcmp('all', varargin))
    cbflags.val.v = [];
    cbflags.val.i = [];
    cbflags.val.roicen = [];
    cbflags.val.vdel = [];
    cbflags.val.tinds = [];
    cbflags.val.sampinc = [];
end

if any(strcmp('quick', varargin)) || any(strcmp('all', varargin))
    cbflags.quick.linealpha = [];
end

if any(strcmp('labs', varargin)) || any(strcmp('all', varargin))
    cbflags.lab.title = [];
end

end