defmodule Ace.Evaluation.ExperimentFactory do
  @moduledoc """
  Creates language-specific experiments for code optimization validation.
  """
  
  @doc """
  Creates an experiment for the specified language.
  
  ## Parameters
  
    - `language`: The programming language of the code
    - `original_code`: The original code to test
    - `optimized_code`: The optimized code to test
  
  ## Returns
  
    - `{:ok, setup_data}`: Setup data for the experiment
    - `{:error, reason}`: If creating the experiment fails
  """
  def create(language, original_code, optimized_code) do
    module = get_language_module(language)
    module.create_experiment(original_code, optimized_code)
  end
  
  # Get the appropriate module for the specified language
  defp get_language_module(language) do
    case String.downcase(language) do
      "elixir" -> Ace.Evaluation.Languages.Elixir
      "javascript" -> Ace.Evaluation.Languages.JavaScript
      "python" -> Ace.Evaluation.Languages.Python
      "ruby" -> Ace.Evaluation.Languages.Ruby
      "go" -> Ace.Evaluation.Languages.Go
      _ -> Ace.Evaluation.Languages.Generic
    end
  end
end

defmodule Ace.Evaluation.Languages.Elixir do
  @moduledoc """
  Elixir-specific experiment implementation.
  """
  
  @doc """
  Creates an experiment for Elixir code.
  """
  def create_experiment(original_code, optimized_code) do
    # Create temporary directory for the experiment
    experiment_dir = create_experiment_dir()
    
    try do
      # Generate unique module names
      module_name = generate_module_name()
      original_module_name = module_name <> "Original"
      optimized_module_name = module_name <> "Optimized"
      
      # Create original module file
      original_file = Path.join(experiment_dir, "original.ex")
      original_module_code = wrap_in_module(original_module_name, original_code)
      File.write!(original_file, original_module_code)
      
      # Create optimized module file
      optimized_file = Path.join(experiment_dir, "optimized.ex")
      optimized_module_code = wrap_in_module(optimized_module_name, optimized_code)
      File.write!(optimized_file, optimized_module_code)
      
      # Create test file
      test_file = Path.join(experiment_dir, "experiment_test.exs")
      test_code = generate_test_code(original_module_name, optimized_module_name)
      File.write!(test_file, test_code)
      
      # Create benchmark file
      bench_file = Path.join(experiment_dir, "benchmark.exs")
      bench_code = generate_benchmark_code(original_module_name, optimized_module_name)
      File.write!(bench_file, bench_code)
      
      {:ok, %{
        dir: experiment_dir,
        original_file: original_file,
        optimized_file: optimized_file,
        test_file: test_file,
        bench_file: bench_file,
        module_name_original: original_module_name,
        module_name_optimized: optimized_module_name
      }}
    rescue
      e ->
        # Clean up on error
        File.rm_rf(experiment_dir)
        {:error, "Failed to create experiment: #{Exception.message(e)}"}
    end
  end
  
  # Create a unique experiment directory
  defp create_experiment_dir do
    base_dir = System.tmp_dir!()
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    random_suffix = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
    experiment_dir = Path.join(base_dir, "ace_experiment_#{timestamp}_#{random_suffix}")
    
    File.mkdir_p!(experiment_dir)
    experiment_dir
  end
  
  # Generate a unique module name
  defp generate_module_name do
    "AceExperiment" <> (
      :crypto.strong_rand_bytes(4)
      |> Base.encode16(case: :upper)
    )
  end
  
  # Wrap code in a module definition
  defp wrap_in_module(module_name, code) do
    """
    defmodule #{module_name} do
      @moduledoc false
      
    #{code}
    end
    """
  end
  
  # Generate test code to verify correctness
  defp generate_test_code(original_module, optimized_module) do
    """
    ExUnit.start()
    
    # Dynamically load the modules
    Code.require_file("original.ex", __DIR__)
    Code.require_file("optimized.ex", __DIR__)
    
    defmodule ExperimentTest do
      use ExUnit.Case
      
      @original_module #{original_module}
      @optimized_module #{optimized_module}
      
      # Basic test with fixed values
      test "modules produce the same results" do
        # Get all functions from the original module
        functions = @original_module.__info__(:functions)
        
        # Test each function
        for {function_name, arity} <- functions do
          if function_name not in [:module_info, :__info__] do
            # Generate arguments based on arity
            args = generate_args(arity)
            
            # Call both functions with the same arguments
            original_result = apply(@original_module, function_name, args)
            optimized_result = apply(@optimized_module, function_name, args)
            
            # Verify the results match
            assert original_result == optimized_result,
                   "Function \#{function_name}/\#{arity} produced different results"
          end
        end
      end
      
      # Helper to generate random arguments
      def generate_args(0), do: []
      def generate_args(arity) do
        Enum.map(1..arity, fn _ -> generate_random_value() end)
      end
      
      # Generate a random value of various types
      def generate_random_value do
        case :rand.uniform(5) do
          1 -> :rand.uniform(100)                                   # integer
          2 -> :rand.uniform() * 100                                # float
          3 -> for(_ <- 1..:rand.uniform(5), do: :rand.uniform(10)) # list
          4 -> "test_" <> Integer.to_string(:rand.uniform(100))     # string
          5 -> %{a: :rand.uniform(10), b: "test"}                   # map
        end
      end
    end
    """
  end
  
  # Generate benchmark code to compare performance
  defp generate_benchmark_code(original_module, optimized_module) do
    """
    # Dynamically load the modules
    Code.require_file("original.ex", __DIR__)
    Code.require_file("optimized.ex", __DIR__)
    
    # Get all functions from the original module
    functions = #{original_module}.__info__(:functions)
    
    results = %{}
    
    # Benchmark each function
    Enum.each(functions, fn {function_name, arity} ->
      # Skip specific functions
      if function_name not in [:module_info, :__info__] do
        # Generate fixed args for consistent benchmarking
        args = generate_fixed_args(arity)
        
        # Time original implementation
        {original_time, _} = :timer.tc(fn ->
          for _ <- 1..1000 do
            apply(#{original_module}, function_name, args)
          end
        end)
        
        # Time optimized implementation
        {optimized_time, _} = :timer.tc(fn ->
          for _ <- 1..1000 do
            apply(#{optimized_module}, function_name, args)
          end
        end)
        
        # Calculate improvement percentage
        improvement = if original_time > 0 do
          ((original_time - optimized_time) / original_time) * 100
        else
          0.0
        end
        
        results = Map.put(results, "\#{function_name}/\#{arity}", %{
          original_time_μs: original_time,
          optimized_time_μs: optimized_time,
          improvement_percent: improvement
        })
        
        IO.puts "Function \#{function_name}/\#{arity}:"
        IO.puts "  Original time:  \#{original_time} μs"
        IO.puts "  Optimized time: \#{optimized_time} μs"
        IO.puts "  Improvement:    \#{Float.round(improvement, 2)}%"
        IO.puts ""
      end
    end)
    
    # Calculate overall improvement
    all_original = Enum.reduce(results, 0, fn {_, data}, acc -> acc + data.original_time_μs end)
    all_optimized = Enum.reduce(results, 0, fn {_, data}, acc -> acc + data.optimized_time_μs end)
    overall_improvement = if all_original > 0 do
      ((all_original - all_optimized) / all_original) * 100
    else
      0.0
    end
    
    IO.puts "Overall performance change: \#{Float.round(overall_improvement, 2)}%"
    
    # Helper to generate fixed arguments
    def generate_fixed_args(0), do: []
    def generate_fixed_args(arity) do
      Enum.map(1..arity, fn i -> 
        case rem(i, 5) do
          0 -> 42                     # integer
          1 -> 3.14                   # float
          2 -> [1, 2, 3, 4, 5]        # list
          3 -> "test_value"           # string
          4 -> %{a: 1, b: "test"}     # map
        end
      end)
    end
    
    # Return metrics
    %{
      function_metrics: results,
      overall_improvement: overall_improvement,
      original_total_μs: all_original,
      optimized_total_μs: all_optimized
    }
    """
  end
