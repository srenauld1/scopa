class map2opt():

    # this hold carl's favorite options for tuning caiman roi extraction;
    # each option here is also an option in optex.py
    # options here, in map2opt, will overwrite their counterparts in optex
    # here each option is a list of scalars, if the option is a scalar in optex, or a list of lists if it's a list in optex
    # lists are distributed into all possible combinations and extract.py loops over these, so you can see how extraction is affected by varying these params; 
    # any params from optex can be used here, these are just my favorite because they seem to have the largest effect and are most variable across recordings 
    # if you change params, or their order below, you must change output in optex accortdingly
    # optreduce will remove redundant reduced sets, since the set can be unique but the options that get used can be redundant (since option use depend on other options)
    # these options also appear in the odf.m, in the matlab part of the scopa pipeline (so user can run caiman extraction from matlab); the full set of options in optex.py do not appear in odf.m, because there are so many

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

