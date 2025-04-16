# NAND Truth Table
training_data = [
    {"inputs": [0, 0], "target": 1},
    {"inputs": [0, 1], "target": 1},
    {"inputs": [1, 0], "target": 1},
    {"inputs": [1, 1], "target": 0},
]

# Initialize weights and bias
w = [0, 0]   # w1, w2
b = 0        # bias
learning_rate = 1

# Activation function (Step function)
def activation(x):
    return 1 if x >= 0 else 0

# Train until all outputs match target
for epoch in range(10):  # limit epochs to avoid infinite loop
    print(f"Epoch {epoch + 1}")
    error_count = 0

    for data in training_data:
        x1, x2 = data["inputs"]
        target = data["target"]

        # Compute output
        total = w[0]*x1 + w[1]*x2 + b
        output = activation(total)

        # Calculate error
        error = target - output

        # Update weights and bias if there's an error
        if error != 0:
            w[0] += learning_rate * error * x1
            w[1] += learning_rate * error * x2
            b += learning_rate * error
            error_count += 1

        print(f"Input: {x1, x2}, Target: {target}, Output: {output}, Weights: {w}, Bias: {b}")

    if error_count == 0:
        print("\nTraining complete!\n")
        break

# Final Test
print("Final weights and bias:")
print(f"w1 = {w[0]}, w2 = {w[1]}, bias = {b}")

print("\nTesting NAND function:")
for data in training_data:
    x1, x2 = data["inputs"]
    total = w[0]*x1 + w[1]*x2 + b
    output = activation(total)
    print(f"{x1} NAND {x2} = {output}")
