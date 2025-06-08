import hashlib
import secrets
import os
import subprocess

# Choose between HW and SW scalar multiplication here:
USE_HW = True  # Toggle this to True to use RTL version

# ——— Domain parameters for secp256k1 ———
p  = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F
a  = 0
b  = 7

Gx = 0x79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798
Gy = 0x483ADA7726A3C4655DA4FBFC0E1108A8FD17B448A68554199C47D08FFB10D4B8
G  = (Gx, Gy)

n  = 0xFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141

# ——— Finite-field and EC point ops ———
def inv_mod(k, m):
    return pow(k, -1, m)

def is_on_curve(P):
    if P is None:
        return True
    x, y = P
    return (y*y - (x*x*x + a*x + b)) % p == 0

def point_add(P, Q):
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

# Hardware-based scalar multiplication via Cocotb/Questa

def hw_scalar_mult(k: int, Px: int, Py: int) -> tuple:
    env = os.environ.copy()
    env["K_SCALAR"] = str(k)
    env["PX"] = str(Px)
    env["PY"] = str(Py)

    # Get the absolute path to the tb/ directory
    base_dir = os.path.dirname(os.path.abspath(__file__))
    tb_dir = os.path.abspath(os.path.join(base_dir, "..", "tb"))
    result = subprocess.run(["make", "-C", "tb", "SIM=questa"], env=env, capture_output=True, text=True)

    if result.returncode != 0:
        print(result.stderr)
        raise RuntimeError("Simulation failed")

    X, Y = None, None
    for line in result.stdout.splitlines():
        if line.startswith("RESULT_X="):
            X = int(line.split("=")[1])
        if line.startswith("RESULT_Y="):
            Y = int(line.split("=")[1])

    if X is None or Y is None:
        raise ValueError("Output values not found in simulation output")

    return X, Y

# Software-based scalar multiplication

def sw_scalar_mult(k, P):
    result = None
    addend = P
    while k:
        if k & 1:
            result = point_add(result, addend)
        addend = point_add(addend, addend)
        k >>= 1
    return result

def scalar_mult(k, P):
    if USE_HW:
        x1, y1 = hw_scalar_mult(k, P[0], P[1])
        sw_x, sw_y = sw_scalar_mult(k, P)
        if (x1, y1) != (sw_x, sw_y):
            print("[MISMATCH] HW != SW")
            print(f"HW: ({hex(x1)}, {hex(y1)})")
            print(f"SW: ({hex(sw_x)}, {hex(sw_y)})")
            raise ValueError("HW scalar_mult output does not match SW reference")
        return x1, y1
    else:
        return sw_scalar_mult(k, P)

def gen_keypair():
    priv = secrets.randbelow(n-1) + 1
    pub  = scalar_mult(priv, G)
    assert is_on_curve(pub)
    return priv, pub

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

if __name__ == "__main__":
    priv, pub = gen_keypair()
    msg = b"A" * (4096 * 4096)  # 4MB

    sig = sign(msg, priv)
    ok  = verify(msg, sig, pub)
    print("Verified on 4MB message:", ok)
