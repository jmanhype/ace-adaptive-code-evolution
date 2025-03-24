#!/bin/bash

# Source environment variables from .env file
if [ -f .env ]; then
  set -a
  source .env
  set +a
  echo "Loaded environment variables from .env"
else
  echo "Warning: .env file not found. Please create it with your GitHub App configuration."
fi

# Start Phoenix server
echo "Starting Phoenix server with GitHub App configuration..."
mix phx.server 