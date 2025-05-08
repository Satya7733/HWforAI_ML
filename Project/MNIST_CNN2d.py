import numpy as np
import matplotlib.pyplot as plt

def relu(x):
    return np.maximum(0, x)

def softmax(x):
    exp_x = np.exp(x - np.max(x, axis=-1, keepdims=True))
    return exp_x / np.sum(exp_x, axis=-1, keepdims=True)

# Simple convolution operation
def conv2d(x, filters, bias, stride=1):
    n_filters, d_filter, h_filter, w_filter = filters.shape
    n_x, d_x, h_x, w_x = x.shape

    h_out = (h_x - h_filter) // stride + 1
    w_out = (w_x - w_filter) // stride + 1

    output = np.zeros((n_x, n_filters, h_out, w_out))

    for i in range(n_x):
        for f in range(n_filters):
            for h in range(0, h_out):
                for w in range(0, w_out):
                    h_start = h * stride
                    w_start = w * stride
                    output[i, f, h, w] = np.sum(
                        x[i, :, h_start:h_start+h_filter, w_start:w_start+w_filter] * filters[f]) + bias[f]
    return output

# Simple max pooling operation
def maxpool2d(x, size=2, stride=2):
    n_x, d_x, h_x, w_x = x.shape
    h_out = (h_x - size) // stride + 1
    w_out = (w_x - size) // stride + 1

    output = np.zeros((n_x, d_x, h_out, w_out))

    for i in range(n_x):
        for d in range(d_x):
            for h in range(h_out):
                for w in range(w_out):
                    h_start = h * stride
                    w_start = w * stride
                    output[i, d, h, w] = np.max(x[i, d, h_start:h_start+size, w_start:w_start+size])
    return output

# Fully connected layer
def fc(x, weights, bias):
    return np.dot(x, weights) + bias

# Example inference on a pretrained dummy model (weights randomly initialized for demo purposes)
def cnn_digit_recognition(img):
    # Assuming input image of shape [28,28]
    x = img.reshape(1, 1, 28, 28)

    # Conv layer 1
    filters1 = np.random.randn(8, 1, 3, 3)
    bias1 = np.random.randn(8)
    x = relu(conv2d(x, filters1, bias1))

    # Max pooling
    x = maxpool2d(x, 2, 2)

    # Conv layer 2
    filters2 = np.random.randn(16, 8, 3, 3)
    bias2 = np.random.randn(16)
    x = relu(conv2d(x, filters2, bias2))

    # Max pooling
    x = maxpool2d(x, 2, 2)

    # Flatten
    x = x.reshape(1, -1)

    # Fully connected layer
    fc_weights = np.random.randn(x.shape[1], 10)
    fc_bias = np.random.randn(10)
    x = fc(x, fc_weights, fc_bias)

    # Softmax to get probabilities
    probs = softmax(x)
    return np.argmax(probs), probs

# Demo run with random input image
img = np.random.rand(28, 28)
predicted_digit, probabilities = cnn_digit_recognition(img)

# Display the randomly generated image
plt.imshow(img, cmap='gray')
plt.title(f"Predicted digit: {predicted_digit}")
plt.show()

print("Predicted digit:", predicted_digit)
print("Probabilities:", probabilities)
