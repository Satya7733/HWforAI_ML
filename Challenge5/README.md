# Hardware ISA & Microarchitecture Proposals

Based on bytecode‑level profiles for three workloads—Matrix Multiplication, QuickSort, and AES encryption—below are tailored instruction‑set and microarchitecture recommendations.

---

## 1. Matrix Multiplication

### Profile Highlights
- **Loads:** ~32 % (streaming matrix elements)  
- **Calls & Constants:** ~18 % (loop overhead)  
- **Arithmetic:** ~6.5 % (multiply‑add operations)

### ISA & Microarchitecture Features
1. **Wide SIMD / FMA**  
   - 256‑ or 512‑bit vector registers (`V0…V15`)  
   - Fused‑Multiply‑Add instruction:  
     ```
     VFMADD.vv vd, vs1, vs2
     ```
2. **Strided & Block Loads**  
   - Gather/Scatter with programmable stride:  
     ```
     VLOAD.vs vd, [base], stride, count
     ```
   - Tile‑based loads into on‑chip scratchpad
3. **Software‑Managed Scratchpad**  
   ```
   SPM_LOAD  tile_reg, DRAM_addr
   SPM_STORE tile_reg, DRAM_addr
   ```
4. **Non‑Blocking Prefetch**  
   ```
   PREFETCH [addr, stride]
   ```
5. **Zero‑Overhead Hardware Loops**  
   ```
   LOOP LP_COUNT, label
   ```
6. **Register File & Pipelines**  
   - 32 vector + 32 scalar registers  
   - Dedicated FMA pipelines (one 256‑bit FMA per cycle)

---

## 2. QuickSort

### Profile Highlights
- **Loads:** ~28 % (array accesses)  
- **Branches & Comparisons:** ~10 % (partition logic & recursion)  
- **Calls & Stack Ops:** ~7–9 % (function calls)

### ISA & Microarchitecture Features
1. **Predicated / Conditional Moves**  
   ```
   CMOV.GT rd, rs, rt    ; rd = (rs > rt) ? rs : rt
   ```
2. **Hardware Stack Instructions**  
   ```
   PUSH rs1, rs2
   POP  rd1, rd2
   ```
3. **Advanced Branch Predictor**  
   - Tournament predictor + loop‑buffer cache  
   - Small BTB for tight loops
4. **Post‑Increment Addressing**  
   ```
   LDI rd, [rs1+], imm   ; rd = Mem[rs1]; rs1 += imm
   ```
5. **Link‑Register Calls**  
   ```
   CALL.R lr, addr
   RET.R  lr
   ```
6. **Prefetching L1 Data Cache**  
   - 16–32 KB with hardware prefetch

---

## 3. AES Encryption

### Profile Highlights
- **Loads:** ~48 % (state & round keys)  
- **Calls & Constants:** ~14 % (S‑box lookups, key schedule)  
- **Bitwise Ops:** ~10–12 % (XOR, shifts, rotates)

### ISA & Microarchitecture Features
1. **Dedicated AES Rounds**  
   ```
   AESENC rd, rs, rk    ; one round
   AESDEC rd, rs, rk    ; inverse round
   ```
2. **Carry‑Less Multiply & Byte‑Shuffle**  
   ```
   CLMUL  rd, rs1, rs2      ; GF(2⁸) mixcolumns
   PSHUFB vd, vs, imm8      ; byte permutation
   ```
3. **128‑Bit SIMD Registers**  
   - Hold full AES state in one register  
   - Micro‑coded key schedule assist opcodes
4. **On‑Chip S‑Box LUT**  
   - 256 × 8 bit single‑cycle RAM  
   - Prefetched round constants in CSR
5. **Fully Unrolled, Pipelined Rounds**  
   - 10 rounds in microcode, no branches  
6. **Security Hardening**  
   - Constant‑time primitives  
   - Mask registers for side‑channel protection

---

## Summary Comparison

| Feature               | Matrix Multiplication        | QuickSort                       | AES Encryption                      |
|-----------------------|------------------------------|---------------------------------|-------------------------------------|
| **Compute Units**     | Wide SIMD + FMA pipelines    | Scalar ALU + predicated ops     | SIMD‑width crypto co‑processor      |
| **Memory Model**      | Scratchpad + strided loads   | Cache + post‑inc addressing     | On‑chip S‑Box LUT + key caches      |
| **Branch Handling**   | Minimal                      | Advanced branch predictor       | Fully unrolled loops (no branches)  |
| **Special Instructions**| PREFETCH; LOOP             | CMOV; PUSH/POP; LDI post‑inc    | AESENC; CLMUL; PSHUFB               |

*End of ISA & Microarchitecture proposals.*
