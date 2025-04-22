# FrozenLake Q-Learning: GPU vs CPU Performance Comparison

## GPU Results (CuPy, 10,000 episodes)
```
[GPU Timing Summary for 10000 episodes]
Total Q-value update time:    25.2915 seconds
Total action selection time:  14.5561 seconds

Final Value Table:
 -4.74 |  -4.15 |  -3.50 |  -2.78 |  -1.98 |
  0.00 |  -3.50 |  -2.78 |   0.00 |  -1.09 |
 -3.50 |  -2.78 |  -1.98 |  -1.09 |  -0.10 |
 -4.13 |   0.00 |  -1.09 |  -0.10 |   1.00 |
 -4.01 |  -3.87 |   0.00 |   1.00 |   0.00 |
```

## CPU Results (Original, 10,000 episodes)
```
[Timing Summary for 10000 episodes]
Total Q-value computation time: 0.2583 seconds
Total action selection time:    0.3385 seconds
Total Q assignment time:        0.1002 seconds
-----------------------------------------------
| -5.262 | -4.736 | -4.152 | -3.505 | -2.784 |
-----------------------------------------------
| -5     | -4.152 | -3.503 | -5     | -1.982 |
-----------------------------------------------
| -4.143 | -3.503 | -2.782 | -1.98  | -1.091 |
-----------------------------------------------
| -3.954 | -5     | -1.98  | -1.089 | -0.1   |
-----------------------------------------------
| -3.575 | -3.698 | -5     | -0.099 | 1      |
-----------------------------------------------
```

## Why GPU is Slower Here
- **Tiny workload.** A 5×5 grid (25 states × 4 actions) doesn’t provide enough data for a GPU’s parallel cores.
- **High overhead.** Kernel launches, JIT-compilation, and host–device synchronization dominate runtime.
- **Sequential control flow.** Episode loops and state resets still run on the CPU, limiting GPU acceleration.

## When GPU Shines
- **Much larger MDPs** (e.g. 100×100 grids).
- **Massively parallel environments** (thousands of FrozenLake instances running concurrently).
- **Deep RL** (e.g. DQN, policy gradients) with large tensor operations.

## Recommendations
1. **Use CPU (or Numba-JIT)** for small toy MDPs—simpler setup and ~60× faster.
2. **Scale up the workload** (larger state/action spaces or batch size) to amortize GPU overhead.
3. **Transition to deep RL frameworks** (PyTorch, JAX) for true GPU utilization with large matrix operations.

