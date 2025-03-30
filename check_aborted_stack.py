import json

def check_aborted_stack(md, pthmd, stack, stackisvol):
    if stackisvol==0 and md['dims'][0] != stack.shape[0]:
        print("stack cannot be reshaped into dimensions reported in tif header, but since it is not volumetric, assuming user aborted acquisition and updating metadata to match stack dimensions")
        md['numvol'] = stack.shape[0]
        md['dims'][0] = md['numvol']
    with open(pthmd, 'w') as file: 
        file.write(json.dumps(md, sort_keys=True, indent=4))
    return md
