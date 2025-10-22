classdef muk<muks
    properties 
        val2 = 80
        hal2 = 81
    end
    methods
        function obj = muk(val)
            obj = obj@muks
            if nargin == 1
                obj.val2 = val;
            end
        end
    end
    methods (Static, Access=public)
        function rs = duk(fool)
            rs = duk@muks(fool);
            % r = 1+obj.duk2;
        end
    end
    methods (Access=protected)
        function r = duks2(obj)
            rs = duks2@muks(obj);
            r = 1+obj.uks(obj);
        end
    end
end

