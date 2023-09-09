

#!/usr/bin/env python

import numpy as np
from tifffile.tifffile import imwrite, imread

pth = '/n/scratch3/users/c/caw846/stacks/20230627-2_D05_syt7f_018_syt7f/20230627_2_2_cmnrgcaddn_.tif'
#pth = '/Users/wienecke/Documents/ambrose/stacks/20230627-2_D05_syt7f_018_syt7f/20230627_2_2_cmnrg_.tif'


Y = imread(pth)
print(Y.shape)
print(Y.dtype)
Y = Y.reshape(3047, 256, 15, 140) #t x z y 
print(Y.shape)
Y = np.transpose(Y, (0, 2, 3, 1)) #t z y x
print(Y.shape)
Y = Y.reshape(3047*15, 140, 256) #(tz) y x
print(Y.shape)
Y = imwrite(pth, Y)
