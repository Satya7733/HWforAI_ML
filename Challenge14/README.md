# Challenge #14: Fibonacci Sequence Kernel Benchmark
[CUDA Fibonacci Benchmark Colab](https://colab.research.google.com/drive/1xqG3hsUMq9I3cxRZ7f09QxCo7PR7w8mo?usp=sharing)

## Problem Statement

Compute the first N Fibonacci numbers (e.g., N = 2^25) in two ways:

1. **CUDA Implementation:** A GPU kernel where each thread calculates one Fibonacci term by iterating from F(0), F(1) up to F(idx).
2. **Sequential CPU Implementation:** A simple loop that computes F(n) = F(n-1) + F(n-2) in O(N) time.

Then compare both implementations in terms of correctness and performance, and produce a comparative plot.

## What We Did

1. **CUDA Kernel & Profiling (********`fib_profile.cu`********\*\*\*\*\*\*\*\*)**

   - Wrote a `__global__ fib_kernel` that assigns one thread per index `idx` to compute F(idx) via an iterative loop.
   - Allocated device and host buffers, used CUDA events to time “kernel-only” and “end-to-end” (including D2H copy).
   - Printed the first 10 values and the final term F(N-1) for verification.

2. **CPU Sequential Implementation (********`fib_seq.cpp`********\*\*\*\*\*\*\*\*)**

   - Used a `std::vector` and a single loop to fill the Fibonacci sequence in O(N).
   - Measured execution time using `std::chrono::high_resolution_clock`.
   - Printed the first 10 values and the final term F(N-1).

3. **Python Comparison & Plotting (********`compare_fib.py`********\*\*\*\*\*\*\*\*)**

   - Ran both executables and captured their outputs (`cpu_output.txt`, `gpu_output.txt`).
   - Parsed timings and final values, asserted correctness match.
   - Generated a bar chart comparing CPU time, GPU kernel-only time, and GPU end-to-end time.

4. **Colab Workflow**

   - Provided three notebook cells:\
     a. `%%writefile` cell to create the source files.\
     b. `%%bash` cell to compile (`nvcc`, `g++`) and run, redirecting outputs.\
     c. Python cell to execute `compare_fib.py`, display verification, and render the plot inline.

## How to Reproduce

Open the Colab notebook linked here: [Your CUDA Fibonacci Benchmark Colab](https://colab.research.google.com/drive/1xqG3hsUMq9I3cxRZ7f09QxCo7PR7w8mo?usp=sharing)


## Files in This Repo

- `fib_profile.cu` — CUDA kernel with profiling and final result output.
- `fib_seq.cpp` — CPU-only Fibonacci sequence generator with timing.
- `compare_fib.py` — Python script to run, verify, and plot performance comparison.
- `cpu_output.txt`, `gpu_output.txt` — Captured run logs.
- `fib_compare.png` — Final plot comparing execution times.

## Performance Plot

![Fibonacci Performance Comparison]\(Plot.png)

*Figure: Execution time (ms) for CPU sequential, GPU end-to-end, and GPU kernel-only for N = 2^25.*

## Summary Points

- **Correctness Verified:** Both implementations produce the same final Fibonacci term.
- **Algorithmic Cost:** CPU loop runs in O(N), whereas the naive GPU threads do O(N²) total work due to per-thread iteration.
- **Overhead Impact:** GPU end-to-end time includes device→host transfer (\~256 MB), inflating total runtime.
- **Timer Isolation:** Kernel-only timings isolate device compute but still suffer from redundant work.
- **Parallel Suitability:** Achieving GPU speedup for Fibonacci requires an inherently parallel algorithm (e.g., fast-doubling or parallel prefix) rather than independent per-index recomputation.




**DHANYAWAD**

