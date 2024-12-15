
def dictsort(din):
    dout = {}
    for m in sorted(din.keys(), key=str.casefold):
        v = din[m]
        if isinstance(v, dict):
            dout[m] = dictsort(v)
        else:
            dout[m] = v
    return dout
