import struct
import hashlib

# Initial hash values (first 32 bits of fractional parts of square roots of first 8 primes)
H = [
    0x6a09e667, 0xbb67ae85, 0x3c6ef372,
    0xa54ff53a, 0x510e527f, 0x9b05688c,
    0x1f83d9ab, 0x5be0cd19
]

# Round constants (first 32 bits of fractional parts of cube roots of first 64 primes)
K = [
    0x428a2f98, 0x71374491, 0xb5c0fbcf, 0xe9b5dba5,
    0x3956c25b, 0x59f111f1, 0x923f82a4, 0xab1c5ed5,
    0xd807aa98, 0x12835b01, 0x243185be, 0x550c7dc3,
    0x72be5d74, 0x80deb1fe, 0x9bdc06a7, 0xc19bf174,
    0xe49b69c1, 0xefbe4786, 0x0fc19dc6, 0x240ca1cc,
    0x2de92c6f, 0x4a7484aa, 0x5cb0a9dc, 0x76f988da,
    0x983e5152, 0xa831c66d, 0xb00327c8, 0xbf597fc7,
    0xc6e00bf3, 0xd5a79147, 0x06ca6351, 0x14292967,
    0x27b70a85, 0x2e1b2138, 0x4d2c6dfc, 0x53380d13,
    0x650a7354, 0x766a0abb, 0x81c2c92e, 0x92722c85,
    0xa2bfe8a1, 0xa81a664b, 0xc24b8b70, 0xc76c51a3,
    0xd192e819, 0xd6990624, 0xf40e3585, 0x106aa070,
    0x19a4c116, 0x1e376c08, 0x2748774c, 0x34b0bcb5,
    0x391c0cb3, 0x4ed8aa4a, 0x5b9cca4f, 0x682e6ff3,
    0x748f82ee, 0x78a5636f, 0x84c87814, 0x8cc70208,
    0x90befffa, 0xa4506ceb, 0xbef9a3f7, 0xc67178f2
]

def rotr(x, n):
    # Rotate right and mask to 32 bits
    return ((x >> n) | (x << (32 - n))) & 0xffffffff

def shr(x, n):
    return x >> n

def Ch(x, y, z):
    return (x & y) ^ (~x & z)

def Maj(x, y, z):
    return (x & y) ^ (x & z) ^ (y & z)

def Σ0(x):
    return rotr(x, 2) ^ rotr(x, 13) ^ rotr(x, 22)

def Σ1(x):
    return rotr(x, 6) ^ rotr(x, 11) ^ rotr(x, 25)

def σ0(x):
    return rotr(x, 7) ^ rotr(x, 18) ^ shr(x, 3)

def σ1(x):
    return rotr(x, 17) ^ rotr(x, 19) ^ shr(x, 10)

def pad(message: bytes) -> bytes:
    ml = len(message) * 8
    message += b'\x80'
    # Pad until length ≡ 448 mod 512
    while (len(message) * 8 + 64) % 512 != 0:
        message += b'\x00'
    # Append original length as 64-bit big-endian integer
    message += struct.pack('>Q', ml)
    return message

def sha256(message: bytes) -> str:
    message = pad(message)
    h = H[:]
    # Process each 512-bit chunk
    for i in range(0, len(message), 64):
        w = list(struct.unpack('>16L', message[i:i+64]))
        # Message schedule
        for j in range(16, 64):
            val = (σ1(w[j-2]) + w[j-7] + σ0(w[j-15]) + w[j-16]) & 0xffffffff
            w.append(val)
        a, b, c, d, e, f, g, h0 = h
        # 64-round compression
        for j in range(64):
            t1 = (h0 + Σ1(e) + Ch(e, f, g) + K[j] + w[j]) & 0xffffffff
            t2 = (Σ0(a) + Maj(a, b, c)) & 0xffffffff
            h0, g, f, e, d, c, b, a = g, f, e, (d + t1) & 0xffffffff, c, b, a, (t1 + t2) & 0xffffffff
        # Update hash state
        h = [(x + y) & 0xffffffff for x, y in zip(h, [a, b, c, d, e, f, g, h0])]
    # Produce final digest
    return ''.join(f'{x:08x}' for x in h)

if __name__ == "__main__":
    # Compare against hashlib for a few test vectors
    test_msgs = [b"", b"abc", b"hello"]
    for msg in test_msgs:
        custom = sha256(msg)
        builtin = hashlib.sha256(msg).hexdigest()
        print(f"message: {msg!r}")
        print(f"  match: {custom == builtin}")
        print(f"  custom:  {custom}")
        print(f"  builtin: {builtin}\n")
