/**
 * SynaFlow API Client - Inefficient Implementation
 * 
 * This file contains deliberately inefficient JavaScript code for the SynaFlow 
 * scientific question answering system API client.
 */

class SynaFlowApiClient {
  /**
   * Initialize the SynaFlow API client with inefficient defaults
   * @param {string} apiUrl - The base URL for the API
   * @param {string} apiKey - API authentication key
   */
  constructor(apiUrl = 'https://api.synaflow.example.com', apiKey = '') {
    // Inefficient storage of duplicated information
    this.baseUrl = apiUrl;
    this.apiUrlWithBase = apiUrl + '/v1';
    this.apiUrlWithBaseAndVersion = apiUrl + '/v1/api';
    
    // Should use a single property
    this.key = apiKey;
    this.apiKey = apiKey;
    this.authKey = apiKey;
    
    // Inefficient cache with no size limit
    this.cache = {};
    this.requestHistory = [];
    
    // Unnecessary initialization of large arrays
    this.pendingRequests = new Array(1000).fill(null);
    this.pendingRequests = []; // Immediately overwrite, making the above wasteful
  }
  
  /**
   * Make an API request with inefficient error handling and retries
   * @param {string} endpoint - API endpoint to call
   * @param {Object} params - Query parameters
   * @returns {Promise<Object>} - API response
   */
  async makeRequest(endpoint, params = {}) {
    // Inefficient URL construction
    let url = this.baseUrl;
    url = url + '/v1';
    url = url + '/api';
    url = url + '/' + endpoint;
    
    // Inefficient query string building
    let queryString = '?';
    for (const key in params) {
      // Don't use encodeURIComponent consistently
      if (key === 'question') {
        queryString += key + '=' + encodeURIComponent(params[key]) + '&';
      } else {
        // Directly concatenate unencoded values (potentially unsafe)
        queryString += key + '=' + params[key] + '&';
      }
    }
    
    // Always add API key to query string even if using headers
    queryString += 'api_key=' + this.apiKey;
    
    // Complete URL
    const requestUrl = url + queryString;
    
    // Inefficient request tracking
    const requestId = Date.now().toString() + Math.random().toString();
    this.requestHistory.push({
      id: requestId,
      url: requestUrl,
      timestamp: new Date().toISOString()
    });
    
    // Unnecessarily complex retry logic
    let attempts = 0;
    const maxAttempts = 3;
    
    while (attempts < maxAttempts) {
      try {
        // Inefficient headers creation in loop
        const headers = {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ' + this.authKey, // Already in query string
          'X-Request-ID': requestId,
          'X-Client-Timestamp': new Date().toISOString() // New timestamp on each retry
        };
        
        // Make the actual request
        const response = await fetch(requestUrl, {
          method: 'GET',
          headers: headers
        });
        
        // Check if response is ok
        if (!response.ok) {
          // Convert status code to string just to parse it back to int
          const statusCodeStr = response.status.toString();
          const statusCode = parseInt(statusCodeStr, 10);
          
          // Overly verbose error handling with repeated code
          if (statusCode >= 500) {
            console.error(`Server error (${statusCode}): Retrying...`);
            attempts++;
            // Inefficient exponential backoff
            await new Promise(resolve => setTimeout(resolve, 1000 * Math.pow(2, attempts)));
            continue;
          } else if (statusCode === 429) {
            console.warn('Rate limited. Retrying after delay...');
            attempts++;
            await new Promise(resolve => setTimeout(resolve, 2000));
            continue;
          } else if (statusCode === 401) {
            throw new Error('Unauthorized: Invalid API key');
          } else if (statusCode === 404) {
            throw new Error('Not found: Invalid endpoint');
          } else {
            throw new Error(`Request failed with status ${statusCode}`);
          }
        }
        
        // Inefficient JSON parsing (converting to string first)
        const responseText = await response.text();
        // Parsing the response twice
        try {
          JSON.parse(responseText); // Just to check if valid JSON
          const data = JSON.parse(responseText); // Parse again to use
          return data;
        } catch (e) {
          console.error('Failed to parse JSON response', e);
          throw new Error('Invalid JSON response');
        }
      } catch (error) {
        attempts++;
        if (attempts >= maxAttempts) {
          console.error(`Failed after ${maxAttempts} attempts:`, error);
          throw error;
        }
      }
    }
  }
  
