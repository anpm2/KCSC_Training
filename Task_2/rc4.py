state = list(range(256))
cipher = []

def rc4(plain, plen, key, klen, cipher):
    j = 0
    for i in range(256):
        j = (j + state[i] + ord(key[i % klen])) % 256
        state[i], state[j] = state[j], state[i]

    i = j = 0
    for idx in range(plen):
        i = (i + 1) % 256
        j = (j + state[i]) % 256
        state[i], state[j] = state[j], state[i]
        xor_byte = ord(plain[idx]) ^ state[(state[i] + state[j]) % 256]
        cipher.append(xor_byte)


def main():
    plain = input("Nhap plaintext: ")
    key = input("Nhap key: ")
    rc4(plain, len(plain), key, len(key), cipher)
    print(f"ciphertext (hex): {''.join([hex(byte)[2:] for byte in cipher])}")


main()