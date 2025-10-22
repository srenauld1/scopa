classdef muks
    properties
        val = 800
        hal = 810
        jag = []
    end
    methods
        function obj = muks(val)
            obj.jag=2;
            if nargin == 1
                obj.val = val;
            end
        end
    end
    methods (Static)
        function r = duk(fool)
            r = 12+fool;
        end
    end
    methods
        function r = duks2(obj)
            r = 1+obj.uks();
        end
    end
    methods (Access=protected)
        function r = uks(obj)
            r = 1+obj.hal;
        end
    end
end
