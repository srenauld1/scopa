

#!/usr/bin/env python

import sys
import cv2
import caiman as cm
import numpy as np

Y = cm.load('/Users/wienecke/Documents/ambrose/stacks/20230624-2_D05_syt7f_018_syt7f/20230624_2_1_caimanreg_.tif')
fukit = Y.shape
print(fukit)
with open('/Users/wienecke/Documents/ambrose/stacks/20230624-2_D05_syt7f_018_syt7f/fuktest003' + str(fukit) + '_.npy', 'wb') as fncrop:
    np.save(fncrop, fukit)
