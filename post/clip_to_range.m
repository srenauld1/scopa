function [ data ] = clip_to_range( data, range )

range = sort( range ); 

data(data < range(1)) = range(1);
data(data > range(2)) = range(2);

end
