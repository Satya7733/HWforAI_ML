import numpy as np
import matplotlib.pyplot as plt
from matplotlib.animation import FuncAnimation, PillowWriter

# NAND dataset
X = np.array([
    [0, 0],
    [0, 1],
    [1, 0],
    [1, 1]
])
T = np.array([1, 1, 1, 0])

# Initialize weights, bias, learning rate
w = np.array([0.0, 0.0])
b = 0.0
lr = 1.0

states = []

def activation(x):
    return 1 if x >= 0 else 0

# Training function
def train_perceptron():
    global w, b
    for epoch in range(10):
        updated = False
        for i in range(len(X)):
            x = X[i]
            t = T[i]
            y = activation(np.dot(w, x) + b)
            error = t - y

            states.append((w.copy(), b))

            if error != 0:
                w += lr * error * x
                b += lr * error
                updated = True

        if not updated:
            break

    states.append((w.copy(), b))

    print("\n🔍 Final Trained Weights:")
    print(f"w1 = {w[0]:.2f}, w2 = {w[1]:.2f}, bias = {b:.2f}\n")
    print("✅ NAND Truth Table After Training:")
    print("----------------------------------")
    print(" x1 | x2 | Target | Predicted")
    print("----------------------------------")
    for i in range(len(X)):
        x1, x2 = X[i]
        target = T[i]
        y = activation(np.dot(w, X[i]) + b)
        print(f"  {x1}  |  {x2} |    {target}    |     {y}")
    print("----------------------------------")

# Plot setup
fig, ax = plt.subplots()
plt.title("Perceptron Learning NAND Logic")
plt.xlabel("x1")
plt.ylabel("x2")

for i in range(len(X)):
    color = 'green' if T[i] == 1 else 'red'
    ax.scatter(X[i][0], X[i][1], color=color, s=100, edgecolors='black')

ax.set_xlim(-0.5, 1.5)
ax.set_ylim(-0.5, 1.5)
line, = ax.plot([], [], 'b--', linewidth=2)

def update(frame):
    weights, bias = states[frame]
    if weights[1] != 0:
        x_vals = np.array([-1, 2])
        y_vals = -(weights[0] * x_vals + bias) / weights[1]
    else:
        x_vals = np.array([bias / weights[0]] * 2)
        y_vals = np.array([-1, 2])

    line.set_data(x_vals, y_vals)
    ax.set_title(f"Step {frame + 1} - w: {weights.round(2)}, b: {round(bias, 2)}")
    return line,

# Train and animate
train_perceptron()
ani = FuncAnimation(fig, update, frames=len(states), interval=1000, repeat=False)

# === Save as GIF ===
ani.save("Challenge7/nand_learning.gif", writer=PillowWriter(fps=1))
print("\n✅ Animation saved as 'nand_learning.gif'!")

# Show animation (optional, can comment out if saving only)
plt.show()
