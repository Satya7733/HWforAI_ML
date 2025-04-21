# Challenge: Perceptron with Sigmoid Activation to Learn NAND and XOR

This project explores how to implement and train a **simple neuron (a.k.a. perceptron)** with **two inputs** and a **sigmoid activation function** using the **perceptron learning rule** to learn basic binary logic functions.

---

## 🧠 Objective

> ✅ Implement a perceptron with sigmoid activation  
> ✅ Use the perceptron learning rule to train the neuron to learn:
- `a.` **NAND**
- `b.` **XOR**

---

## 🧩 What is a Perceptron?

A perceptron is the simplest type of neural network — a **single neuron** that computes a weighted sum of inputs and passes it through an **activation function**.

In this challenge, we use the **sigmoid function**:
\[
\sigma(x) = \frac{1}{1 + e^{-x}}
\]

And its derivative (for gradient updates):
\[
\sigma'(x) = \sigma(x)(1 - \sigma(x))
\]

📚 Reference:  
[Machine Learning Mastery – Sigmoid Function](https://machinelearningmastery.com/a-gentle-introduction-to-sigmoid-function/)

---

## 🚀 Tasks Performed

### ✅ 1. Implemented Sigmoid Neuron
- Created a Python function for sigmoid and its derivative
- Initialized weights, bias, and learning rate

---

### ✅ 2. Trained on **NAND** Using Perceptron Rule
- Used the sigmoid neuron to approximate **NAND**
- Applied **perceptron learning rule**:
  \[
  w = w + \eta \cdot (target - output) \cdot input
  \]
- Training converged successfully
- Evaluated the learned weights and outputs

---

### ✅ 3. Trained on **XOR** Using Perceptron Rule
- Used the same sigmoid neuron setup to try learning **XOR**
- Observed that training **does not converge**, proving XOR is **not linearly separable**
- This leads to the motivation of needing **multi-layer neural networks**
- **Implemented Multiple layer neural network**
---

## 📊 Results Summary

### NAND Truth Table (after training):
| x1 | x2 | Target | Output |
|----|----|--------|--------|
| 0  | 0  |   1    |  ≈ 1   |
| 0  | 1  |   1    |  ≈ 1   |
| 1  | 0  |   1    |  ≈ 1   |
| 1  | 1  |   0    |  ≈ 0   |

---

### XOR Truth Table (single-layer perceptron fails):
| x1 | x2 | Target | Output |
|----|----|--------|--------|
| 0  | 0  |   0    |  ?     |
| 0  | 1  |   1    |  ~0.5  |
| 1  | 0  |   1    |  ~0.5  |
| 1  | 1  |   0    |  ?     |

✅ Output does not match target → shows why we need multiple layers for XOR.

---

## 📦 Files Included

| File                  | Description                                      |
|-----------------------|--------------------------------------------------|
| `sigmoid_neuron.py`   | Contains code for training sigmoid neuron        |
| `nand_output.png`     | Graph or log of NAND training output (optional)  |
| `xor_output.png`      | Graph showing failed convergence for XOR         |

---

## 💡 Key Takeaways

- A **single-layer sigmoid neuron** can learn linearly separable functions like **NAND**
- It **fails on XOR** due to its non-linear separability
- This exercise builds foundational understanding for deeper neural networks

---

## 🔧 Requirements

```bash
py -3 -m pip install numpy matplotlib
