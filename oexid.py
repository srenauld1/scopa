import json
from dict_unique import dict_unique
import os

def oexid(opt, pth_optroi):

    if os.path.isfile(pth_optroi):
        with open(pth_optroi, 'r') as file:
            optfile = json.loads(file.read())
    else:
        optfile = opt


    optnew = dict_unique(opt, optfile)
    optid = 1

    with open(pth_optroi, 'w') as file: 
        file.write(json.dumps(optnew, sort_keys=False, indent=4)) #don't sort keys, they've been sorted already 

    return optid
    