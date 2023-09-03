

#!/usr/bin/env python

import sys
import cv2
import caiman as cm
import numpy as np
import json 
from ast import literal_eval

print(sys.argv)

numfuk = int(sys.argv[1].split(':')[-1]) #for passing index as arg in command line, this won't error on local, even though there's no colon
strfuk = sys.argv[2].split(':')[-1]

Y = cm.load('/Users/wienecke/Documents/ambrose/stacks/20230624-2_D05_syt7f_018_syt7f/20230624_2_1_caimanreg_.tif')
fukit = Y.shape
print(fukit)
with open('/Users/wienecke/Documents/ambrose/stacks/20230624-2_D05_syt7f_018_syt7f/duktest03' + str(fukit) + '_' + str(numfuk) + strfuk + '.npy', 'wb') as fncrop:
    np.save(fncrop, fukit)
