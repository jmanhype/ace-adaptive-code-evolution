# ACE: Multi-File Analysis Guide

## Introduction

ACE provides powerful cross-file relationship analysis that enables it to identify optimization opportunities across file boundaries. This guide explains how to use the multi-file analysis features, understand the visualization of file relationships, and leverage these insights to improve your codebase.

## Table of Contents

1. [Why Multi-File Analysis](#why-multi-file-analysis)
2. [How Multi-File Analysis Works](#how-multi-file-analysis-works)
3. [Using the Command Line Interface](#using-the-command-line-interface)
4. [Using the Web Dashboard](#using-the-web-dashboard)
5. [Understanding File Relationships](#understanding-file-relationships)
6. [Cross-File Optimization Opportunities](#cross-file-optimization-opportunities)
7. [Relationship Visualization](#relationship-visualization)
8. [Practical Use Cases](#practical-use-cases)
9. [Tips and Best Practices](#tips-and-best-practices)
10. [Troubleshooting](#troubleshooting)

## Why Multi-File Analysis

Traditional code analysis tools typically focus on optimizing individual files in isolation. However, many codebases suffer from issues that span across multiple files, such as:

- Duplicated functionality across multiple modules
- Inconsistent API usage
- Circular dependencies
- Scattered related logic that should be consolidated
- Tight coupling between components that should be independent
- Inconsistent error handling across related modules

ACE's multi-file analysis addresses these challenges by analyzing relationships between files and identifying optimization opportunities that exist across file boundaries.

## How Multi-File Analysis Works

ACE's multi-file analysis operates in several stages:

1. **Individual File Analysis**: Each file is first analyzed independently to understand its structure, imports, exports, and internal logic.

2. **Relationship Detection**: ACE identifies relationships between files by analyzing:
   - Import/require statements
   - Inheritance/extension relationships
   - Interface implementations
   - Function/method calls between files
   - References to constants or types defined in other files

3. **Relationship Classification**: Detected relationships are classified by type:
   - `imports`: File imports/requires functionality from another file
   - `extends`: File extends/inherits from another file
   - `implements`: File implements an interface defined in another file
   - `uses`: File uses classes/functions from another file
   - `references`: File references constants or types from another file
   - `depends_on`: Generic dependency relationship

4. **Cross-File Analysis**: Using the relationship graph, ACE analyzes files in groups to detect patterns and issues that span across multiple files.

5. **Opportunity Generation**: ACE identifies cross-file optimization opportunities, with suggestions that may affect multiple files.

## Using the Command Line Interface

### Analyzing Multiple Files

To analyze multiple files as part of a project:

```bash
# Analyze specific files
ace analyze-project --files lib/module1.ex lib/module2.ex lib/module3.ex

# Analyze all files in a directory
ace analyze-project --dir ./lib --pattern "**/*.ex"

# Specify a project name
ace analyze-project --dir ./lib --name "My Project" --description "Project description"
```

### Options

```
--name              Project name (default: directory name)
--description       Project description (optional)
--focus-areas       Areas to focus on (default: performance,maintainability)
--severity-threshold Minimum severity to report (default: medium)
--detect-relationships Whether to detect relationships between files (default: true)
--format            Output format: text, json (default: text)
--output            Write results to a file instead of stdout
```

### Example Output

```
$ ace analyze-project --dir ./lib

Project: my_project
Base path: /path/to/lib
Files analyzed: 12
Relationships detected: 23
Cross-file opportunities: 4

File relationships graph:
  user.ex -> auth.ex (imports)
  user.ex -> profile.ex (references)
  auth.ex -> permissions.ex (uses)
  ...

Cross-file opportunities:
  1. [HIGH] Duplicated validation logic in user.ex and profile.ex
     - Suggestion: Extract shared validation to a common module
  
  2. [MEDIUM] Inconsistent error handling between auth.ex and permissions.ex
     - Suggestion: Standardize error handling approach
  
  ...
```

## Using the Web Dashboard

The ACE web dashboard provides an intuitive interface for multi-file analysis with powerful visualization capabilities.

### Starting the Dashboard

```bash
# Start the web dashboard
ace serve

# Access the dashboard in your browser
# http://localhost:4000
```

### Project Creation

1. Navigate to the "Analyze" tab
2. Click the toggle to enable "Multi-file Mode"
3. Add files to analyze using the file browser
4. Click "Create Project" and provide a name and description
5. Click "Run Analysis" to begin the multi-file analysis

### File Relationship Visualization

Once analysis is complete:

1. Navigate to the "Relationships" tab to view the file relationship graph
2. Each node represents a file, with edges representing relationships
3. Files are color-coded by language
4. Relationships are color-coded by type
5. Click on any node to see detailed information about that file's relationships

## Understanding File Relationships

ACE identifies and visualizes several types of relationships between files:

### Imports

The most common relationship, where one file imports or requires functionality from another.

Example (Elixir):
```elixir
# user.ex imports functionality from auth.ex
defmodule MyApp.User do
  import MyApp.Auth
  
  def authenticate(user, password) do
    validate_credentials(user, password)  # Function from Auth
  end
end
```

### Extends

One file contains a class/module that extends or inherits from a class/module in another file.

Example (JavaScript):
```javascript
// In component.js
export class Component {
  render() { /* ... */ }
}

// In button.js
import { Component } from './component';
export class Button extends Component {
  // ...
}
```

### Implements

One file contains a class/module that implements an interface defined in another file.

Example (TypeScript):
```typescript
// In interface.ts
export interface Logger {
  log(message: string): void;
}

// In file_logger.ts
import { Logger } from './interface';
export class FileLogger implements Logger {
  log(message: string) { /* ... */ }
}
```

### Uses

One file calls functions/methods or uses classes defined in another file (beyond simple imports).

### References

One file references constants, types, or other symbols defined in another file.

Example (Elixir):
```elixir
# In constants.ex
defmodule MyApp.Constants do
  @doc "Application-wide constants"
  def timeout, do: 30_000
end

# In http_client.ex
defmodule MyApp.HttpClient do
  def request(url) do
    # References a constant from another file
    HTTPoison.get(url, [], timeout: MyApp.Constants.timeout())
  end
end
```

### Depends On

A generic relationship indicating that one file depends on another.

## Cross-File Optimization Opportunities

ACE identifies several types of cross-file optimization opportunities:

### Duplicated Code

When similar or identical code appears in multiple files, ACE will suggest extracting it to a shared module.

Example opportunity:
```
[HIGH] Duplicated validation logic in user.ex and profile.ex
- Description: Similar email validation logic is duplicated across these files
- Suggestion: Extract shared validation to a common validation.ex module
```

### Inconsistent Patterns

When related files use inconsistent approaches to solve similar problems.

Example opportunity:
```
[MEDIUM] Inconsistent error handling between auth.ex and permissions.ex
- Description: auth.ex uses {:error, reason} tuples while permissions.ex raises exceptions
- Suggestion: Standardize error handling approach across authorization-related modules
```

### Circular Dependencies

When files directly or indirectly depend on each other, creating potential issues.

Example opportunity:
```
[HIGH] Circular dependency detected between order.ex and customer.ex
- Description: These files import each other, creating a circular dependency
- Suggestion: Extract shared functionality to a separate module to break the cycle
```

### Interface Violations

When a file doesn't properly implement an interface defined in another file.

### Tight Coupling

When files are too tightly coupled, making the codebase less maintainable.

## Relationship Visualization

The "Relationships" tab in the web dashboard provides a powerful visualization of file relationships:

### Graph View

The main visualization shows:
- **Nodes**: Each file as a colored node (color indicates language)
- **Edges**: Relationships between files as directional arrows (color indicates relationship type)
- **Labels**: File names and relationship types

### Interaction

- **Click a node**: Select a file to see its details
- **Hover over nodes/edges**: See additional information
- **Drag nodes**: Rearrange the visualization
- **Zoom/pan**: Navigate larger relationship graphs
- **Filter relationships**: Toggle visibility of specific relationship types

### Detail Panel

When a file is selected:

1. **File Information**:
   - File path
   - Language
   - Number of dependencies and dependents

2. **Dependencies**:
   - List of files this file depends on
   - Relationship type for each dependency
   - Click any file to navigate to it

3. **Dependents**:
   - List of files that depend on this file
   - Relationship type for each dependent
   - Click any file to navigate to it

4. **Cross-File Opportunities**:
   - Optimization opportunities involving this file
   - Severity and type of each opportunity
   - Click to see optimization details

## Practical Use Cases

### Refactoring Large Codebases

Multi-file analysis helps identify modules that should be split, merged, or refactored for better organization.

### Finding Architectural Issues

The relationship graph can reveal architectural problems like excessive coupling or unexpected dependencies.

### API Consistency

Identify inconsistent API usage across related modules that should follow the same patterns.

### Code Duplication Management

Find and eliminate duplicated logic across the codebase, improving maintainability.

### Dependency Management

Visualize and optimize the dependency structure of your codebase, reducing complexity.

## Tips and Best Practices

### Project Organization

Structure your project analysis around logical boundaries:

```bash
# Analyze each bounded context separately
ace analyze-project --dir ./lib/auth --name "Authentication"
ace analyze-project --dir ./lib/billing --name "Billing"
```

### Focus Areas

Customize focus areas for domain-specific analysis:

```bash
# Focus on maintainability and security for auth modules
ace analyze-project --dir ./lib/auth --focus-areas maintainability,security
```

### Incremental Improvement

1. Target high-severity cross-file issues first
2. Group related optimizations that should be applied together
3. Gradually improve the dependency structure

### Regular Analysis

Include multi-file analysis in your development workflow:

```bash
# Add to your CI/CD pipeline
stage "analyze" {
  command = "ace analyze-project --dir ./lib --output analysis.json"
}
```

## Troubleshooting

### Common Issues

#### No Relationships Detected

**Problem**: ACE doesn't detect relationships between files that you know are related.

**Solutions**:
- Verify file paths are correct and accessible
- Check that the language is supported for relationship detection 
- For dynamic languages, ensure imports/relationships are explicit
- Try using explicit relationship detection options

#### False Positives

**Problem**: ACE reports relationships that don't actually exist.

**Solutions**:
- Filter relationship types that are less relevant
- Focus analysis on smaller, more cohesive directories
- Update to the latest version of ACE

#### Large Codebases

**Problem**: Visualization becomes cluttered with too many files.

**Solutions**:
- Analyze smaller sub-projects instead of the entire codebase
- Use filtering options to focus on specific relationship types
- Adjust the project scope to focus on a specific area

### Getting Help

If you encounter issues not covered by this guide:

- Check the ACE documentation for updates
- Run `ace --help` for command-line options
- File an issue on GitHub with details about your environment and the specific problem