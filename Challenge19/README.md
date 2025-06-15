
# Challenge #19 – Binary Leaky Integrate-and-Fire (LIF) Neuron

## ✅ Objective

The goal of this challenge is to:

- Understand how a **binary Leaky Integrate-and-Fire (LIF)** neuron functions.
- Implement the LIF neuron behavior in **Verilog**.
- Simulate and validate its operation using a testbench and golden model.
- Explore its behavior with respect to the leak factor (λ), threshold (θ), and input patterns.

---

## 🧠 What is a Binary LIF Neuron?

The **binary LIF neuron** is a simplified model used in spiking neural networks. It mimics biological neurons that integrate inputs over time and fire (spike) once a threshold is reached. Here's how it works:

- **Potential accumulation:**
```

P(t) = λ \* P(t-1) + I(t)

```
- `P(t)` = potential at time `t`
- `λ` = leak factor (0 < λ ≤ 1)
- `I(t)` = binary input (0 or 1)

- **Spike generation:**
```

S(t) = 1 if P(t) ≥ θ, else 0

````
- `θ` = threshold

- **Reset behavior:**
- If `S(t) = 1` (i.e., neuron spikes), then `P(t)` is reset to a defined value (usually 0 or a fraction of `θ`).

---

## 💾 Implementation Summary

- Written in **synthesizable Verilog**, using **fixed-point arithmetic** (Q3.5 format by default).
- Parameterized for:
- Bit width and fractional precision.
- Leak factor as numerator and denominator (e.g., 8/10).
- Threshold value.
- Reset value after spike.

### RTL Module: `binary_lif_neuron.v`

- Implements the LIF logic:
- Multiply accumulated potential by leak factor (λ).
- Add current binary input.
- If threshold is crossed → spike and reset.
- Uses fixed-point math with configurable resolution.

### Testbench: `tb_binary_lif_neuron.v`

- Feeds a deterministic test pattern of binary inputs.
- Computes a **golden model** in `real` using the same leak and threshold values.
- Asserts correctness by comparing spike events with the golden output.

---

## 🧪 How to Simulate

1. Make sure you have `iverilog` installed.
2. Compile the design and testbench:

```bash
iverilog -g2012 -o lif.vvp rtl/binary_lif_neuron.v tb/tb_binary_lif_neuron.v
````

3. Run the simulation:

```bash
vvp lif.vvp
```

4. Expected output:

```
All checks passed!
```

If there is a mismatch between DUT and golden model, the testbench will report an error and abort.

---

## 🛠 Parameters You Can Tune

| Parameter    | Description                        | Example         |
| ------------ | ---------------------------------- | --------------- |
| `W`          | Total number of bits (Qm.f format) | 8               |
| `FRAC_BITS`  | Bits after binary point            | 5 (Q3.5 format) |
| `LAMBDA_NUM` | Numerator of leak factor λ         | 8               |
| `LAMBDA_DEN` | Denominator of leak factor λ       | 10 (λ = 0.8)    |
| `THRESH`     | Threshold value in Q format        | 20 (≈ 2.5)      |
| `RESET_VAL`  | Reset value after spike            | 0               |

---

## 📈 What You Learn

* How to **model time-dependent dynamics** in hardware.
* How to use **fixed-point math** to approximate real values in Verilog.
* How to structure reusable, parameterized RTL components.
* How to validate hardware designs against **reference models**.

---

## 🔍 Future Extensions

* Connect multiple neurons into a **spiking layer**.
* Add refractory period or inhibition logic.
* Visualize spike trains using VCD + GTKWave.
* Add a Cocotb testbench for more expressive Python-based testing.

---

## 📁 File Structure

```plaintext
Challenge19_BinaryLIF/
├── rtl/
│   └── binary_lif_neuron.v          # Main LIF neuron module
├── tb/
│   └── tb_binary_lif_neuron.v       # Self-checking testbench
└── README.md                        # You're here!
```

---

## 🧮 Example Configuration

* Leak factor (λ) = 0.8 → `LAMBDA_NUM = 8`, `LAMBDA_DEN = 10`
* Threshold (θ) = 2.5 → `THRESH = 20` for Q3.5
* Input: bursty binary pattern
* Output: spikes when accumulated potential ≥ 2.5, then resets

---

## ✅ Conclusion

This challenge successfully models and simulates a **binary Leaky Integrate-and-Fire neuron** in Verilog using fixed-point math and parameterization.
It serves as a basic building block for digital neuromorphic circuits and forms a good foundation for scaling up to hardware spiking neural networks.

