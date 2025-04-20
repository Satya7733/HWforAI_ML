import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation, PillowWriter

# XOR data
X = np.array([
    [0, 0],
    [0, 1],
    [1, 0],
    [1, 1]
])
T = np.array([[0], [1], [1], [0]])

# Sigmoid functions
def sigmoid(x):
    return 1 / (1 + np.exp(-x))
def sigmoid_derivative(x):
    return x * (1 - x)

# Initialize weights/biases
np.random.seed(42)
W1 = np.random.uniform(-1, 1, (2, 2))
b1 = np.zeros((1, 2))
W2 = np.random.uniform(-1, 1, (2, 1))
b2 = np.zeros((1, 1))

lr = 0.1
epochs = 50000
interval = 1000  # how often to capture boundary
boundaries = []

# Training loop
for epoch in range(epochs):
    # Forward
    h_input = np.dot(X, W1) + b1
    h_output = sigmoid(h_input)

    o_input = np.dot(h_output, W2) + b2
    o_output = sigmoid(o_input)

    # Error and backprop
    error = T - o_output
    d_output = error * sigmoid_derivative(o_output)
    d_hidden = d_output.dot(W2.T) * sigmoid_derivative(h_output)

    # Update weights
    W2 += h_output.T.dot(d_output) * lr
    b2 += np.sum(d_output, axis=0, keepdims=True) * lr
    W1 += X.T.dot(d_hidden) * lr
    b1 += np.sum(d_hidden, axis=0, keepdims=True) * lr

    # Capture decision boundary
    if epoch % interval == 0:
        x_range = np.linspace(-0.2, 1.2, 100)
        y_range = np.linspace(-0.2, 1.2, 100)
        xx, yy = np.meshgrid(x_range, y_range)
        grid = np.c_[xx.ravel(), yy.ravel()]

        h = sigmoid(np.dot(grid, W1) + b1)
        z = sigmoid(np.dot(h, W2) + b2).reshape(xx.shape)
        boundaries.append((xx, yy, z.copy(), epoch))

# === Animation ===
fig, ax = plt.subplots()
plt.title("2-Layer Neural Net Learning XOR")
plt.xlabel("x1")
plt.ylabel("x2")

# Scatter input points
for i in range(len(X)):
    color = 'green' if T[i][0] == 1 else 'red'
    ax.scatter(X[i][0], X[i][1], color=color, s=100, edgecolors='black')

ax.set_xlim(-0.2, 1.2)
ax.set_ylim(-0.2, 1.2)
contour = [None]

def update(frame):
    while ax.collections:
        ax.collections.pop()

    xx, yy, z, epoch = boundaries[frame]
    contour[0] = ax.contourf(xx, yy, z, levels=[0.5, 1.0], alpha=0.3, colors=["blue"])
    ax.set_title(f"Epoch: {epoch}")
    return contour[0].collections

ani = FuncAnimation(fig, update, frames=len(boundaries), interval=500, repeat=False)

# === Save animation ===
save_path = "U:/My Documents/MCECS_Satya/HWforAI/Challenge/Challenge7/xor_2layer_learning.gif"
ani.save(save_path, writer=PillowWriter(fps=2))
print(f"\n✅ XOR 2-layer learning animation saved at: {save_path}")

# === Final Truth Table ===
final_out = sigmoid(np.dot(sigmoid(np.dot(X, W1) + b1), W2) + b2)
predicted = (final_out > 0.5).astype(int)

print("\n✅ XOR Truth Table After Training (2-layer):")
print("----------------------------------")
print(" x1 | x2 | Target | Predicted")
print("----------------------------------")
for i in range(4):
    x1, x2 = X[i]
    t = T[i][0]
    y = predicted[i][0]
    print(f"  {x1}  |  {x2} |    {t}    |     {y}")
print("----------------------------------")