end

defmodule Ace.Evaluation.Languages.JavaScript do
  @moduledoc """
  JavaScript-specific experiment implementation.
  """
  
  @doc """
  Creates an experiment for JavaScript code.
  """
  def create_experiment(original_code, optimized_code) do
    # Create temporary directory for the experiment
    experiment_dir = create_experiment_dir()
    
    try do
      # Create module files
      original_file = Path.join(experiment_dir, "original.js")
      optimized_file = Path.join(experiment_dir, "optimized.js")
      
      # Write the files
      File.write!(original_file, wrap_in_module("OriginalModule", original_code))
      File.write!(optimized_file, wrap_in_module("OptimizedModule", optimized_code))
      
      # Create test file
      test_file = Path.join(experiment_dir, "test.js")
      test_code = generate_test_code()
      File.write!(test_file, test_code)
      
      # Create benchmark file
      bench_file = Path.join(experiment_dir, "benchmark.js")
      bench_code = generate_benchmark_code()
      File.write!(bench_file, bench_code)
      
      # Create package.json for dependencies
      package_json = Path.join(experiment_dir, "package.json")
      package_content = generate_package_json()
      File.write!(package_json, package_content)
      
      {:ok, %{
        dir: experiment_dir,
        original_file: original_file,
        optimized_file: optimized_file,
        test_file: test_file,
        bench_file: bench_file
      }}
    rescue
      e ->
        # Clean up on error
        File.rm_rf(experiment_dir)
        {:error, "Failed to create JavaScript experiment: #{Exception.message(e)}"}
    end
  end
  
  # Create a unique experiment directory
  defp create_experiment_dir do
    base_dir = System.tmp_dir!()
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    random_suffix = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
    experiment_dir = Path.join(base_dir, "ace_js_experiment_#{timestamp}_#{random_suffix}")
    
    File.mkdir_p!(experiment_dir)
    experiment_dir
  end
  
  # Wrap JavaScript code in a module
  defp wrap_in_module(module_name, code) do
    """
    /**
     * #{module_name} - Code under test
     * 
     * This file was auto-generated by the ACE experiment factory.
     */
    
    const #{module_name} = (function() {
      // Original code
    #{code}
    
      // Automatically detect and expose functions
      const module = {};
      
      // Find all function declarations and function expressions assigned to variables
      const functionRegex = /(?:function\\s+(\\w+)|(?:const|let|var)\\s+(\\w+)\\s*=\\s*function|(?:const|let|var)\\s+(\\w+)\\s*=\\s*\\([^)]*\\)\\s*=>)/g;
      const functionMatches = [...`${code}`.matchAll(functionRegex)];
      
      functionMatches.forEach(match => {
        const functionName = match[1] || match[2] || match[3];
        if (functionName && typeof eval(functionName) === 'function') {
          module[functionName] = eval(functionName);
        }
      });
      
      return module;
    })();
    
    // For Node.js
    if (typeof module !== 'undefined' && module.exports) {
      module.exports = #{module_name};
    }
    """
  end
  
  # Generate Jest test file
  defp generate_test_code do
    """
    /**
     * Test file for comparing original and optimized implementations
     * 
     * This file uses Jest for testing.
     */
    
    const OriginalModule = require('./original.js');
    const OptimizedModule = require('./optimized.js');
    
    // Helper to generate test values
    function generateTestValue(type) {
      switch(type) {
        case 'number':
          return Math.floor(Math.random() * 100);
        case 'string':
          return `test_${Math.floor(Math.random() * 100)}`;
        case 'array':
          return Array.from({length: 5}, () => Math.floor(Math.random() * 10));
        case 'object':
          return {a: Math.floor(Math.random() * 10), b: 'test'};
        case 'boolean':
          return Math.random() > 0.5;
        default:
          return 42;
      }
    }
    
    // For each function in the original module, create a test
    describe('Optimization Correctness Tests', () => {
      // Get all functions in the original module
      const functions = Object.keys(OriginalModule).filter(
        key => typeof OriginalModule[key] === 'function'
      );
      
      // Test each function
      functions.forEach(functionName => {
        test(`${functionName} should maintain the same behavior`, () => {
          // Skip non-function properties
          if (typeof OriginalModule[functionName] !== 'function') return;
          
          // Determine the number of parameters
          const originalFunction = OriginalModule[functionName];
          const optimizedFunction = OptimizedModule[functionName];
          
          // Get the function's expected parameter count
          const paramCount = originalFunction.length;
          
          // Generate arguments based on parameter count
          const args = Array.from({length: paramCount}, (_, i) => {
            // Cycle through different types
            const types = ['number', 'string', 'array', 'object', 'boolean'];
            return generateTestValue(types[i % types.length]);
          });
          
          // Call both implementations with the same arguments
          const originalResult = originalFunction(...args);
          const optimizedResult = optimizedFunction(...args);
          
          // Compare results
          expect(optimizedResult).toEqual(originalResult);
        });
      });
    });
    """
  end
  
  # Generate benchmark file using Benchmark.js
  defp generate_benchmark_code do
    """
    /**
     * Benchmark file for comparing original and optimized implementations
     * 
     * This file uses Benchmark.js for performance testing.
     */
    
    const Benchmark = require('benchmark');
    const OriginalModule = require('./original.js');
    const OptimizedModule = require('./optimized.js');
    
    // Helper to generate fixed test values for consistent benchmarking
    function generateFixedValue(type) {
      switch(type) {
        case 'number': return 42;
        case 'string': return 'benchmark_test_value';
        case 'array': return [1, 2, 3, 4, 5];
        case 'object': return {a: 1, b: 'test'};
        case 'boolean': return true;
        default: return 42;
      }
    }
    
    // Get all functions in the original module
    const functions = Object.keys(OriginalModule).filter(
      key => typeof OriginalModule[key] === 'function'
    );
    
    // Results container
    const results = {
      original: {},
      optimized: {},
      improvements: {}
    };
    
    // For each function, create a benchmark
    functions.forEach(functionName => {
      // Get the functions
      const originalFunction = OriginalModule[functionName];
      const optimizedFunction = OptimizedModule[functionName];
      
      // Skip non-function properties
      if (typeof originalFunction !== 'function') return;
      
      // Get the parameter count
      const paramCount = originalFunction.length;
      
      // Generate fixed arguments
      const args = Array.from({length: paramCount}, (_, i) => {
        const types = ['number', 'string', 'array', 'object', 'boolean'];
        return generateFixedValue(types[i % types.length]);
      });
      
      // Create a benchmark suite for this function
      const suite = new Benchmark.Suite();
      
      // Add the original implementation
      suite.add(`Original ${functionName}`, function() {
        originalFunction(...args);
      });
      
      // Add the optimized implementation
      suite.add(`Optimized ${functionName}`, function() {
        optimizedFunction(...args);
      });
      
      // Add listeners
      suite
        .on('complete', function() {
          const originalBench = this[0];
          const optimizedBench = this[1];
          
          console.log(`Function ${functionName}:`);
          console.log(`  Original: ${Math.round(originalBench.hz)} ops/sec`);
          console.log(`  Optimized: ${Math.round(optimizedBench.hz)} ops/sec`);
          
          const improvement = ((optimizedBench.hz - originalBench.hz) / originalBench.hz) * 100;
          console.log(`  Improvement: ${improvement.toFixed(2)}%`);
          
          // Store results
          results.original[functionName] = {
            hz: originalBench.hz,
            stats: originalBench.stats
          };
          
          results.optimized[functionName] = {
            hz: optimizedBench.hz,
            stats: optimizedBench.stats
          };
          
          results.improvements[functionName] = improvement;
        })
        // Run the benchmark
        .run({ 'async': false });
    });
    
    // Calculate overall improvement
    const originalTotal = Object.values(results.original).reduce((sum, item) => sum + item.hz, 0);
    const optimizedTotal = Object.values(results.optimized).reduce((sum, item) => sum + item.hz, 0);
    const overallImprovement = ((optimizedTotal - originalTotal) / originalTotal) * 100;
    
    console.log('\\nOverall Performance:');
    console.log(`  Original total: ${Math.round(originalTotal)} ops/sec`);
    console.log(`  Optimized total: ${Math.round(optimizedTotal)} ops/sec`);
    console.log(`  Performance improvement: ${overallImprovement.toFixed(2)}%`);
    
    // Output results in a format the runner can parse
    console.log('\\nBENCHMARK_RESULTS:');
    console.log(JSON.stringify({
      original: { hz: originalTotal },
      optimized: { hz: optimizedTotal },
      improvement: overallImprovement
    }));
    console.log('END_BENCHMARK_RESULTS');
    """
  end
  
  # Generate package.json
  defp generate_package_json do
    """
    {
      "name": "ace-experiment",
      "version": "1.0.0",
      "description": "ACE code optimization experiment",
      "main": "index.js",
      "scripts": {
        "test": "jest",
        "benchmark": "node benchmark.js"
      },
      "dependencies": {
        "benchmark": "^2.1.4",
        "jest": "^27.5.1",
        "microtime": "^3.0.0"
      }
    }
    """
  end
