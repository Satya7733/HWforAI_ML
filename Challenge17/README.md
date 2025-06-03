Here is a `README.md` you can use for Challenge #17:

```markdown
# Challenge #17: Sorting on a Systolic Array

## Objective

The goal of this challenge is to:

- Understand how **Bubble Sort** can be implemented using a **systolic array** architecture.
- Evaluate the **execution time performance** of Bubble Sort for different problem sizes in software.
- Compare and reason about the scalability and hardware acceleration potential of systolic arrays versus conventional CPU-based sorting.

---

## Tasks

### 1. Design a Systolic Array for Bubble Sort

A systolic array for Bubble Sort can be implemented as a **1×N linear array** of **Processing Elements (PEs)**, each holding one value. These PEs perform **compare-and-swap** operations with their neighbors in a lockstep manner. 

- **Phase 1**: Odd-indexed pairs perform compare-and-swap.
- **Phase 2**: Even-indexed pairs do the same.
- Repeat these alternating phases for `N - 1` times to sort `N` values.

This hardware-based approach allows multiple comparisons to occur in parallel, significantly reducing the overall sorting time.

---

### 2. Software Implementation and Testing

We implemented a basic **Bubble Sort** algorithm in Python and tested it on input sizes:

```

\[10, 100, 1000, 2000, 5000, 10000]

```

Execution times (in seconds) were recorded:

| Input Size | Time (s)    |
|------------|-------------|
| 10         | 0.000009    |
| 100        | 0.000386    |
| 1000       | 0.051187    |
| 2000       | 0.198570    |
| 5000       | 1.218462    |
| 10000      | 5.129063    |

A performance graph is included below:

![Bubble Sort Execution Time](Graph.png)

---

### 3. Conclusion

- The CPU-based Bubble Sort shows clear **O(N²)** time complexity, as evidenced by the execution times.
- This makes the software version unsuitable for large input sizes (N > 5000 becomes slow).
- Mapping Bubble Sort to a systolic array enables **parallelism** across compare-and-swap units, reducing the complexity to approximately **O(N)** in terms of clock cycles.
- This demonstrates the performance benefit and scalability of hardware-accelerated sorting using systolic arrays.

---

## Files

- `BubbleSort_SysArr.py` – Python script for bubble sort and timing
- `Graph.png` – Graph showing execution time vs. input size
- `README.md` – This file summarizing the challenge
```

Let me know if you want to include any code snippets or hardware diagrams directly into the README.
