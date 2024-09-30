classdef mfit2
    properties
        opts = []
    end
    methods
        function obj = mfit2(val)
            obj.opts = mfit2pars(val);
        end
    end
end

