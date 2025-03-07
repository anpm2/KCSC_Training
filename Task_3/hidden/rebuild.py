import struct

def rol(val, n):
    return ((val << n) | (val >> (32 - n))) & 0xFFFFFFFF

def ror(val, n):
    return ((val >> n) | (val << (32 - n))) & 0xFFFFFFFF

def encrypt(dest, dword_key):
    var_C = rol(dword_key[0], 5) + ror(dword_key[1], 3)
    var_8 = ror(dword_key[2], 3) - rol(dword_key[3], 5)
    var_4 = var_C ^ var_8 ^ dest

    if var_4 & 1 == 0:
        dword_key[0] ^= ror(var_8, 0xD)
        dword_key[1] ^= ror(var_8, 0xF)
        dword_key[2] ^= rol(var_C, 0xD)
        dword_key[3] ^= rol(var_C, 0xB)
    else:
        dword_key[0] ^= rol(var_8, 0xB)
        dword_key[1] ^= rol(var_8, 0xD)
        dword_key[2] ^= ror(var_C, 0xF)
        dword_key[3] ^= ror(var_C, 0xD)
    return var_4

def main():
    input = b'a'*108
    key = b'AlpacaHackRound8'
    dword_key = [struct.unpack('<I', key[i:i+4])[0] for i in range(0, len(key), 4)]
    dest = [struct.unpack('<I', input[i:i+4])[0] for i in range(0, len(input), 4)]
    for i in range(7):
        dest[i] = encrypt(dest[i], dword_key)

    print(dest)

main()