import struct

enc_flag = [0]*8
enc_flag[0] = 0xB6DDB3A9
enc_flag[1] = 0x36162C23
enc_flag[2] = 0x1889FABF
enc_flag[3] = 0x6CE4E73B
enc_flag[4] = 0xA5AF8FC
enc_flag[5] = 0x21FF8415
enc_flag[6] = 0x44859557
enc_flag[7] = 0x2DC227B7

byte_list = []
for dword in enc_flag:
    byte_list.extend(struct.pack('<I', dword))
# [print(hex(val), end=', ') for val in byte_list]

str = b"Z\x0485p6<17p6?\"=1$p9#p4c3$6+-Z\"978$q"
[print(chr(i ^ 0x50), end='') for i in str]
# print(len(str))