classdef mfit2
    properties
        opts = []
    end
    methods
        function obj = mfit2(val)
            arguments
                val = []
            end
            if isstruct(val) || isempty(val)
                obj.opts = mfit2pars(val);
            else
                error("must pass struct into mfit2")
            end
        end
    end
end

