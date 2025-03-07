import struct

benc_flag = [
    0xa9, 0xb3, 0xdd, 0xb6, 0x23, 0x2c, 0x16, 0x36, 
    0xbf, 0xfa, 0x89, 0x18, 0x3b, 0xe7, 0xe4, 0x6c, 
    0xfc, 0xf8, 0x5a, 0xa, 0x15, 0x84, 0xff, 0x21, 
    0x57, 0x95, 0x85, 0x44, 0xb7, 0x27, 0xc2, 0x2d
]

# benc_input = [
#     0xB1, 0xCB, 0x06, 0x54, 0xA2, 0x1E, 0xA4, 0xA4, 
#     0xC5, 0x9A, 0x48, 0x34, 0x97, 0x87, 0xD6, 0x53, 
#     0x6F, 0xC0, 0xE0, 0xB8, 0xDB, 0xF2, 0x59, 0x02, 
#     0x82, 0x8D, 0xE3, 0x52, 0x1D, 0x5E, 0x5D, 0x59
# ]

denc_flag = [struct.unpack('<I', bytes(benc_flag[i:i+4]))[0] for i in range(0, len(benc_flag), 4)]

key = [0x5454, 0x4602, 0x4477, 0x5e5e]
delta = 0xFF58F981
ini_sum = 0xE8017300

# def encrypt(v4, v5):
#     sum = ini_sum
#     for i in range(32):
#         v4 = (v4 + ((((v5 << 4) & 0xFFFFFFFF ^ (v5 >> 5)) + v5) ^ 
#                 (sum + key[sum & 3]) ^ 0x44) & 0xFFFFFFFF)

#         v5 = (v5 + ((((v4 << 5) & 0xFFFFFFFF ^ (v4 >> 6)) + v4) ^ 
#                 (sum + key[(sum >> 11) & 3]) ^ 0x33) & 0xFFFFFFFF)
        
#         sum = (sum - delta) & 0xFFFFFFFF
#     return v4, v5

# def end_process(inp):
#     for i in range(8):
#         for j in range(32):
#             if inp[i] & 0x80000000:
#                 inp[i] = (inp[i] << 1) ^ 0x84A6972F
#             else:
#                 inp[i] <<= 1
#             inp[i] &= 0xFFFFFFFF

def decrypt(v4, v5):
    sum = (ini_sum - 32 * delta) & 0xFFFFFFFF
    for i in range(32):
        sum = (sum + delta) & 0xFFFFFFFF

        v5 = (v5 - ((((v4 << 5) & 0xFFFFFFFF ^ (v4 >> 6)) + v4) ^ 
                (sum + key[(sum >> 11) & 3]) ^ 0x33)) & 0xFFFFFFFF
        
        v4 = (v4 - ((((v5 << 4) & 0xFFFFFFFF ^ (v5 >> 5)) + v5) ^ 
                (sum + key[sum & 3]) ^ 0x44)) & 0xFFFFFFFF
    return v4, v5

def rev_end_process(denc_flag):
    for i in range(8):
        for j in range(32):
            if denc_flag[i] & 1:
                denc_flag[i] = ((denc_flag[i] ^ 0x84A6972F) >> 1) | 0x80000000
            else:
                denc_flag[i] >>= 1
    
def main():
    rev_end_process(denc_flag)
    
    list_flag = [0] * len(denc_flag)
    for i in range(0, len(denc_flag), 2):
        v4, v5 = denc_flag[i], denc_flag[i+1]
        dec_v4, dec_v5 = decrypt(v4, v5)
        list_flag[i] = dec_v4
        list_flag[i+1] = dec_v5

    flag = b''.join([struct.pack('<I', i) for i in list_flag])
    print(flag)


main()