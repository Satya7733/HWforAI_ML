import pyrtl

# ── PORTS ─────────────────────────────────────────────────────────────────────
q_sa    = pyrtl.Input(32, 'q_sa')     # Q[s,a]
q_s2max = pyrtl.Input(32, 'q_s2max')  # max_a' Q[s',a']
reward  = pyrtl.Input(32, 'reward')   # r
gamma   = pyrtl.Input(32, 'gamma')    # γ (fixed-point)
alpha   = pyrtl.Input(32, 'alpha')    # α (fixed-point)

# ── DATAPATH ──────────────────────────────────────────────────────────────────
gam_mul = gamma * q_s2max             # γ · maxQ[s′]
target  = reward + gam_mul            # r + γ·maxQ[s′]
delta   = target - q_sa               # (…)-Q[s,a]
scaled  = alpha * delta               # α·Δ
q_new   = q_sa + scaled               # Q[s,a] ← Q[s,a] + α·Δ

# ── OUTPUT ────────────────────────────────────────────────────────────────────
q_out = pyrtl.Output(32, 'q_out')
q_out <<= q_new

# ── (Optional) PIPELINE ───────────────────────────────────────────────────────
# q_reg = pyrtl.Register(32, 'Q_reg')
# q_reg.next <<= q_new

# ── EXPORT TO VERILOG ─────────────────────────────────────────────────────────
from pyrtl import output_to_verilog
with open('q_update.v', 'w') as f:
    # add_reset=False is a valid option; avoids the PyrtlError you saw
    output_to_verilog(f, add_reset=False)
