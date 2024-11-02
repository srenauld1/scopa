
def dict_ord(din):
    dout = {}
    for m in sorted(din.keys(), key=str.casefold):
        v = din[m]
        if isinstance(v, dict):
            dout[m] = dict_ord(v)
        else:
            dout[m] = v
    return dout
