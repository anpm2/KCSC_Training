import struct

benc_input = [
    0xB1, 0xCB, 0x06, 0x54, 0xA2, 0x1E, 0xA4, 0xA4, 
    0xC5, 0x9A, 0x48, 0x34, 0x97, 0x87, 0xD6, 0x53, 
    0x6F, 0xC0, 0xE0, 0xB8, 0xDB, 0xF2, 0x59, 0x02, 
    0x82, 0x8D, 0xE3, 0x52, 0x1D, 0x5E, 0x5D, 0x59
]

denc_input = [struct.unpack('<I', bytes(benc_input[i:i+4]))[0] for i in range(0, len(benc_input), 4)]

key = [0x5454, 0x4602, 0x4477, 0x5e5e]
delta = 0xFF58F981
ini_sum = 0xE8017300

def decrypt(v4, v5):
    sum = (ini_sum - 32 * delta) & 0xFFFFFFFF
    for i in range(32):
        sum = (sum + delta) & 0xFFFFFFFF
        
        v5 = (v5 - ((((v4 << 5) & 0xFFFFFFFF ^ (v4 >> 6)) + v4) ^ 
                (sum + key[(sum >> 11) & 3]) ^ 0x33)) & 0xFFFFFFFF
        
        v4 = (v4 - ((((v5 << 4) & 0xFFFFFFFF ^ (v5 >> 5)) + v5) ^ 
                (sum + key[sum & 3]) ^ 0x44)) & 0xFFFFFFFF
    return v4, v5

def main():
    list_flag = [0] * len(denc_input)
    for i in range(0, len(denc_input), 2):
        v4, v5 = denc_input[i], denc_input[i+1]
        dec_v4, dec_v5 = decrypt(v4, v5)
        list_flag[i] = dec_v4
        list_flag[i+1] = dec_v5
    flag = b''.join([struct.pack('<I', i) for i in list_flag])
    print(flag)

main()