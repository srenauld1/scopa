import numpy as np

class map2params():
    def __init__(self):
        
        self.params = {}
        self.params['m2p_merge_thresh'] = [.3]
        self.params['m2p_gsig'] = [3] #[2, 3, 4]
        self.params['m2p_nb'] = [1]
        self.params['SC_sigma'] = [1, 2, 4]
        self.params['lambda_gnmf'] = [1, 2, 4]
        self.params['perc_baseline_snmf'] = [20,40] #10, 20, 40]
        self.params['max_iter_snmf'] = [1000]

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
        assert 0 <= index <= self.max_index
        return self.map[index]

# if __name__ == "__main__":
#     M = map2params(stim_dim= 100)
#     print(M.order)
#     print(M.map_index(25))