end

defmodule Ace.Evaluation.Languages.Python do
  @moduledoc """
  Python-specific experiment implementation.
  """
  
  @doc """
  Creates an experiment for Python code.
  """
  def create_experiment(original_code, optimized_code) do
    # Create temporary directory for the experiment
    experiment_dir = create_experiment_dir()
    
    try do
      # Create module files
      original_file = Path.join(experiment_dir, "original.py")
      optimized_file = Path.join(experiment_dir, "optimized.py")
      
      # Write the files with properly wrapped code
      File.write!(original_file, wrap_in_module("original_module", original_code))
      File.write!(optimized_file, wrap_in_module("optimized_module", optimized_code))
      
      # Create test file
      test_file = Path.join(experiment_dir, "test_experiment.py")
      test_code = generate_test_code()
      File.write!(test_file, test_code)
      
      # Create benchmark file
      bench_file = Path.join(experiment_dir, "benchmark.py")
      bench_code = generate_benchmark_code()
      File.write!(bench_file, bench_code)
      
      # Create requirements.txt for dependencies
      requirements_file = Path.join(experiment_dir, "requirements.txt")
      requirements_content = generate_requirements()
      File.write!(requirements_file, requirements_content)
      
      # Create README with instructions
      readme_file = Path.join(experiment_dir, "README.md")
      readme_content = generate_readme()
      File.write!(readme_file, readme_content)
      
      {:ok, %{
        dir: experiment_dir,
        original_file: original_file,
        optimized_file: optimized_file,
        test_file: test_file,
        bench_file: bench_file
      }}
    rescue
      e ->
        # Clean up on error
        File.rm_rf(experiment_dir)
        {:error, "Failed to create Python experiment: #{Exception.message(e)}"}
    end
  end
  
  # Create a unique experiment directory
  defp create_experiment_dir do
    base_dir = System.tmp_dir!()
    timestamp = DateTime.utc_now() |> DateTime.to_unix()
    random_suffix = :crypto.strong_rand_bytes(4) |> Base.encode16(case: :lower)
    experiment_dir = Path.join(base_dir, "ace_py_experiment_#{timestamp}_#{random_suffix}")
    
    File.mkdir_p!(experiment_dir)
    experiment_dir
  end
  
  # Wrap Python code in a module structure
  defp wrap_in_module(module_name, code) do
    """
    #!/usr/bin/env python3
    # -*- coding: utf-8 -*-
    
    \"\"\"
    #{module_name} - Code under test
    
    This file was auto-generated by the ACE experiment factory.
    \"\"\"
    
    import time
    import sys
    
    #{code}
    
    # Automatically detect and expose functions
    # This allows the test code to dynamically discover functions
    __all__ = [name for name, obj in locals().items() 
               if callable(obj) and not name.startswith('_')]
    
    if __name__ == "__main__":
        # Code that runs when the file is executed directly
        pass
    """
  end
  
  # Generate pytest test file
  defp generate_test_code do
    """
    #!/usr/bin/env python3
    # -*- coding: utf-8 -*-
    
    \"\"\"
    Test file for comparing original and optimized implementations
    
    This file uses pytest for testing.
    \"\"\"
    
    import pytest
    import inspect
    import random
    import string
    import original_module
    import optimized_module
    
    # Generate test values for different types
    def generate_test_value(param_type):
        if param_type == int:
            return random.randint(1, 100)
        elif param_type == float:
            return random.uniform(1.0, 100.0)
        elif param_type == str:
            return ''.join(random.choices(string.ascii_letters, k=random.randint(5, 10)))
        elif param_type == list:
            return [random.randint(1, 100) for _ in range(5)]
        elif param_type == dict:
            return {f'key{i}': random.randint(1, 100) for i in range(5)}
        elif param_type == bool:
            return random.choice([True, False])
        else:
            return None
    
    # Get all functions from the original module
    original_functions = {name: func for name, func in inspect.getmembers(original_module, inspect.isfunction)
                          if name in original_module.__all__}
    
    # For each function, create a test case
    @pytest.mark.parametrize("func_name", original_functions.keys())
    def test_function_equivalence(func_name):
        # Get the functions from both modules
        original_func = getattr(original_module, func_name)
        optimized_func = getattr(optimized_module, func_name)
        
        # Skip if the function doesn't exist in optimized module
        if not hasattr(optimized_module, func_name):
            pytest.skip(f"Function {func_name} not found in optimized module")
        
        # Get signature to determine parameter types and defaults
        sig = inspect.signature(original_func)
        
        # Generate arguments based on parameter types
        args = []
        for param_name, param in sig.parameters.items():
            # Try to infer type from default value or annotation
            param_type = None
            if param.annotation != inspect.Parameter.empty:
                param_type = param.annotation
            elif param.default != inspect.Parameter.empty:
                param_type = type(param.default)
            else:
                # Default to int if can't determine
                param_type = random.choice([int, float, str, list, dict, bool])
            
            # Generate value based on type
            args.append(generate_test_value(param_type))
        
        # Call both implementations with the same arguments
        original_result = original_func(*args)
        optimized_result = optimized_func(*args)
        
        # Compare results
        assert optimized_result == original_result, f"Results differ for {func_name}: original={original_result}, optimized={optimized_result}"
    """
  end
  
  # Generate benchmark code
  defp generate_benchmark_code do
    """
    #!/usr/bin/env python3
    # -*- coding: utf-8 -*-
    
    \"\"\"
    Benchmark file for comparing original and optimized implementations
    
    This file uses timeit for performance testing.
    \"\"\"
    
    import timeit
    import inspect
    import json
    import time
    import sys
    
    import original_module
    import optimized_module
    
    # Generate fixed test values for consistent benchmarking
    def generate_fixed_value(value_type):
        if value_type == int:
            return 42
        elif value_type == float:
            return 3.14159
        elif value_type == str:
            return "benchmark_test_string"
        elif value_type == list:
            return [1, 2, 3, 4, 5]
        elif value_type == dict:
            return {"a": 1, "b": 2, "c": 3}
        elif value_type == bool:
            return True
        else:
            return None
    
    # Get all functions from the original module
    original_functions = {name: func for name, func in inspect.getmembers(original_module, inspect.isfunction)
                          if name in original_module.__all__}
    
    # Results container
    results = {
        "original": {},
        "optimized": {},
        "improvements": {}
    }
    
    # Number of iterations for timing
    ITERATIONS = 100000
    
    # For each function, create a benchmark
    for func_name, original_func in original_functions.items():
        print(f"Benchmarking {func_name}...")
        
        # Skip if the function doesn't exist in optimized module
        if not hasattr(optimized_module, func_name):
            print(f"  Function {func_name} not found in optimized module")
            continue
        
        optimized_func = getattr(optimized_module, func_name)
        
        # Get signature to determine parameter types and defaults
        sig = inspect.signature(original_func)
        
        # Generate arguments based on parameter types
        args = []
        for param_name, param in sig.parameters.items():
            # Try to infer type from default value or annotation
            param_type = None
            if param.annotation != inspect.Parameter.empty:
                param_type = param.annotation
            elif param.default != inspect.Parameter.empty:
                param_type = type(param.default)
            else:
                # Default to int if can't determine
                param_type = int
            
            # Generate value based on type
            args.append(generate_fixed_value(param_type))
        
        # Setup code for timeit
        setup_code = f'''
        import original_module
        import optimized_module
        args = {args}
        '''
        
        # Time original implementation
        original_stmt = f"original_module.{func_name}(*args)"
        try:
            original_time = timeit.timeit(stmt=original_stmt, setup=setup_code, number=ITERATIONS)
            results["original"][func_name] = original_time
            print(f"  Original: {original_time:.6f} seconds")
        except Exception as e:
            print(f"  Original function error: {e}")
            continue
        
        # Time optimized implementation
        optimized_stmt = f"optimized_module.{func_name}(*args)"
        try:
            optimized_time = timeit.timeit(stmt=optimized_stmt, setup=setup_code, number=ITERATIONS)
            results["optimized"][func_name] = optimized_time
            print(f"  Optimized: {optimized_time:.6f} seconds")
        except Exception as e:
            print(f"  Optimized function error: {e}")
            continue
        
        # Calculate improvement
        if original_time > 0:
            improvement = ((original_time - optimized_time) / original_time) * 100
            results["improvements"][func_name] = improvement
            print(f"  Improvement: {improvement:.2f}%")
        else:
            results["improvements"][func_name] = 0
            print("  No improvement (original time too small)")
    
    # Calculate overall improvement
    original_total = sum(results["original"].values())
    optimized_total = sum(results["optimized"].values())
    
    if original_total > 0:
        overall_improvement = ((original_total - optimized_total) / original_total) * 100
    else:
        overall_improvement = 0
    
    print("\\nOverall Performance:")
    print(f"  Original total: {original_total:.6f} seconds")
    print(f"  Optimized total: {optimized_total:.6f} seconds")
    print(f"  Performance improvement: {overall_improvement:.2f}%")
    
    # Output results in a format the ACE runner can parse
    print("\\nBENCHMARK_RESULTS:")
    result_json = json.dumps({
        "original": {"time": original_total, "hz": 1.0/original_total if original_total > 0 else 0},
        "optimized": {"time": optimized_total, "hz": 1.0/optimized_total if optimized_total > 0 else 0},
        "improvement": overall_improvement
    })
    print(result_json)
    print("END_BENCHMARK_RESULTS")
    """
  end
  
  # Generate requirements.txt for Python dependencies
  defp generate_requirements do
    """
    pytest==7.3.1
    pytest-benchmark==4.0.0
    """
  end
  
  # Generate README with instructions
  defp generate_readme do
    """
    # ACE Python Experiment
    
    This directory contains a Python experiment generated by ACE (Adaptive Code Evolution).
    
    ## Files
    
    - `original.py` - Original code implementation
    - `optimized.py` - Optimized code implementation
    - `test_experiment.py` - Test file to verify correctness
    - `benchmark.py` - Benchmark file to measure performance
    - `requirements.txt` - Python dependencies
    
    ## Running Tests
    
    ```bash
    # Install dependencies
    pip install -r requirements.txt
    
    # Run tests
    pytest test_experiment.py -v
    ```
    
    ## Running Benchmarks
    
    ```bash
    python benchmark.py
    ```
    
    The benchmark will output performance metrics for each function and an overall improvement percentage.
    """
  end
