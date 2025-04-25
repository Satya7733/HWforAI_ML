# FrozenLake Q‑Learning HW Acceleration Challenge

This repository captures the work done to meet the challenge requirements:

1. **Benchmark & Profile**

   - Implemented a Python Q‑learning + Dyna‑Q agent for a 15×15 FrozenLake (deterministic) grid.
   - Instrumented timers around:
     - **Q-update** (single multiply‑accumulate)
     - **Planning updates** (Dyna‑Q inner loop)
     - **Overall runtime** including environment steps and loop overhead.
   - Generated profiling results showing:
  - **Q-update: 7.2021 s (2.00%)**
  - **Planning: 136.1239 s (37.88%)**
  - **Overhead (env.step, Python loop, logging): 216.0070 s (60.11%)**
- Achieved 100% success rate over 200 evaluation episodes.

2. **Hardware Acceleration Decision**

   - The **multiply‑accumulate (MAC) kernel** in both Q‑update and planning dominates runtime (\~40%).
   - By offloading this MAC into hardware, we expect an overall speedup of **\~1.66×** (Amdahl’s Law).

3. **Back‑of‑the‑Envelope Analysis**

   - Software: 5 M MAC operations × \~10 ns each → \~50 ms in hardware vs. tens of seconds in Python.
   - Conclusion: HW MAC is worth the effort for significant performance gains.

4. **HDL Prototype (PyRTL)**

   - Chose **PyRTL** for rapid RTL prototyping in Python.
   - Implemented the Q‑update formula as a small combinational datapath:
     ```verilog
     module q_update (
       input  [31:0] q_sa,
       input  [31:0] q_s2max,
       input  [31:0] reward,
       input  [31:0] gamma,
       input  [31:0] alpha,
       output [31:0] q_out
     );
       assign q_out = q_sa + alpha * (reward + gamma * q_s2max - q_sa);
     endmodule
     ```
   - Exported from PyRTL to `q_update.v` with `output_to_verilog(..., add_reset=False)`.

5. **Functional Verification**

   - Developed a **cocotb** testbench (`tb_HW_Qvalue.py`) to verify the MAC unit against a Python reference model.
   - Configured a pytest-cocotb workflow with `pytest.ini` and `conftest.py` to auto-generate RTL and run tests.

6. **Next Steps**

   - Integrate the MAC unit into a larger top‑level design with:
     - Q‑table memory interface (e.g., BRAM or AXI‐Lite).
     - Control FSM to sequence state/action indices.
     - DMA or AXI‐DMA for host↔FPGA data transfers.
   - Implement and test on target FPGA board via chosen protocol (PCIe / Ethernet / AXI).
   - Explore further acceleration of environment simulation or batch updates using hardware offload.



