#!/bin/bash
# Deployment script for ACE (Adaptive Code Evolution)
# This script sets up the environment and deploys ACE

set -e  # Exit on any error

# Print colorful messages
print_info() {
  echo -e "\033[0;34m[INFO]\033[0m $1"
}

print_success() {
  echo -e "\033[0;32m[SUCCESS]\033[0m $1"
}

print_error() {
  echo -e "\033[0;31m[ERROR]\033[0m $1"
}

print_warning() {
  echo -e "\033[0;33m[WARNING]\033[0m $1"
}

# Check if Docker is installed
check_docker() {
  if ! command -v docker &> /dev/null; then
    print_error "Docker is not installed. Please install Docker before continuing."
    exit 1
  fi

  if ! command -v docker-compose &> /dev/null; then
    print_error "Docker Compose is not installed. Please install Docker Compose before continuing."
    exit 1
  fi
  
  print_success "Docker and Docker Compose are installed."
}

# Check for required environment variables
check_env_vars() {
  ENV_FILE=".env"
  
  # Create .env file if it doesn't exist
  if [ ! -f "$ENV_FILE" ]; then
    touch "$ENV_FILE"
  fi
  
  # Check for API keys
  if [ -z "$GROQ_API_KEY" ] && ! grep -q "GROQ_API_KEY" "$ENV_FILE"; then
    print_warning "GROQ_API_KEY environment variable is not set."
    read -p "Would you like to set it now? (y/n): " RESP
    if [[ "$RESP" == "y" ]]; then
      read -p "Enter your Groq API key: " API_KEY
      echo "GROQ_API_KEY=$API_KEY" >> "$ENV_FILE"
      print_success "GROQ_API_KEY added to $ENV_FILE"
    else
      print_warning "No GROQ_API_KEY provided. ACE will run in mock mode."
    fi
  else
    if [ -n "$GROQ_API_KEY" ]; then
      print_success "GROQ_API_KEY found in environment."
    else
      print_success "GROQ_API_KEY found in $ENV_FILE."
    fi
  fi
  
  # Check for other API keys if needed
  if ! grep -q "GROQ_API_KEY" "$ENV_FILE" && ! grep -q "OPENAI_API_KEY" "$ENV_FILE" && ! grep -q "ANTHROPIC_API_KEY" "$ENV_FILE" && [ -z "$GROQ_API_KEY" ] && [ -z "$OPENAI_API_KEY" ] && [ -z "$ANTHROPIC_API_KEY" ]; then
    print_warning "No API keys found. ACE will run in mock mode."
  fi
  
  # Add other environment variables if needed
  if ! grep -q "ACE_LLM_PROVIDER" "$ENV_FILE"; then
    if grep -q "GROQ_API_KEY" "$ENV_FILE" || [ -n "$GROQ_API_KEY" ]; then
      echo "ACE_LLM_PROVIDER=groq" >> "$ENV_FILE"
    elif grep -q "OPENAI_API_KEY" "$ENV_FILE" || [ -n "$OPENAI_API_KEY" ]; then
      echo "ACE_LLM_PROVIDER=openai" >> "$ENV_FILE"
    elif grep -q "ANTHROPIC_API_KEY" "$ENV_FILE" || [ -n "$ANTHROPIC_API_KEY" ]; then
      echo "ACE_LLM_PROVIDER=anthropic" >> "$ENV_FILE"
    else
      echo "ACE_LLM_PROVIDER=mock" >> "$ENV_FILE"
    fi
  fi
}

# Update docker-compose.yml file
update_docker_compose() {
  print_info "Updating docker-compose.yml..."
  
  # Uncomment environment variables
  sed -i.bak 's/# - GROQ_API_KEY=\${GROQ_API_KEY}/- GROQ_API_KEY=\${GROQ_API_KEY}/g' docker-compose.yml
  sed -i.bak 's/# - ACE_LLM_PROVIDER=groq/- ACE_LLM_PROVIDER=\${ACE_LLM_PROVIDER:-groq}/g' docker-compose.yml
  
  # Clean up backup file
  rm -f docker-compose.yml.bak
  
  print_success "docker-compose.yml updated."
}

# Deploy ACE
deploy_ace() {
  print_info "Deploying ACE..."
  
  # Stop existing containers if they exist
  docker-compose down 2>/dev/null || true
  
  # Start the database first
  print_info "Starting database..."
  docker-compose up -d db
  
  # Wait for database to initialize
  print_info "Waiting for database to initialize..."
  sleep 10
  
  # Start the application
  print_info "Starting application..."
  # Make sure DATABASE_URL is properly set for Docker networking
  export DATABASE_URL=ecto://postgres:postgres@db/ace_dev
  docker-compose up -d app
  
  # Set up the database
  print_info "Setting up the database..."
  docker exec ace_standalone-app-1 mix ecto.setup
  
  print_success "ACE deployed successfully!"
  print_info "Dashboard available at: http://localhost:4000"
}

# Main deployment process
main() {
  print_info "Starting ACE deployment process..."
  
  # Check requirements
  check_docker
  check_env_vars
  update_docker_compose
  
  # Deploy
  deploy_ace
  
  print_info "Deployment completed!"
}

# Run the main function
main