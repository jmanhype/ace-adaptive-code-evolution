# Script to fix PR file content
IO.puts("Starting PR file fix script...")

# Get the PR by number
{:ok, pr} = Ace.GitHub.Service.get_pull_request_by_number(3, "jmanhype/synaflow")
IO.puts("Found PR: ##{pr.number} - #{pr.title}")

# Sample content for inefficient_api.js
js_content = """
class InefficientApiClient {
  constructor(apiUrl, apiKey) {
    this.apiUrl = apiUrl;
    this.baseUrl = apiUrl;
    this.apiUrlWithBase = apiUrl + '/v1';
    this.apiUrlWithBaseAndVersion = apiUrl + '/v1/api';
    this.apiKey = apiKey;
    this.lastRequestTime = null;
    this.requestQueue = [];
    this.cache = {};
  }

  async fetchData(endpoint, params = {}) {
    // Inefficient string concatenation
    let url = this.baseUrl + '/v1/api/' + endpoint;
    
    // Build query string inefficiently
    let queryString = '?';
    for (const key in params) {
      queryString += key + '=' + params[key] + '&';
    }
    queryString += 'api_key=' + this.apiKey;
    
    // Complete URL
    url = url + queryString;
    
    // Store request time with poor precision
    this.lastRequestTime = new Date().toString();
    
    // Inefficient error handling
    try {
      const response = await fetch(url);
      const data = await response.json();
      
      // Unnecessarily parse and stringify again
      const parsedData = JSON.parse(JSON.stringify(data));
      
      // Cache without limits
      this.cache[url] = parsedData;
      
      return parsedData;
    } catch (error) {
      console.error('Error:', error);
      // No proper error return
      return {};
    }
  }

  processResults(results) {
    // Deep copy inefficiently
    const resultsCopy = JSON.parse(JSON.stringify(results));
    
    // Inefficient array processing
    let processedResults = [];
    for (let i = 0; i < resultsCopy.length; i++) {
      const item = resultsCopy[i];
      // Inefficient object creation
      processedResults.push({
        id: item.id,
        name: item.name,
        value: item.value,
        timestamp: item.timestamp,
        processed: true
      });
    }
    
    return processedResults;
  }

  clearCache() {
    // Inefficient cache clearing
    for (const key in this.cache) {
      delete this.cache[key];
    }
    this.cache = {};
  }
}

module.exports = { InefficientApiClient };
"""

# Sample content for inefficient_helpers.py
py_content = """
import time
import json
import re
import math

def inefficient_string_concat(items, separator=', '):
    # Inefficient string concatenation in a loop
    result = ''
    for item in items:
        result = result + str(item) + separator
    # Remove trailing separator
    if result:
        result = result[:-len(separator)]
    return result

def expensive_factorial(n):
    # Recursive implementation without memoization
    if n <= 1:
        return 1
    else:
        return n * expensive_factorial(n - 1)

def memory_hog(size=1000):
    # Create unnecessarily large lists with duplicated data
    big_list = []
    for i in range(size):
        # Create a new list for each iteration
        temp_list = list(range(size))
        # Make unnecessary copy
        big_list.append(temp_list.copy())
    
    # Inefficient nested iteration
    result = []
    for outer in big_list:
        for middle in outer:
            # Redundant conversion
            result.append(str(middle))
    
    return result

def parse_data_inefficiently(data_string):
    # Inefficient parsing with multiple passes
    lines = data_string.split('\\n')
    result = {}
    
    # Parse in an inefficient way
    for line in lines:
        # Multiple string operations where one would do
        line = line.strip()
        if not line:
            continue
        
        parts = line.split(':')
        if len(parts) < 2:
            continue
        
        key = parts[0].strip()
        # Inefficient joining
        value = ''
        for i in range(1, len(parts)):
            value += parts[i]
            if i < len(parts) - 1:
                value += ':'
        
        result[key] = value.strip()
    
    # Unnecessary conversion
    return json.loads(json.dumps(result))

def slow_search(needle, haystack):
    # Inefficient string search implementation
    found_indices = []
    
    # O(n²) search instead of using built-in methods
    for i in range(len(haystack)):
        match = True
        for j in range(len(needle)):
            if i + j >= len(haystack) or haystack[i + j] != needle[j]:
                match = False
                break
        if match:
            found_indices.append(i)
    
    return found_indices

class IneffientDataProcessor:
    def __init__(self):
        # Initialize with empty structures that will be immediately replaced
        self.data = []
        self.initialize_data()
        
        # Redundant storage
        self.data_copy = self.data.copy()
        self.data_length = len(self.data)
        self.data_status = "initialized"
    
    def initialize_data(self):
        # Reset data unnecessarily
        self.data = []
        # Then fill it again
        for i in range(100):
            self.data.append({'id': i, 'value': i * 2})
    
    def process_data(self):
        # Process inefficiently with O(n²) when O(n) would work
        result = []
        for item in self.data:
            # Unnecessary intermediate array
            temp = []
            for other_item in self.data:
                if item['id'] != other_item['id']:
                    temp.append(other_item['value'])
            
            # Calculate average in an inefficient way
            total = 0
            count = 0
            for val in temp:
                total += val
                count += 1
            
            avg = total / count if count > 0 else 0
            
            # Create new dict instead of updating existing
            result.append({
                'id': item['id'],
                'value': item['value'],
                'avg_others': avg
            })
        
        return result
"""

# Update PRFile for JavaScript file
js_file = Ace.GitHub.Models.PRFile
|> Ace.Repo.get_by(pr_id: pr.id, filename: "src/inefficient_api.js")

if js_file do
  IO.puts("Updating JavaScript file...")
  # Use Ecto.Changeset to update
  js_file
  |> Ecto.Changeset.change(%{content: js_content})
  |> Ace.Repo.update()
  |> case do
    {:ok, _updated} -> IO.puts("✅ JavaScript file updated")
    {:error, error} -> IO.puts("❌ Error updating JavaScript file: #{inspect(error)}")
  end
else
  IO.puts("⚠️ JavaScript file not found")
end

# Update PRFile for Python file
py_file = Ace.GitHub.Models.PRFile
|> Ace.Repo.get_by(pr_id: pr.id, filename: "src/inefficient_helpers.py")

if py_file do
  IO.puts("Updating Python file...")
  # Use Ecto.Changeset to update
  py_file
  |> Ecto.Changeset.change(%{content: py_content})
  |> Ace.Repo.update()
  |> case do
    {:ok, _updated} -> IO.puts("✅ Python file updated")
    {:error, error} -> IO.puts("❌ Error updating Python file: #{inspect(error)}")
  end
else
  IO.puts("⚠️ Python file not found")
end

IO.puts("Script completed!")
