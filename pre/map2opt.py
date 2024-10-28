class map2opt():

    # this hold carl's favorite options for tuning roi extraction; 
    # lists are distributed into all possible combinations and extract.py loops over these, so you can see how extraction is affected by varying these params; 
    # any params from optex can be used here, these are just my favorite because they seem to have the largest effect and are most variable across recordings 
    # optreduce will remove redundant reduced sets, since the set can be unique but the options that get used can be redundant (since option use depend on other options)

    def __init__(self):

        self.opt = {}

        # "important" options used in main
        self.opt['gSig'] = [ [2, 2, 0.5], [4, 4, 1] ] #list of lists; z (3rd element) ignored if extract_in_2d; 
        self.opt['method_init'] = ['graph_nmf', 'sparse_nmf', 'greedy_roi']
        self.opt['nb'] = [1,2] 
        self.opt['low_rank_background'] = [True, False]
        self.opt['update_background_components'] = [True, False] 
        self.opt['merge_thresh'] = [0.95, 0.85, 0.65] 
        self.opt['normalize_init'] = [True] 
        self.opt['only_init'] = [True, False] 
        self.opt['roidensity'] = [0.4, 0.8] 
        self.opt['p'] = [0, 1, 2]
        # "important" initialization options for sparse_nmf and graph_nmf
        self.opt['sigma_smooth_snmf_time'] = [0.5] #first element of sigma_smooth_snmf, for smoothing in time before initialization; in optex, the xyz elements are assigned the same values as gSig 
        self.opt['perc_baseline_snmf'] = [5, 20]
        self.opt['max_iter_snmf'] = [500] 
        self.opt['sparsity_penalty'] = [1, 4] #not a caiman option, but assigned to caiman options alpha_snmf (when using method_init sparse_nmf) and lambda_gnmf (when using method_init graph_nmf)

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
