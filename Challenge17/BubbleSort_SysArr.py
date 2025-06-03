import time
import random
import pandas as pd
import matplotlib.pyplot as plt

def bubble_sort(arr):
    n = len(arr)
    for i in range(n):
        for j in range(0, n - i - 1):
            if arr[j] > arr[j + 1]:
                arr[j], arr[j + 1] = arr[j + 1], arr[j]

sizes = [10, 100, 1000, 2000,5000, 10000]
execution_times = []

for size in sizes:
    data = [random.randint(0, size) for _ in range(size)]
    start = time.time()
    bubble_sort(data)
    end = time.time()
    execution_times.append(end - start)

# Create and print a simple table
df = pd.DataFrame({
    "Input Size": sizes,
    "Time (s)": execution_times
})
print(df.to_string(index=False))

# Plotting
plt.figure(figsize=(8,5))
plt.plot(sizes, execution_times, marker='o')
plt.title("Bubble Sort: Execution Time vs. Input Size")
plt.xlabel("Input Size (N)")
plt.ylabel("Execution Time (s)")
plt.grid(True)
plt.show()
