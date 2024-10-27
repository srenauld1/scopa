class map2opt():
    def __init__(self):

        self.opt = {}

        # "important" options used in main
        self.opt['gSig'] = [ [2, 2, 0.5],[2, 2, 1.5] ] #list of lists; z (3rd element) ignored if extract_in_2d; 
        self.opt['method_init'] = ['graph_nmf']
        self.opt['nb'] = [1,2]
        self.opt['update_background_components'] = [True] 
        self.opt['low_rank_background'] = [True]
        self.opt['merge_thresh'] = [0.85] 
        self.opt['normalize_init'] = [True] 
        self.opt['only_init'] = [False] 
        self.opt['roidensity'] = [0.4] 
        self.opt['p'] = [1]
        # "important" initialization options for sparse_nmf and graph_nmf
        self.opt['sigma_smooth_snmf_time'] = [0.5] #first element of sigma_smooth_snmf, for smoothing in time before initialization
        self.opt['perc_baseline_snmf'] = [20]
        self.opt['max_iter_snmf'] = [500] 
        self.opt['sparsity_penalty'] = [1]

        self.map = []
        self.max_index = 1
        for key,val in self.opt.items():
            self.outer(val)
            self.max_index *= len(val)
        self.max_index-= 1
        self.order = list(self.opt.keys())

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
            raise Exception("optex_setind is greater than total num option sets")
        return self.map[index]
