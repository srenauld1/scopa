function cb = default_cbflags(cb, varargin)

if isempty(cb)
    if ~all(strcmp('all', varargin))
        error("if cb is empty, reset domain must be 'all'")
    end
end

if any(strcmp('restart', varargin)) || any(strcmp('all', varargin))
    cb.restart.v = [];
    cb.restart.t = [];
end

if any(strcmp('val', varargin)) || any(strcmp('all', varargin))
    cb.val.v = [];
    cb.val.i = [];
    cb.val.roicen = [];
    cb.val.vdel = [];
    cb.val.tinds = [];
    cb.val.sampinc = [];
    cb.val.varchan = [];
    cb.val.imchan = [];
    cb.val.implane = [];
    cb.val.imcen = [];
    cb.val.vidcen = [];
end

if any(strcmp('quick', varargin)) || any(strcmp('all', varargin))
    cb.quick.varalpha = [];
    cb.quick.imalpha = [];
end

if any(strcmp('changed', varargin)) || any(strcmp('all', varargin))
    cb.changed.varalpha = [];
    cb.changed.imalpha = [];
end

if any(strcmp('labs', varargin)) || any(strcmp('all', varargin))
    cb.lab.title = [];
end

end