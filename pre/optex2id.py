import json
from dict_unique import dict_unique

def optex2id(opt, methodex, pth_optroi):

    with open(pth_optroi, 'r') as file:
        optfile = json.loads(file.read())

    optnew = dict_unique(opt, optfile)

    with open(pth_optroi, 'w') as file: 
        file.write(json.dumps(optfile, sort_keys=False, indent=4)) #don't sort keys, they've been sorted already 

    return optid
    