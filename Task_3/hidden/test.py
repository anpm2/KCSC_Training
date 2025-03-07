import struct

def ror(val, n):
    return ((val >> n) | (val << (32 - n))) & 0xFFFFFFFF

def rol(val, n):
    return ((val << n) | (val >> (32 - n))) & 0xFFFFFFFF

def test():
    key = b'AlpacaHackRound8'
    dword_key = [struct.unpack('<I', key[i:i+4])[0] for i in range(0, len(key), 4)]

    inp = b'a'*108
    inp = [inp[i:i+4] for i in range(0, len(inp), 4)]
    inp = [struct.unpack('<I', inp[i])[0] for i in range(len(inp))]

    for i in range(len(inp)):
        var_C = rol(dword_key[0], 5) + ror(dword_key[1], 3) & 0xFFFFFFFF
        var_8 = ror(dword_key[2], 3) - rol(dword_key[3], 5) & 0xFFFFFFFF
        var_4 = var_C ^ var_8 ^ inp[i]
        print(f'var_C = {hex(var_C)}')
        print(f'var_8 = {hex(var_8)}')
        print(f'var_4 = {hex(var_4)}')
        break 

    if var_4 & 1 == 0:
        dword_key[0] ^= ror(var_8, 0xD)
        print(f'dword_key[0] = {hex(dword_key[0])}')

        dword_key[1] ^= ror(var_8, 0xF)
        print(f'dword_key[1] = {hex(dword_key[1])}')

        dword_key[2] ^= rol(var_C, 0xD)
        print(f'dword_key[2] = {hex(dword_key[2])}')

        dword_key[3] ^= rol(var_C, 0xB)
        print(f'dword_key[3] = {hex(dword_key[3])}')

    # else:
    #     dword_key[0] ^= rol(var_8, 0xB)
    #     print(f'dword_key[0] = {hex(dword_key[0])}')

    #     dword_key[1] ^= rol(var_8, 0xD)
    #     print(f'dword_key[1] = {hex(dword_key[1])}')

    #     dword_key[2] ^= ror(var_C, 0xF)
    #     print(f'dword_key[2] = {hex(dword_key[2])}')

    #     dword_key[3] ^= ror(var_C, 0xD)
    #     print(f'dword_key[3] = {hex(dword_key[3])}')

test()