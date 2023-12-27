

pieces = open('pars.txt', 'r').read().split('\0')

print(pieces)
tmp = {}
while len(pieces) >= 2:
    k = pieces.pop(0); v = pieces.pop(0)
    tmp[k] = v

for key, value in tmp.items():
    litmp = list(tmp[key].split(" "))
    print(key)
    print(litmp)
    print("fuk")
    exec(key + '=litmp')
    print("fuk2")
    key
    print("fuk3")
    
