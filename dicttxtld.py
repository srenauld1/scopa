import json
from dictsort import dictsort

def dicttxtld(pth):    
    
    #in matlab version of this, option to flatten is false, option to sort is true, option to force row vectors is true 
    
    with open(pth, 'r') as file:
        optdf = json.loads(file.read())
    optdf = optdf['cm']
    optdf = dictsort(optdf) 
    
    return optdf