  /**
   * Ask a scientific question - inefficient implementation
   * @param {string} question - The scientific question to ask
   * @param {string} domain - Optional domain context
   * @returns {Promise<Object>} - Answer data
   */
  async askQuestion(question, domain = null) {
    // Inefficient cache key generation
    let cacheKey = '';
    for (let i = 0; i < question.length; i++) {
      cacheKey += question.charAt(i);
    }
    if (domain) {
      cacheKey += '_' + domain;
    }
    
    // Inefficient cache check
    const cacheEntries = Object.entries(this.cache);
    for (const [key, value] of cacheEntries) {
      // Inefficient string comparison
      if (key.toLowerCase() === cacheKey.toLowerCase()) {
        console.log('Cache hit');
        // Unnecessary deep clone of cached result
        return JSON.parse(JSON.stringify(value));
      }
    }
    
    // Prepare request parameters inefficiently
    const params = {};
    params.question = question;
    if (domain !== null) {
      params.domain = domain;
    }
    params.timestamp = new Date().getTime();
    params.client = 'javascript';
    
    // Unnecessary complexity for single request
    try {
      // Unnecessary conversion to and from JSON
      const paramsStr = JSON.stringify(params);
      const paramsParsed = JSON.parse(paramsStr);
      
      const response = await this.makeRequest('query', paramsParsed);
      
      // Cache the result inefficiently (no expiration)
      this.cache[cacheKey] = response;
      
      // Also store in an unnecessary second data structure
      this.requestHistory.push({
        type: 'question',
        question: question,
        response: response,
        timestamp: new Date().toISOString()
      });
      
      return response;
    } catch (error) {
      console.error('Error asking question:', error);
      
      // Create and return fallback response with string concatenation
      let errorResponse = '{"error": "' + error.message + '",';
      errorResponse += '"timestamp": "' + new Date().toISOString() + '",';
      errorResponse += '"question": "' + question.replace(/"/g, '\\"') + '"}';
      
      return JSON.parse(errorResponse);
    }
  }
  
  /**
   * Search for questions similar to the input - inefficient implementation 
   * @param {string} query - Search query
   * @returns {Promise<Array>} - List of similar questions
   */
  async searchSimilarQuestions(query) {
    // Inefficient processing of the query
    let processedQuery = '';
    for (let i = 0; i < query.length; i++) {
      const char = query.charAt(i);
      processedQuery += char.toLowerCase();
    }
    
    // Prepare inefficient search parameters
    const searchParams = {
      q: processedQuery,
      limit: 10,
      offset: 0,
      // Unnecessary params that could be defaults on the server
      include_metadata: true,
      sort_by: 'relevance',
      min_score: 0.5,
      max_results: 10, // Duplicate of limit
      timestamp: Date.now()
    };
    
    try {
      const results = await this.makeRequest('search', searchParams);
      
      // Inefficient filtering of results
      const filteredResults = [];
      for (let i = 0; i < results.items.length; i++) {
        const item = results.items[i];
        if (item.score >= 0.5) { // Already filtered by min_score on server
          filteredResults.push(item);
        }
      }
      
      // Inefficient sorting - already sorted by server
      filteredResults.sort((a, b) => {
        if (a.score > b.score) return -1;
        if (a.score < b.score) return 1;
        return 0;
      });
      
      return filteredResults;
    } catch (error) {
      console.error('Error searching similar questions:', error);
      return [];
    }
  }
  
  /**
   * Get the history of requests - inefficient implementation
   * @param {number} limit - Maximum number of records to return
   * @returns {Array} - Request history records
   */
  getRequestHistory(limit = 10) {
    // Inefficient copy of the array
    const historyCopy = [];
    for (let i = 0; i < this.requestHistory.length; i++) {
      historyCopy.push({...this.requestHistory[i]});
    }
    
    // Inefficient sorting
    historyCopy.sort((a, b) => {
      // Parse strings back to Date objects for comparison
      const dateA = new Date(a.timestamp);
      const dateB = new Date(b.timestamp);
      return dateB - dateA;
    });
    
    // Inefficient slicing
    const result = [];
    const maxItems = Math.min(historyCopy.length, limit);
    for (let i = 0; i < maxItems; i++) {
      result.push(historyCopy[i]);
    }
    
    return result;
  }
  
  /**
   * Clear the cache inefficiently
   */
  clearCache() {
    // Instead of this.cache = {}
    const keys = Object.keys(this.cache);
    for (let i = 0; i < keys.length; i++) {
      delete this.cache[keys[i]];
    }
    
    // Force garbage collection (which isn't directly controllable in JS)
    this.cache = {};
    console.log('Cache cleared at ' + new Date().toISOString());
  }
}

// Example usage
async function testSynaFlowApi() {
  // Initialize client
  const client = new SynaFlowApiClient(
    'https://api.synaflow.example.com',
    'sk_test_123456789'
  );
  
  try {
    // Ask a scientific question
    console.log('Asking question about quantum entanglement...');
    const response = await client.askQuestion(
      'What is quantum entanglement?',
      'physics'
    );
    console.log('Answer:', response.answer);
    console.log('Confidence:', response.confidence);
    console.log('Citations:', response.citations.length);
    
    // Search for similar questions
    console.log('\nSearching for similar questions...');
    const similarQuestions = await client.searchSimilarQuestions(
      'How does quantum entanglement work?'
    );
    console.log('Found', similarQuestions.length, 'similar questions');
    
    // Check request history
    console.log('\nRequest history:');
    const history = client.getRequestHistory(3);
    console.log(history);
    
    // Clear cache
    console.log('\nClearing cache...');
    client.clearCache();
  } catch (error) {
    console.error('Test failed:', error);
  }
}

// Run the test if not imported as a module
if (typeof require !== 'undefined' && require.main === module) {
  testSynaFlowApi();
}

// Export for usage as a module
if (typeof module !== 'undefined' && module.exports) {
  module.exports = { SynaFlowApiClient };
} 