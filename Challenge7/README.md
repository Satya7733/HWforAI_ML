# 🧠 Challenge 7 – Visualizing the Perceptron Learning Process

## 📝 Challenge Summary

This challenge focuses on **visualizing how a perceptron learns to classify binary logic** using the perceptron learning rule. The main goal is to animate how the decision boundary evolves as the neuron updates its weights during training.

---

## 🔍 Problem Statement

1. **Visualize the learning process** in a 2D plane by representing the neuron’s “line” that separates the input space.
2. **Create an animated visualization** that illustrates every step of the weight-updating process using the perceptron rule.

---

## ✅ Key Learnings

### 1. **Perceptron Training on NAND Logic**

* Implemented a perceptron (single neuron) with a step activation function.
* Trained it using the NAND truth table:

  ```
  Inputs: (0,0), (0,1), (1,0), (1,1)  
  Targets: [1, 1, 1, 0]
  ```
* During training, we stored all weight and bias updates at every step for visualization.

### 2. **Visualization & Animation**

* Used `matplotlib.animation.FuncAnimation` to animate the evolution of the decision boundary (line) in 2D space.
* Color-coded the input points (green for 1, red for 0).
* Over time, the boundary visibly adjusts to separate the NAND outputs correctly.

### 3. **XOR Learning with 2-Layer Neural Network**

* Extended the task to include a **2-layer neural network** (2 inputs → 2 hidden → 1 output) to solve XOR.
* Used sigmoid activation and backpropagation for training.
* Captured the decision boundary over epochs and animated its transformation from an untrained state to a non-linear separation.

---

## 🎥 Outputs

* `nand_learning.gif`: Animation showing the perceptron learning to classify NAND logic.
* `xor_2layer_learning.gif`: Animation showing a neural network learning to classify XOR logic with a curved decision boundary.

---

## 📆 Files Included

* `Challenge7/nand_learning.gif` – Perceptron learning visualization (NAND)
* `Challenge7/xor_2layer_learning.gif` – 2-layer neural net learning (XOR)
* `nand_perceptron.py` – Code for training + animating NAND perceptron
* `xor_mlp.py` – Code for training + animating 2-layer XOR network

---

## 📚 Conclusion

This challenge demonstrated how neural networks **visually evolve** as they learn. We observed:

* Linear decision boundaries for linearly separable logic (NAND)
* Curved boundaries for non-linear functions (XOR)

By animating each step, we gained valuable intuition into how weights update and how decision boundaries shift to classify input patterns.
