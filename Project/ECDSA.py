import hashlib
import secrets

# ——— Domain parameters for secp256k1 ———
# Curve: y^2 = x^3 + a*x + b over F_p
p  = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
a  = 0
b  = 7

# Base point G
Gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
Gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
G  = (Gx, Gy)

# Order of G
n  = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141

# ——— Finite-field and EC point ops ———
def inv_mod(k, m):
    """Modular inverse k⁻¹ mod m."""
    return pow(k, -1, m)

def is_on_curve(P):
    if P is None:
        return True
    x, y = P
    return (y*y - (x*x*x + a*x + b)) % p == 0

def point_add(P, Q):
    """Add two points P + Q on the curve."""
    if P is None: return Q
    if Q is None: return P
    x1, y1 = P
    x2, y2 = Q
    if x1 == x2 and (y1 + y2) % p == 0:
        return None
    if P != Q:
        lam = ((y2 - y1) * inv_mod(x2 - x1, p)) % p
    else:
        lam = ((3*x1*x1 + a) * inv_mod(2*y1, p)) % p
    x3 = (lam*lam - x1 - x2) % p
    y3 = (lam*(x1 - x3) - y1) % p
    return (x3, y3)

def scalar_mult(k, P):
    """Multiply point P by scalar k via double-and-add."""
    result = None
    addend = P
    while k:
        if k & 1:
            result = point_add(result, addend)
        addend = point_add(addend, addend)
        k >>= 1
    return result

# ——— Key generation ———
def gen_keypair():
    priv = secrets.randbelow(n-1) + 1
    pub  = scalar_mult(priv, G)
    assert is_on_curve(pub)
    return priv, pub

# ——— ECDSA: hash, sign, verify ———
def sha256_int(msg: bytes) -> int:
    return int.from_bytes(hashlib.sha256(msg).digest(), 'big') % n

def sign(msg: bytes, priv: int):
    e = sha256_int(msg)
    while True:
        k = secrets.randbelow(n-1) + 1
        x1, y1 = scalar_mult(k, G)
        r = x1 % n
        if r == 0:
            continue
        s = (inv_mod(k, n) * (e + priv * r)) % n
        if s == 0:
            continue
        return (r, s)

def verify(msg: bytes, sig: tuple, pub: tuple) -> bool:
    r, s = sig
    if not (1 <= r < n and 1 <= s < n):
        return False
    e = sha256_int(msg)
    w = inv_mod(s, n)
    u1 = (e * w) % n
    u2 = (r * w) % n
    X = point_add(scalar_mult(u1, G), scalar_mult(u2, pub))
    if X is None:
        return False
    x1, _ = X
    return (x1 % n) == r

""" # ——— Demo & self-test ———
if __name__ == "__main__":
    priv, pub = gen_keypair()
    print("Private key:", hex(priv))
    print("Public key: ", (hex(pub[0]), hex(pub[1])))

    for msg in [b"", b"hello secp256k1", b"ECDSA demo"]:
        sig = sign(msg, priv)
        ok  = verify(msg, sig, pub)
        print(f"\nmsg: {msg!r}")
        print(f" signature: (r={hex(sig[0])}, s={hex(sig[1])})")
        print(f" verified?  {ok}")
 """
if __name__ == "__main__":
    priv, pub = gen_keypair()
    # 1MB of data
    msg = b"A" * (4096 * 4096)  # 4MB

    # Single sign+verify on a big message
    sig = sign(msg, priv)
    ok  = verify(msg, sig, pub)
    print("Verified on 1MB message:", ok)
