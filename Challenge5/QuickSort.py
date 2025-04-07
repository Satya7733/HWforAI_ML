def quicksort(arr):
    if len(arr) <= 1:
        return arr  # Base case: a list with 0 or 1 element is already sorted
    
    pivot = arr[len(arr) // 2]  # Choosing the middle element as the pivot
    left = [x for x in arr if x < pivot]  # Elements smaller than pivot
    middle = [x for x in arr if x == pivot]  # Elements equal to pivot
    right = [x for x in arr if x > pivot]  # Elements greater than pivot
    
    return quicksort(left) + middle + quicksort(right)  # Recursively sorting and combining

# Example Usage
arr = [10, 3, 8, 15, 6, 12, 2, 18, 7]
sorted_arr = quicksort(arr)
print("Sorted Array:", sorted_arr)
