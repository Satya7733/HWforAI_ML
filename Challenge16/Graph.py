import csv
import re
import numpy as np
import matplotlib.pyplot as plt

# 1) Load & normalize custom‐CUDA timings
cuda_times = {}
with open("cuda_times.csv", newline="") as f:
    reader = csv.reader(f)
    for raw_arch, ms in reader:
        raw_arch = raw_arch.strip()
        # Normalize IN4_H5_OUT1 → IN4_5_O1
        m = re.match(r"IN(\d+)_H(\d+)_OUT(\d+)", raw_arch)
        if m:
            arch = f"IN{m.group(1)}_{m.group(2)}_O{m.group(3)}"
        else:
            arch = raw_arch
        cuda_times[arch] = float(ms)

# 2) Load PyTorch timings
pt_cpu = {}
pt_gpu = {}
with open("pytorch_times.csv", newline="") as f:
    reader = csv.reader(f)
    for arch, cpu_ms, gpu_ms in reader:
        arch = arch.strip()
        pt_cpu[arch] = float(cpu_ms)
        pt_gpu[arch] = float(gpu_ms)

# 3) Intersection of architectures
common = sorted(set(cuda_times) & set(pt_cpu))
if not common:
    raise RuntimeError("Still no matching architectures after normalization!")

# 4) Plot combined bar chart
x = np.arange(len(common))
cuda_v = [cuda_times[a] for a in common]
cpu_v  = [pt_cpu   [a] for a in common]
gpu_v  = [pt_gpu   [a] for a in common]

fig, ax = plt.subplots(figsize=(10,6))
width = 0.25
ax.bar(x - width, cuda_v,  width, label='Custom CUDA (GPU)')
ax.bar(x,          gpu_v,  width, label='PyTorch (GPU)')
ax.bar(x + width,  cpu_v,  width, label='PyTorch (CPU)')

# Annotate
for idx, arch in enumerate(common):
    for offset, val in zip([-width, 0, width], [cuda_v[idx], gpu_v[idx], cpu_v[idx]]):
        ax.text(idx + offset, val + max(cpu_v+gpu_v+cuda_v)*0.02,
                f"{val:.3f} ms", ha='center', va='bottom', fontsize=9)

ax.set_xticks(x)
ax.set_xticklabels(common, rotation=45, ha='right')
ax.set_xlabel("Network architecture (IN4 → … → O1)")
ax.set_ylabel("Forward-pass time (ms per 1000 iters)")
ax.set_title("Custom CUDA vs PyTorch: Forward-pass Performance")
ax.legend()
ax.grid(True, linestyle='--', alpha=0.4)
plt.tight_layout()
plt.show()
