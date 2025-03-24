#!/bin/bash

# ACE Code Cartography - Map Generation Script
# This script generates various code maps for the ACE project

echo "Generating ACE code maps..."
mkdir -p maps

# System Architecture Maps
echo "Creating system architecture maps..."
find lib -type d | sort > maps/directory_structure.txt
find lib -name "*.ex" | xargs grep -l "alias" | xargs grep "alias " | grep -v "# alias" | sort > maps/module_dependencies.txt
grep -r "scope \"/" lib/ace_web/router.ex > maps/route_map.txt
find lib -name "*.ex" -o -name "*.heex" | xargs grep -l "<.\\|<component" | xargs grep "<.\\|<component" | sort > maps/component_usage_map.txt
find priv/repo/migrations -name "*.exs" | xargs grep -l "create table" | xargs grep "create table" > maps/database_schema_map.txt

# Complexity & Size Maps
echo "Creating complexity and size maps..."
find . -type f -not -path "*/\.*" -not -path "*/deps/*" -not -path "*/_build/*" | xargs wc -l 2>/dev/null | sort -nr > maps/file_size_map.txt
find lib -name "*.ex" | xargs wc -l | sort -nr | head -50 > maps/complexity_heat_map.txt
find lib -name "*.ex" | xargs grep -l "def " | xargs grep "def " | grep -v defmodule | grep -v defmacro | sort > maps/function_map.txt

# Historical & Contribution Maps
echo "Creating historical and contribution maps..."
git shortlog -sn --all > maps/contributor_map.txt
git log --pretty=format: --name-only | sort | uniq -c | sort -rg | head -50 > maps/file_modification_frequency.txt
find lib -type f -name "*.ex" | xargs ls -lt | awk '{print $6, $7, $8, $9}' > maps/temporal_map.txt

# Documentation & Integration Maps
echo "Creating documentation and integration maps..."
find lib -name "*.ex" | xargs grep -l "@moduledoc" | sort > maps/modules_with_docs.txt
grep -r "GitHub" --include="*.ex" --include="*.exs" lib > maps/github_integration_map.txt
find test -name "*_test.exs" | xargs grep -l "test" | sort > maps/test_coverage_map.txt

# Visualization
echo "Creating visualization data..."
echo "digraph CodeMap {" > maps/visual_code_map.dot
echo "  // Main modules" >> maps/visual_code_map.dot
find lib/ace -maxdepth 1 -name "*.ex" | sed 's|^lib/\(.*\).ex$|  "\1" [shape=box, style=filled, fillcolor=lightblue];|' >> maps/visual_code_map.dot
echo "  // Module relationships" >> maps/visual_code_map.dot
find lib -name "*.ex" | xargs grep -l "alias" | xargs grep "alias " | grep -v "# alias" | sed 's/^.*alias //' | sed 's/, as:.*$//' | sort | uniq | sed 's|\([^ ]*\)\.\([^ ]*\)|  "\1" -> "\2";|' >> maps/visual_code_map.dot
echo "}" >> maps/visual_code_map.dot

echo "All code maps have been generated in the 'maps' directory."
echo "To generate a visual representation of the code map, install Graphviz and run:"
echo "  dot -Tpng maps/visual_code_map.dot -o maps/code_map.png" 