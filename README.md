# HWforAI_ML: Hardware Meets AI & ML Challenges

A collection of hands-on challenges blending hardware (HDL, CUDA, FPGA) and AI/ML (Python, PyTorch). Each challenge explores profiling, bottlenecks, and hardware acceleration for classic algorithms and neural models.

---
# ECDSA Scalar Multiplication Hardware Accelerator

## 🌟 Objective

Accelerate the scalar multiplication `k·P` on the **secp256k1** elliptic curve — a key computational step in the **ECDSA** digital signature scheme.

---

## 📀 Design Overview

* **Curve**: secp256k1 → `y² = x³ + 7` over a 256-bit prime field `Fp`
* **RTL Modules**:

  * Modular arithmetic (add, sub, mult, inv)
  * Point addition and doubling
  * Scalar multiplication (double-and-add algorithm)
* **Language**: Implemented entirely in **Verilog**

---

## 🧲 Verification & Co-Simulation

* ✅ Verified functionality using a **SystemVerilog testbench**
* 🔄 Performed **HW/SW co-simulation** using **Cocotb**:

  * Python test script controlled and validated RTL scalar multiplication
  * Results matched expected values for different scalar inputs

---

## 🏗️ Physical Implementation

* Currently synthesizing the design using the **OpenLane** flow
* Goal: generate a GDSII layout for hardware realization

---

## ⏱️ Software Profiling Results (Python)

* Message size: **4 MiB**
* Total `scalar_mult` calls: **4**
* Total time in `scalar_mult`: **0.1176 sec**
* Average time per call: **0.0294 sec**
* Total script execution time: **0.2565 sec**
* ⏳ Time spent in scalar multiplication: **\~45.85%**
* ✅ Signature successfully verified on a large message

---

## 🧠 Motivation for Acceleration

Python profiling reveals scalar multiplication consumes nearly **half** of the ECDSA flow's total time. This motivates implementing it as a hardware accelerator — which has now been completed, verified, and is currently being synthesized.

### Challenge Summaries

- **Challenge 1 – Beyond CMOS Device Exploration**
Explores the 2023 IEEE IRDS “Beyond CMOS” roadmap; surveys emerging devices such as spintronic, ferroelectric, and photonic logic/memory technologies aimed at succeeding CMOS scaling.

- **Challenge 2 – Intrinsic and Designed Computation**
Reviews Crutchfield et al.’s 2010 paper; contrasts natural (intrinsic) versus engineered (designed) computation in dynamical systems, highlighting non-digital paradigms like chaos computing and reservoir computing.

- **Challenge 3 – Physical System Solving Differential Equations**
Identified an analog op-amp integrator circuit that inherently solves differential equations through its electrical properties, without using software instructions or a digital processor.

- **Challenge 5 – ISA/Microarchitecture Design**  
  Profiles Matrix Multiplication, QuickSort, and AES in Python; proposes custom ISA and microarchitecture features for each workload.

- **Challenge 6 – Perceptron with Sigmoid Activation**  
  Implements and trains a single-neuron perceptron to learn NAND (successfully) and XOR (fails, motivating multi-layer networks).

- **Challenge 7 – Perceptron Learning VisualizationAnimates how a perceptron learns**
  To separate NAND logic in 2D space by updating weights and bias. Extends to a 2-layer neural network that successfully learns XOR with backpropagation, showing evolving nonlinear boundaries.

- **Challenge 8 – XOR Feed-Forward MLP with Backpropagation**  
  Implements a 2-2-1 multilayer perceptron from scratch in Python (NumPy, Matplotlib) to solve XOR via backpropagation. Includes animated visualization of learning, static and animated decision surfaces, and console diagnostics for weights/biases.

- **Challenge 10 – Q-Learning Profiling & HW Acceleration**  
  Profiles Python Q-learning (FrozenLake), identifies Q-update as a bottleneck, and implements a custom SystemVerilog accelerator module.

- **Challenge 11 – GPU vs CPU Q-Learning**  
  Compares CuPy (GPU) vs. NumPy (CPU) for Q-learning; finds GPU is slower for small problems due to overhead, and recommends CPU for small MDPs.

- **Challenge 12 – Q-Learning HW Acceleration (Dyna-Q)**  
  Benchmarks and profiles Dyna-Q agent; offloads multiply-accumulate kernel to custom hardware, achieving notable speedup.

- **Challenge 13 – CUDA SAXPY Benchmarking**  
  Benchmarks SAXPY on CUDA for increasing sizes; analyzes timing and scaling, with Python for visualization.

- **Challenge 14 – CUDA Fibonacci Benchmark**  
  Compares CUDA and CPU implementations for generating Fibonacci sequences; analyzes correctness and performance.

- **Challenge 16 – PyTorch vs Custom CUDA NN Forward-Pass**  
  Benchmarks a small neural network’s forward pass using PyTorch (CPU/GPU) and custom CUDA, showing hand-written CUDA can outperform frameworks for tiny models.

- **Challenge 17 – Systolic Array Bubble Sort**  
  Implements Bubble Sort on a linear systolic array (hardware-friendly), compares with Python software version, and visualizes execution time scaling. Demonstrates O(N²) for software vs. O(N) for hardware by exploiting parallel compare-and-swap.

---

For code, plots, and hardware files, see each challenge's folder.

**DHANYAWAD!**
