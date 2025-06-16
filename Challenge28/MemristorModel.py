#Author: Satyajit Deokar
#PSU ID: 958613207

import numpy as np
import matplotlib.pyplot as plt
import pandas as pd

# ----------------------------
# 1. Memristor model parameters
Ron = 100.0          # Low resistance state (Ohms)
Roff = 16e3          # High resistance state (Ohms)
D = 10e-9            # Device length (meters)
mu = 1e-14           # Ion mobility (m^2/Vs)
k = mu * Ron / (D ** 2)  # Drift constant
p = 2                # Order of Biolek window function

def window(x, p):
    """Biolek window function to suppress boundary drift."""
    return 1 - (2 * x - 1) ** (2 * p)

# ----------------------------
# 2. Simulation function
def simulate(V_amp=1.0, freq=1e3, dt=1e-7, t_end=5e-3, x_init=0.1):
    """
    Simulate the memristor under sinusoidal voltage.
    Returns arrays for voltage (V) and current (I).
    """
    t = np.arange(0, t_end, dt)
    v = V_amp * np.sin(2 * np.pi * freq * t)
    x = x_init
    i_data, v_data = [], []

    for V in v:
        M = Ron * x + Roff * (1 - x)
        I = V / M
        dx = k * I * window(x, p) * dt
        x = np.clip(x + dx, 0.0, 1.0)
        v_data.append(V)
        i_data.append(I)

    return np.array(v_data), np.array(i_data)

# ----------------------------
# 3. Run the simulation
V, I = simulate()

# ----------------------------
# 4. Plot I–V characteristic
plt.figure(figsize=(6, 5))
plt.plot(V, I, color='navy', lw=1.5)
plt.xlabel("Voltage (V)")
plt.ylabel("Current (A)")
plt.title("Memristor I–V Hysteresis Loop (Biolek Model)")
plt.grid(True)
plt.tight_layout()
plt.show()

# ----------------------------
# 5. Display sample data
df = pd.DataFrame({
    "Voltage (V)": V[:10],
    "Current (A)": I[:10]
})
print("Sample data (first 10 points):")
print(df)
