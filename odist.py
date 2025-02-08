class odist():


    def __init__(self, opt):

        self.map = []
        self.max_index = 1
        for key,val in opt.items():
            self.outer(val)
            self.max_index *= len(val)
        self.max_index-= 1
        self.order = list(opt.keys())

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

