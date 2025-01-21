classdef muk
    properties
        val = 80
        hal = 81
    end
    methods
        function obj = muk(val)
            if nargin == 1
                obj.val = val;
            end
        end
    end
    methods
        function r = duk(obj,fool)
            r = obj.val+fool;
        end
    end
end