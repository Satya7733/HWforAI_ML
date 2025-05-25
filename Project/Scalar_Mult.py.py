# Elliptic Curve Scalar Multiplication (without external libraries)

def inverse_mod(k, p):
    """Return the modular inverse of k modulo p."""
    if k == 0:
        raise ZeroDivisionError('division by zero')
    return pow(k, -1, p)

def is_on_curve(x, y, a, b, p):
    """Check if the point lies on the curve."""
    return (y * y - (x * x * x + a * x + b)) % p == 0

def point_add(P, Q, a, p):
    """Add two points P and Q on the elliptic curve."""
    if P is None: return Q
    if Q is None: return P

    x1, y1 = P
    x2, y2 = Q

    if x1 == x2 and y1 != y2:
        return None  # Point at infinity

    if P != Q:
        m = (y2 - y1) * inverse_mod(x2 - x1, p) % p
    else:
        if y1 == 0:
            return None  # Tangent is vertical
        m = (3 * x1 * x1 + a) * inverse_mod(2 * y1, p) % p

    x3 = (m * m - x1 - x2) % p
    y3 = (m * (x1 - x3) - y1) % p
    return (x3, y3)

def scalar_mult(k, P, a, p):
    """Multiply point P by scalar k on the curve."""
    result = None  # Point at infinity
    addend = P

    while k:
        if k & 1:
            result = point_add(result, addend, a, p)
        addend = point_add(addend, addend, a, p)
        k >>= 1

    return result

# === Curve Parameters (from your Verilog testbench) ===

p  = 0xfffffffffffffffffffffffffffffffeffffffffffffffff
a  = 0xfffffffffffffffffffffffffffffffefffffffffffffffc
b  = 0  # assumed (adjust if you know the curve)

x1 = 0xd458e7d127ae671b0c330266d246769353a012073e97acf8
y1 = 0x325930500d851f336bddc050cf7fb11b5673a1645086df3b
P = (x1, y1)

k = 2  # scalar

# === Compute k * P ===

if not is_on_curve(x1, y1, a, b, p):
    print("Point is not on the curve!")
else:
    xk, yk = scalar_mult(k, P, a, p)
    print("k * P = (x, y)")
    print(f"x = {hex(xk)}")
    print(f"y = {hex(yk)}")
