// Sample JavaScript file with inefficient code for optimization testing

/**
 * Calculate the nth Fibonacci number using an inefficient recursive approach.
 * This implementation has exponential time complexity O(2^n).
 * 
 * @param {number} n - The position in the Fibonacci sequence to calculate
 * @returns {number} The nth Fibonacci number
 */
function inefficientFibonacci(n) {
  if (n <= 0) {
    return 0;
  } else if (n === 1) {
    return 1;
  } else {
    return inefficientFibonacci(n - 1) + inefficientFibonacci(n - 2);
  }
}

/**
 * Inefficiently search for an item in an array by checking each element.
 * This implementation doesn't leverage JavaScript's built-in array methods.
 * 
 * @param {*} item - The item to search for
 * @param {Array} array - The array to search in
 * @returns {boolean} True if the item is found, false otherwise
 */
function inefficientArraySearch(item, array) {
  let found = false;
  for (let i = 0; i < array.length; i++) {
    if (array[i] === item) {
      found = true;
      break;
    }
  }
  return found;
}

/**
 * Inefficiently concatenate strings using the + operator in a loop.
 * This creates a new string object each time, which is inefficient.
 * 
 * @param {Array<string>} strings - An array of strings to concatenate
 * @returns {string} The concatenated string
 */
function inefficientStringConcatenation(strings) {
  let result = "";
  for (let i = 0; i < strings.length; i++) {
    result = result + strings[i];
  }
  return result;
}

/**
 * Calculate averages of subarrays in a nested array inefficiently.
 * This implementation recalculates values multiple times.
 * 
 * @param {Array<Array<number>>} data - A nested array of numbers
 * @returns {Array<number>} An array of averages for each subarray
 */
function calculateAverages(data) {
  const averages = [];
  for (let i = 0; i < data.length; i++) {
    let sum = 0;
    let length = 0;
    for (let j = 0; j < data[i].length; j++) {
      sum += data[i][j];
      length += 1;
    }
    if (length > 0) {
      averages.push(sum / length);
    } else {
      averages.push(0);
    }
  }
  return averages;
}

/**
 * An inefficient implementation to find duplicate items in an array.
 * This uses a nested loop, resulting in O(n²) time complexity.
 * 
 * @param {Array} array - The array to check for duplicates
 * @returns {Array} An array of duplicate items
 */
function findDuplicatesInefficiently(array) {
  const duplicates = [];
  for (let i = 0; i < array.length; i++) {
    for (let j = i + 1; j < array.length; j++) {
      if (array[i] === array[j] && !duplicates.includes(array[i])) {
        duplicates.push(array[i]);
      }
    }
  }
  return duplicates;
}

// Example usage
console.log(`Fibonacci(10): ${inefficientFibonacci(10)}`);
console.log(`Search result: ${inefficientArraySearch(5, [1, 2, 3, 4, 5])}`);
console.log(`Concatenated: ${inefficientStringConcatenation(['Hello', ' ', 'World', '!'])}`);
console.log(`Averages: ${calculateAverages([[1, 2, 3], [4, 5, 6], [7, 8, 9]])}`);
console.log(`Duplicates: ${findDuplicatesInefficiently([1, 2, 3, 2, 4, 1, 5])}`); 