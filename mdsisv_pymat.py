
# import sys
# from pathlib import Path
# sys.path.append(str(Path('/Users/wienecke/scopa').parent))

from mdsisv import mdsisv

import sys

name_of_script = sys.argv[0]
pthstack = sys.argv[1]
pthmd = sys.argv[2]

# pthstack='/Users/wienecke/stacks/20230627-2_D05_syt7f_018_syt7f/20230627_2_2_ord_.mat'
# pthmd = ''
mdsisv(pthstack, pthmd)