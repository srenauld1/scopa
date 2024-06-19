classdef tez
    properties
        val {mustBeNumeric}
        pal {mustBeNumeric}
    end
    methods (Access = public)
        function obj = tez(val, pal)
            if nargin == 2
                obj.val = val;
                obj.pal = pal;
            end
        end
        r = rndis(obj)
    end
end