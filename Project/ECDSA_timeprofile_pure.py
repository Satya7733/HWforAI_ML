import hashlib
import secrets
import time
import pandas as pd
import matplotlib.pyplot as plt

# ——— Domain parameters for secp256k1 ———
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
    return pow(k, -1, m)

def is_on_curve(P):
    if P is None:
        return True
    x, y = P
    return (y*y - (x*x*x + a*x + b)) % p == 0

def point_add(P, Q):
    if P is None:
        return Q
    if Q is None:
        return P
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

# ——— Original scalar_mult (no prints) ———
def _orig_scalar_mult(k, P):
    result = None
    addend = P
    while k:
        if k & 1:
            result = point_add(result, addend)
        addend = point_add(addend, addend)
        k >>= 1
    return result

# ——— Instrumented wrapper for scalar_mult (time profiling only) ———
_scalar_mult_calls = 0
_scalar_mult_time  = 0.0

def scalar_mult(k, P):
    global _scalar_mult_calls, _scalar_mult_time
    start = time.perf_counter()
    R = _orig_scalar_mult(k, P)
    elapsed = time.perf_counter() - start
    _scalar_mult_calls += 1
    _scalar_mult_time  += elapsed
    return R

# ——— Key generation ———
def gen_keypair():
    priv = secrets.randbelow(n-1) + 1
    pub  = scalar_mult(priv, G)
    assert is_on_curve(pub), "pub is off-curve!"
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

# --- Experiment over multiple message sizes ---
message_sizes = [1*1024*1024, 2*1024*1024, 4*1024*1024, 8*1024*1024]  # bytes
results = []

for size in message_sizes:
    # Reset counters
    _scalar_mult_calls = 0
    _scalar_mult_time = 0.0

    # Start timing
    start_total = time.perf_counter()

    # Run keygen, sign, verify on message of given size
    priv, pub = gen_keypair()
    msg = b"A" * size
    sig = sign(msg, priv)
    ok = verify(msg, sig, pub)

    # End timing
    end_total = time.perf_counter()
    total_elapsed = end_total - start_total

    # Record results
    results.append({
        "Message Size (MiB)": size / (1024*1024),
        "Verified": ok,
        "Scalar_Mult Calls": _scalar_mult_calls,
        "Scalar_Mult Time (s)": _scalar_mult_time,
        "Total Time (s)": total_elapsed,
        "Percent in Scalar_Mult": (_scalar_mult_time / total_elapsed) * 100
    })

# Create DataFrame
df = pd.DataFrame(results)

# Plot Total Time and Scalar_Mult Time vs Message Size
plt.figure(figsize=(8, 5))
plt.plot(df["Message Size (MiB)"], df["Total Time (s)"], marker='o', label="Total Time")
plt.plot(df["Message Size (MiB)"], df["Scalar_Mult Time (s)"], marker='s', label="Scalar_Mult Time")
plt.xlabel("Message Size (MiB)")
plt.ylabel("Time (s)")
plt.title("Time vs Message Size")
plt.legend()
plt.grid(True)
plt.tight_layout()
plt.show()

# Display the DataFrame
import ace_tools as tools; tools.display_dataframe_to_user(name="Timing Results", dataframe=df)
