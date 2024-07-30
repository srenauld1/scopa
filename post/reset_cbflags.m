function cbflags = reset_cbflags(cbflags, varargin)

if isempty(cbflags)
    if ~all(strcmp('all', varargin))
        error("if cbflags is empty, reset scope must be 'all'")
    end
end

if any(strcmp('restart', varargin)) || any(strcmp('all', varargin))
    cbflags.restart.v = [];
    cbflags.restart.t = [];
end

if any(strcmp('get', varargin)) || any(strcmp('all', varargin))
    cbflags.get.v = [];
    cbflags.get.i = [];
    cbflags.get.tstart = [];
    cbflags.get.tend = [];
end

if any(strcmp('tmp', varargin)) || any(strcmp('all', varargin))
    cbflags.tmp.v = [];
    cbflags.tmp.i = [];
    cbflags.tmp.roipix = [];
    cbflags.tmp.tinds = [];
    cbflags.tmp.tstart = [];
    cbflags.tmp.tend = [];
end

if any(strcmp('val', varargin)) || any(strcmp('all', varargin))
    cbflags.val.v = [];
    cbflags.val.i = [];
    cbflags.val.roipix = [];
    cbflags.val.tinds = [];
end

if any(strcmp('delete', varargin)) || any(strcmp('all', varargin))
    cbflags.delete.roi = [];
    cbflags.change.t = [];
end

if any(strcmp('labs', varargin)) || any(strcmp('all', varargin))
    cbflags.lab.title = [];
end


end