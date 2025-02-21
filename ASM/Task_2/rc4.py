plain = input("Nhap plaintext: ")
key = input("Nhap key: ")
state = []
cipher = []

def ksa():
    for i in range(256):
        state.append(i)
    j = 0
    for i in range(256):
        j = (j + state[i] + ord(key[i % len(key)])) % 256
        state[i], state[j] = state[j], state[i]

def prga():
    i = j = 0
    for byte in plain:
        i = (i + 1) % 256
        j = (j + state[i]) % 256
        state[i], state[j] = state[j], state[i]
        xor_byte = ord(byte) ^ state[(state[i] + state[j]) % 256]
        cipher.append(format(xor_byte, '02x'))

def main():
    ksa()
    prga()
    print(f'ciphertext (hex): {"".join(cipher)}')


main()