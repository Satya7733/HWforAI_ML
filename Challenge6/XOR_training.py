import numpy as np
import matplotlib.pyplot as plt

# XOR inputs and expected outputs
X = np.array([
    [0, 0],
    [0, 1],
    [1, 0],
    [1, 1]
])
T = np.array([[0], [1], [1], [0]])

# Sigmoid function and its derivative
def sigmoid(x):
    return 1 / (1 + np.exp(-x))
def sigmoid_derivative(x):
    return x * (1 - x)

# Set random seed for reproducibility
np.random.seed(42)

# === Modified: Use uniform initialization instead of normal ===
W1 = np.random.uniform(-1, 1, (2, 2))  # input → hidden
b1 = np.zeros((1, 2))

W2 = np.random.uniform(-1, 1, (2, 1))  # hidden → output
b2 = np.zeros((1, 1))

lr = 0.1  # learning rate
losses = []

# === Modified: Increased number of epochs to 50,000 ===
for epoch in range(50000):
    # Forward pass
    hidden_input = np.dot(X, W1) + b1
    hidden_output = sigmoid(hidden_input)

    final_input = np.dot(hidden_output, W2) + b2
    final_output = sigmoid(final_input)

    # Compute loss (MSE)
    error = T - final_output
    loss = np.mean(error**2)
    losses.append(loss)

    # Backward pass
    d_output = error * sigmoid_derivative(final_output)
    d_hidden = d_output.dot(W2.T) * sigmoid_derivative(hidden_output)

    # Update weights and biases
    W2 += hidden_output.T.dot(d_output) * lr
    b2 += np.sum(d_output, axis=0, keepdims=True) * lr
    W1 += X.T.dot(d_hidden) * lr
    b1 += np.sum(d_hidden, axis=0, keepdims=True) * lr

    # Optional loss print
    if epoch % 5000 == 0:
        print(f"Epoch {epoch} - Loss: {loss:.6f}")

# Plot loss curve
plt.plot(losses)
plt.title("Loss Curve During Training")
plt.xlabel("Epoch")
plt.ylabel("Mean Squared Error")
plt.grid(True)
plt.show()

# === Modified: Apply threshold to convert to binary output (0 or 1) ===
predicted = (final_output > 0.5).astype(int)

# Final result
print("\nXOR Results After Training:")
for i in range(4):
    x1, x2 = X[i]
    print(f"{x1} XOR {x2} = {predicted[i][0]}")
