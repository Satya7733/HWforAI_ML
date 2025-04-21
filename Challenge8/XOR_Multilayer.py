import numpy as np
import matplotlib.pyplot as plt
from matplotlib.patches import Circle
from matplotlib.animation import FuncAnimation, PillowWriter

# --- 0) Draw the network topology ---
def draw_structure():
    positions = {
        'x0': (0, 0.75),
        'x1': (0, 0.25),
        'h0': (1, 0.75),
        'h1': (1, 0.25),
        'y':  (2, 0.5)
    }
    connections = [
        ('x0', 'h0'), ('x0', 'h1'),
        ('x1', 'h0'), ('x1', 'h1'),
        ('h0', 'y'),  ('h1', 'y')
    ]

    fig, ax = plt.subplots(figsize=(6, 3))
    # Draw nodes
    for label, (x, y) in positions.items():
        circ = Circle((x, y), 0.1, fill=False, linewidth=2)
        ax.add_patch(circ)
        ax.text(x, y, label, ha='center', va='center', fontsize=12)
    # Draw arrows
    for src, tgt in connections:
        x0, y0 = positions[src]
        x1, y1 = positions[tgt]
        ax.annotate('', xy=(x1, y1), xytext=(x0, y0),
                    arrowprops=dict(arrowstyle='->', lw=1.5))
    ax.axis('equal')
    ax.axis('off')
    ax.set_title("2-2-1 Feed-Forward Perceptron Structure")
    plt.show()

# Call it right away
draw_structure()


# --- 1) Helper: print the network structure & parameters ---
def print_network(W1, b1, W2, b2, label=""):
    print(f"\n=== {label} network parameters ===")
    print(" Input → Hidden layer")
    for i in range(W1.shape[0]):
        for j in range(W1.shape[1]):
            print(f"   x{i} -- W1[{i},{j}] = {W1[i,j]:.4f} --> h{j}")
    for j in range(b1.shape[1]):
        print(f"   bias b1[{j}] (for h{j}) = {b1[0,j]:.4f}")
    print(" Hidden → Output layer")
    for i in range(W2.shape[0]):
        print(f"   h{i} -- W2[{i},0]  = {W2[i,0]:.4f} --> y")
    print(f"   bias b2[0] (for y) = {b2[0,0]:.4f}")
    print("=" * 30)

# --- 2) Activation functions ---
def sigmoid(x):
    return 1 / (1 + np.exp(-x))

def sigmoid_derivative(x):
    return x * (1 - x)

# --- 3) XOR dataset ---
X = np.array([[0,0],
              [0,1],
              [1,0],
              [1,1]])
y = np.array([[0],[1],[1],[0]])

# --- 4) Hyperparameters & initialization ---
lr     = 0.5
epochs = 5000
np.random.seed(42)

W1 = np.random.uniform(-1, 1, (2, 2))   # input → hidden weights
b1 = np.random.uniform(-1, 1, (1, 2))   # hidden biases
W2 = np.random.uniform(-1, 1, (2, 1))   # hidden → output weights
b2 = np.random.uniform(-1, 1, (1, 1))   # output bias

# Print initial weights
print_network(W1, b1, W2, b2, label="Initial")

# --- 5) Training loop (backpropagation) ---
history = []
for epoch in range(epochs + 1):
    # Forward pass
    h_in     = X.dot(W1) + b1
    h_out    = sigmoid(h_in)
    o_in     = h_out.dot(W2) + b2
    output   = sigmoid(o_in)
    # Compute deltas
    o_error  = y - output
    o_delta  = o_error * sigmoid_derivative(output)
    h_error  = o_delta.dot(W2.T)
    h_delta  = h_error * sigmoid_derivative(h_out)
    # Update weights / biases
    W2 += lr * h_out.T.dot(o_delta)
    b2 += lr * o_delta.sum(axis=0, keepdims=True)
    W1 += lr * X.T.dot(h_delta)
    b1 += lr * h_delta.sum(axis=0, keepdims=True)
    # Snapshot every 100 epochs
    if epoch % 100 == 0:
        history.append((W1.copy(), b1.copy(), W2.copy(), b2.copy(), epoch))

# Print trained weights
print_network(W1, b1, W2, b2, label="Trained")

# --- 6) Prepare grid for decision surface visualization ---
grid_x = np.linspace(-0.1, 1.1, 200)
grid_y = np.linspace(-0.1, 1.1, 200)
xx, yy = np.meshgrid(grid_x, grid_y)
grid   = np.c_[xx.ravel(), yy.ravel()]

# --- 7) Animation setup ---
fig, ax = plt.subplots()
def update(frame):
    ax.clear()
    W1_snap, b1_snap, W2_snap, b2_snap, epoch = history[frame]
    # Decision surface
    h = sigmoid(grid.dot(W1_snap) + b1_snap)
    o = sigmoid(h.dot(W2_snap) + b2_snap)
    Z = o.reshape(xx.shape)
    ax.pcolormesh(xx, yy, Z, shading='auto')
    # Plot XOR points
    for xi, yi, tgt in zip(X[:,0], X[:,1], y.ravel()):
        ax.scatter(xi, yi, marker='o' if tgt else 'X', s=100, edgecolor='k')
    # Hidden-layer decision lines
    x_vals = np.array([ax.get_xlim()[0], ax.get_xlim()[1]])
    for i in range(2):
        w1, w2 = W1_snap[:, i]
        b      = b1_snap[0, i]
        if abs(w2) > 1e-3:
            y_vals = -(w1 * x_vals + b) / w2
            ax.plot(x_vals, y_vals, '--', linewidth=2)
    ax.set_title(f'Epoch: {epoch}')
    ax.set_xlim(-0.1, 1.1)
    ax.set_ylim(-0.1, 1.1)

anim = FuncAnimation(fig, update, frames=len(history), interval=200)

# --- 8) Save & show ---
anim.save('xor_training.gif', writer=PillowWriter(fps=5))
print("\n🎉 Animation saved as xor_training.gif")
plt.show()
