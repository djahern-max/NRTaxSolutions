# File Name: main_setup.sh
# Description: Main setup script for NR Tax Solutions application

#!/bin/bash

# NR Tax Solutions Application Setup Script
# This script automates the creation of the NR Tax Solutions application

# Set text colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Project configuration
PROJECT_NAME="ryze-nrtax"
PROJECT_DIR="./${PROJECT_NAME}"

# Error handling function
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}

# Display welcome message
echo -e "${GREEN}========================================================"
echo -e "       NR Tax Solutions Application Setup"
echo -e "========================================================${NC}"
echo ""
echo -e "This script will automate the creation of your ${PROJECT_NAME} application."
echo -e "It will set up both the backend and frontend components."
echo ""

# Check for required dependencies
echo -e "${YELLOW}Checking for required dependencies...${NC}"

# Function to check if a command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Check for Python
if command_exists python3; then
    python_cmd="python3"
elif command_exists python; then
    python_cmd="python"
else
    handle_error "Python is not installed. Please install Python 3.8 or higher."
fi

# Check Python version
python_version=$($python_cmd -c 'import sys; print(".".join(map(str, sys.version_info[:2])))') || handle_error "Failed to get Python version"
if (( $(echo "$python_version < 3.8" | bc -l) )); then
    handle_error "Python version 3.8 or higher is required. Found version $python_version"
fi
echo -e "Python version $python_version... ${GREEN}OK${NC}"

# Check for pip
if ! command_exists pip && ! command_exists pip3; then
    handle_error "pip is not installed. Please install pip."
fi
echo -e "pip... ${GREEN}OK${NC}"

# Check for node
if ! command_exists node; then
    handle_error "Node.js is not installed. Please install Node.js 14 or higher."
fi
# Check Node.js version
node_version=$(node -v | cut -d 'v' -f 2 | cut -d '.' -f 1) || handle_error "Failed to get Node.js version"
if (( node_version < 14 )); then
    handle_error "Node.js version 14 or higher is required. Found version $node_version"
fi
echo -e "Node.js... ${GREEN}OK${NC}"

# Check for npm
if ! command_exists npm; then
    handle_error "npm is not installed. Please install npm."
fi
echo -e "npm... ${GREEN}OK${NC}"

# Check for PostgreSQL
if ! command_exists psql; then
    echo -e "${YELLOW}Warning: PostgreSQL is not installed or not in PATH. The application requires PostgreSQL.${NC}"
    read -p "Do you want to continue without PostgreSQL? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        handle_error "Setup aborted. Please install PostgreSQL and try again."
    fi
else
    echo -e "PostgreSQL... ${GREEN}OK${NC}"
fi

# Create project directory
echo -e "\n${YELLOW}Setting up project directory...${NC}"
read -p "Enter the directory where you want to create the project (default: ${PROJECT_DIR}): " project_dir
project_dir=${project_dir:-$PROJECT_DIR}

# Check if directory exists
if [ -d "$project_dir" ]; then
    read -p "Directory $project_dir already exists. Do you want to overwrite it? (y/n) " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        handle_error "Setup aborted."
    fi
    rm -rf "$project_dir" || handle_error "Failed to remove existing directory"
fi

mkdir -p "$project_dir" || handle_error "Failed to create project directory"
cd "$project_dir" || handle_error "Failed to change to project directory"

# Generate individual scripts
echo -e "\n${YELLOW}Generating setup scripts...${NC}"

# Create the backend setup script
cat > setup_backend.sh << 'EOF'
#!/bin/bash

# Set text colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Error handling function
handle_error() {
    echo -e "${RED}Error: $1${NC}"
    exit 1
}
EOF