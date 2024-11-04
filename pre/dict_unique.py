import numpy as np

def dict_unique(din, dout=None):

    #get list of unique dicts, from list of dicts din (if dout is None), or from two list of dicts din and dout (using this loop because terser lines failed)
    
    newdout = 0
    if dout is None:
        newdout = 1
        dout = [{}] #list of empty dict
    elif isinstance(dout, dict):
        dout2 = []
        nestflag = 0
        for key in dout:
            if isinstance(dout[key], dict): #convert dicts of dicts to list of dicts
                nestflag = 1
                dout2.append(dout[key])
            else:
                if nestflag:
                    raise Exception("dout is a dict of lists, but should be a dict, or a dict of dicts")
        if nestflag:
            dout = dout2
        else:
            dout = [dout]


    if not isinstance(din, list):
        din = [din]

    for k in np.arange(len(din)):
        foundmatch = 0
        for m in np.arange(len(dout)):
            found_diff = 0
            if din[k].keys() == dout[m].keys():
                for ind,key in enumerate(din[k].keys()):
                    if np.array_equal(din[k][key],dout[m][key]):
                        if ind==len(din[k].items())-1:
                            if found_diff==0:
                                if foundmatch==1:
                                    raise Exception("duplicates in dout, which should only contain unique dicts")
                                else:
                                    foundmatch = 1
                    else:
                        found_diff = 1
            else:
                found_diff = 1
            
        if k==0 and newdout:
            dout[0] = din[k]
        else:
            if foundmatch==0:
                dout.append(din[k])
    
    return dout

