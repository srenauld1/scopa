function [ data ] = scale_range( data, rangeIn , rangeOut )

data = (data - rangeIn(1)) / diff( rangeIn );
data = data * diff( rangeOut ) + rangeOut(1);

end
