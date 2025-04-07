def matrix_multiply_manual(A, B):
    """
    Multiply two matrices manually.
    
    Args:
        A: First matrix (list of lists)
        B: Second matrix (list of lists)
    
    Returns:
        The product of A and B
    """
    # Check if matrices can be multiplied
    if len(A[0]) != len(B):
        raise ValueError("Matrix dimensions don't match for multiplication. A columns must equal B rows.")
    
    # Initialize result matrix with zeros
    rows_A = len(A)
    cols_B = len(B[0])
    result = [[0 for _ in range(cols_B)] for _ in range(rows_A)]
    
    # Perform matrix multiplication
    for i in range(rows_A):
        for j in range(cols_B):
            for k in range(len(B)):
                result[i][j] += A[i][k] * B[k][j]
                
    return result

# Example usage
A = [
    [1, 2, 3],
    [4, 5, 6]
]

B = [
    [7, 8],
    [9, 10],
    [11, 12]
]

result = matrix_multiply_manual(A, B)
print("Matrix multiplication result:")
for row in result:
    print(row)