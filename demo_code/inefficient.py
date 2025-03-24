# A Python file with some optimization opportunities

def slow_function(numbers):
    """
    A function with inefficient code that can be optimized.
    """
    result = []
    for num in numbers:
        # Inefficient string concatenation in a loop
        text = ""
        for i in range(num):
            text += str(i) + ","
        
        # Inefficient list append in a loop
        squares = []
        for i in range(num):
            squares.append(i * i)
        
        # Inefficient filtering
        even_squares = []
        for square in squares:
            if square % 2 == 0:
                even_squares.append(square)
        
        result.append((text, even_squares))
    
    return result

def process_data(data_list):
    """
    Process a list of data with multiple passes and inefficient operations.
    """
    # Multiple list traversals that could be combined
    max_value = 0
    for item in data_list:
        if item > max_value:
            max_value = item
    
    min_value = float('inf')
    for item in data_list:
        if item < min_value:
            min_value = item
    
    total = 0
    for item in data_list:
        total += item
    
    average = total / len(data_list)
    
    # Inefficient filtering
    filtered = []
    for item in data_list:
        if min_value <= item <= max_value and item != average:
            filtered.append(item)
    
    return {
        'max': max_value,
        'min': min_value,
        'average': average,
        'filtered': filtered
    }

# Some inefficient global variables
global_cache = {}

# Function that could benefit from memoization
def fibonacci(n):
    """Calculate the Fibonacci number inefficiently."""
    if n <= 1:
        return n
    return fibonacci(n-1) + fibonacci(n-2)

# Main execution with some redundant operations
if __name__ == "__main__":
    numbers = [5, 10, 15]
    result = slow_function(numbers)
    print(f"Result: {result}")
    
    data = [3, 1, 4, 1, 5, 9, 2, 6, 5, 3, 5]
    processed = process_data(data)
    print(f"Processed data: {processed}")
    
    # Inefficient use of the fibonacci function
    fib_results = []
    for i in range(10):
        fib_results.append(fibonacci(i))
    print(f"Fibonacci results: {fib_results}")

