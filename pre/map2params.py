import numpy as np

class map2params():
    def __init__(self):

        self.params = {}

        # "important" options used in main
        self.params['gSig'] = [ [2, 2, 0.5] ] #list of lists
        self.params['method_init'] = ['graph_nmf']
        self.params['nb'] = [1]
        self.params['update_background_components'] = [True] 
        self.params['low_rank_background'] = [True]
        self.params['merge_thresh'] = [0.85] 
        self.params['normalize_init'] = [True] 
        self.params['only_init'] = [False] 
        self.params['roidensity'] = [0.4] 
        self.params['p'] = [1]
        # "important" initialization options for sparse_nmf and graph_nmf
        self.params['sigma_smooth_snmf'] = [ [0.5, self.params['gSig'][0], self.params['gSig'][1], self.params['gSig'][2]] ] #list of lists
        self.params['perc_baseline_snmf'] = [20]
        self.params['max_iter_snmf'] = [500] 
        self.params['sparsity_penalty'] = [1]

        self.map = []
        self.max_index = 1
        for key,val in self.params.items():
            self.outer(val)
            self.max_index *= len(val)
        self.max_index-= 1
        self.order = list(self.params.keys())

    def outer(self,l2):
        if self.map == []:
            self.map = [[f2] for f2 in l2]
        else:
            prod = []
            for f1 in self.map:
                for f2 in l2:
                    prod.append(f1+[f2])
            self.map = prod
        return None

    def map_index(self,index):
        if index > self.max_index:
            raise Exception("index_extraction_param_set is greater than total num paream sets")
        return self.map[index]
