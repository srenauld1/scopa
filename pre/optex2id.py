import json

def optex2id(opt, methodex, pth_optex):

    with open(pth_optex, 'r') as file:
        optfile = json.loads(file.read())

    with open(pth_optex, 'w') as file: 
        file.write(json.dumps(optfile, sort_keys=False, indent=4)) #don't sort keys, they've been sorted already 

    return optid
    