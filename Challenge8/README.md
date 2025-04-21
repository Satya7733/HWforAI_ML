# XOR Feed‑Forward MLP with Backpropagation

A self‑contained Python implementation of a 2‑2‑1 multi‑layer perceptron trained via backpropagation to solve the XOR problem, with animated visualization of learning dynamics.

---

## 🚀 Features

- **Simple, from‑scratch implementation**  
  No deep‑learning frameworks—only NumPy and Matplotlib.
- **2‑2‑1 network architecture**  
  - 2 input neurons  
  - 2 hidden neurons (sigmoid activation)  
  - 1 output neuron (sigmoid activation)
- **Backpropagation training**  
  - Configurable learning rate  
  - MSE‑style weight updates  
  - Snapshot of weights every 100 epochs
- **Visualization**  
  - Static plot of the network topology  
  - Animated decision surface over the 2D input space  
  - Hidden‑layer “decision lines” drawn as they rotate to carve out XOR
- **Console output**  
  - ASCII‑diagram of all weights & biases before and after training

---

## 📋 Prerequisites

- Python 3.7+  
- [NumPy](https://numpy.org/)  
- [Matplotlib](https://matplotlib.org/)  
- [Pillow](https://python-pillow.org/) (to save GIFs)

Install dependencies with:

```bash
pip install numpy matplotlib pillow
```

---

## 🗂️ Repository Structure

```
.
├── xor_mlp_backprop.py     # Main script
├── xor_training.gif        # Generated animation output
├── README.md               # This file

```

---

## ⚙️ Usage

1. **Run the script**  
   ```bash
   python xor_mlp_backprop.py
   ```
2. **What happens**  
   - A static window pops up showing the 2‑2‑1 network layout.  
   - Console prints initial and final weights/biases.  
   - An animated Matplotlib window shows the decision surface evolving.  
   - A `xor_training.gif` is saved in your working directory.  
3. **View results**  
   - Open `xor_training.gif` in any image viewer.  
   - Inspect printed weight values to see how training shaped the network.

---

## 📝 Script Breakdown

1. **`draw_structure()`**  
   - Renders the network graph: input → hidden → output neurons.  
2. **`print_network()`**  
   - Console‑prints every connection weight and bias in arrow format.  
3. **Data setup**  
   - Defines the four XOR inputs and targets.  
4. **Model initialization**  
   - Random weights and biases in range [–1,1], seeded for reproducibility.  
5. **Training loop**  
   - Forward pass → compute activations.  
   - Backpropagate errors → update weights with learning rate.  
   - Record snapshots every 100 epochs.  
6. **Visualization grid**  
   - Builds a fine mesh over [–0.1,1.1]² to color‑map network outputs.  
7. **Animation**  
   - Uses Matplotlib’s `FuncAnimation` to animate snapshots.  
   - Shows how hidden‑layer decision lines swivel over training.  
8. **Output**  
   - Saves `xor_training.gif` via `PillowWriter`.  
   - Pops up final animation plot with `plt.show()`.

---

## 🧠 Network Architecture

```
  x0─────┐
         ├─→ h0 ─→
  x1─────┘        \
                   → y
  x0─────┐        /
         ├─→ h1 ─→
  x1─────┘
```

- Hidden neurons use sigmoid activation to carve non‑linear boundaries.  
- Output neuron uses sigmoid to produce a continuous [0,1] output.

---

## 🔧 Configuration

Within the script you can adjust:

- **`lr`** (learning rate)  
- **`epochs`** (total training iterations)  
- **Snapshot frequency** (currently every 100 epochs)  
- **Mesh resolution** (grid size for decision surface)

---

## 🤝 Contributing

Feel free to:

- Add support for different activation functions  
- Experiment with more hidden neurons or deeper networks  
- Export to MP4 or interactive HTML  

Pull requests and issues are welcome!

---

## 📄 License

This project is released under the [MIT License](LICENSE).

---

*Happy learning!*