end

defmodule Ace.Evaluation.Languages.Ruby do
  @moduledoc """
  Ruby-specific experiment implementation.
  """
  
  @doc """
  Creates an experiment for Ruby code.
  """
  def create_experiment(_original_code, _optimized_code) do
    # Basic implementation for Ruby experiments
    # In a real implementation, this would create Ruby files and scripts
    {:error, "Ruby experiments not yet implemented"}
  end
end

defmodule Ace.Evaluation.Languages.Go do
  @moduledoc """
  Go-specific experiment implementation.
  """
  
  @doc """
  Creates an experiment for Go code.
  """
  def create_experiment(_original_code, _optimized_code) do
    # Basic implementation for Go experiments
    # In a real implementation, this would create Go files and scripts
    {:error, "Go experiments not yet implemented"}
  end
end

defmodule Ace.Evaluation.Languages.Generic do
  @moduledoc """
  Generic experiment implementation for unsupported languages.
  """
  
  @doc """
  Creates a basic experiment for unsupported languages.
  """
  def create_experiment(original_code, optimized_code) do
    # Create temporary directory for the experiment
    experiment_dir = Path.join(System.tmp_dir!(), "ace_experiment_generic_#{:os.system_time(:seconds)}")
    File.mkdir_p!(experiment_dir)
    
    # Store original and optimized code for manual inspection
    original_file = Path.join(experiment_dir, "original.txt")
    optimized_file = Path.join(experiment_dir, "optimized.txt")
    
    File.write!(original_file, original_code)
    File.write!(optimized_file, optimized_code)
    
    # For generic languages, we'll just do a basic size comparison
    original_size = byte_size(original_code)
    optimized_size = byte_size(optimized_code)
    size_change_percent = ((optimized_size - original_size) / original_size) * 100
    
    # Create a report file
    report_file = Path.join(experiment_dir, "report.txt")
    report = """
    Generic Code Evaluation
    ======================
    
    Original code size: #{original_size} bytes
    Optimized code size: #{optimized_size} bytes
    Size change: #{Float.round(size_change_percent, 2)}%
    
    Note: This is a generic evaluation for an unsupported language.
    Only basic size metrics are available. For more detailed analysis,
    implement a language-specific evaluation module.
    """
    
    File.write!(report_file, report)
    
    {:ok, %{
      dir: experiment_dir,
      original_file: original_file,
      optimized_file: optimized_file,
      report_file: report_file,
      metrics: %{
        original_size: original_size,
        optimized_size: optimized_size,
        size_change_percent: size_change_percent
      }
    }}
  end
end