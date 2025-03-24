# Inefficient Python code for optimization testing

def slow_function(n):
    """
    A deliberately inefficient function that builds a list of strings.
    
    Args:
        n: Integer representing the number of strings to generate
        
    Returns:
        A list of strings
    """
    result = []
    for i in range(n):
        # Inefficient string concatenation
        s = ""
        for j in range(i):
            s = s + str(j) + "-"
        result.append(s)
    return result

def inefficient_data_processing(data):
    """
    Process data inefficiently using multiple loops.
    
    Args:
        data: A list of integers
        
    Returns:
        A filtered and transformed list
    """
    # Inefficient filtering
    filtered = []
    for item in data:
        if item % 2 == 0:
            filtered.append(item)
    
    # Inefficient transformation
    result = []
    for item in filtered:
        result.append(item * item)
    
    return result

def slow_search(lst, item):
    """
    A deliberately slow search algorithm.
    
    Args:
        lst: The list to search through
        item: The item to find
        
    Returns:
        True if the item is in the list, False otherwise
    """
    # Using a loop instead of 'in' operator
    found = False
    for element in lst:
        if element == item:
            found = True
            break
    return found

if __name__ == "__main__":
    # Some inefficient operations
    numbers = list(range(1000))
    result1 = slow_function(100)
    result2 = inefficient_data_processing(numbers)
    result3 = [slow_search(numbers, i) for i in range(100)]
    
    print(f"Generated {len(result1)} strings")
    print(f"Processed {len(result2)} numbers")
    print(f"Found {sum(result3)} items") 