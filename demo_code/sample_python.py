# Sample Python file with inefficient code for optimization testing

def inefficient_fibonacci(n):
    """
    Calculate the nth Fibonacci number using a highly inefficient recursive approach.
    This implementation has exponential time complexity O(2^n).
    
    Args:
        n: The position in the Fibonacci sequence to calculate
        
    Returns:
        The nth Fibonacci number
    """
    if n <= 0:
        return 0
    elif n == 1:
        return 1
    else:
        return inefficient_fibonacci(n-1) + inefficient_fibonacci(n-2)

def inefficient_list_search(item, my_list):
    """
    Inefficiently search for an item in a list by checking each element.
    This implementation doesn't leverage Python's built-in 'in' operator.
    
    Args:
        item: The item to search for
        my_list: The list to search in
        
    Returns:
        True if the item is found, False otherwise
    """
    found = False
    for element in my_list:
        if element == item:
            found = True
            break
    return found

def inefficient_string_concatenation(strings):
    """
    Inefficiently concatenate strings using + operator in a loop.
    This creates a new string object each time, which is inefficient.
    
    Args:
        strings: A list of strings to concatenate
        
    Returns:
        The concatenated string
    """
    result = ""
    for s in strings:
        result = result + s
    return result

def calculate_averages(data):
    """
    Inefficiently calculate averages of subarrays in a nested list.
    This implementation recalculates the sum and length multiple times.
    
    Args:
        data: A list of lists containing numbers
        
    Returns:
        A list of averages for each subarray
    """
    averages = []
    for subarray in data:
        sum_value = 0
        length = 0
        for item in subarray:
            sum_value += item
            length += 1
        if length > 0:
            averages.append(sum_value / length)
        else:
            averages.append(0)
    return averages

# Example usage
if __name__ == "__main__":
    print(f"Fibonacci(10): {inefficient_fibonacci(10)}")
    print(f"Search result: {inefficient_list_search(5, [1, 2, 3, 4, 5])}")
    print(f"Concatenated: {inefficient_string_concatenation(['Hello', ' ', 'World', '!'])}")
    print(f"Averages: {calculate_averages([[1, 2, 3], [4, 5, 6], [7, 8, 9]])}") 