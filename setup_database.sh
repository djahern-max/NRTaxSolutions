#!/bin/bash

# Set text colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================================"
echo -e "       Setting up NR Tax Solutions Database"
echo -e "========================================================${NC}"

# Check if PostgreSQL is installed
if ! command -v psql &> /dev/null; then
    echo -e "${RED}Error: PostgreSQL is not installed or not in PATH.${NC}"
    echo -e "Please install PostgreSQL before running this script."
    exit 1
fi

# Check PostgreSQL connection
echo -e "\n${YELLOW}Checking PostgreSQL connection...${NC}"
if ! psql -c "SELECT 1" postgres &> /dev/null; then
    echo -e "${RED}Error: Could not connect to PostgreSQL server.${NC}"
    echo -e "Please make sure the PostgreSQL server is running."
    exit 1
fi

# Create database
echo -e "\n${YELLOW}Creating database...${NC}"
if psql -lqt | cut -d \| -f 1 | grep -qw ryze_nrtax_db; then
    read -p "Database 'ryze_nrtax_db' already exists. Do you want to drop and recreate it? (y/n) " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "Dropping existing database..."
        dropdb ryze_nrtax_db
    else
        echo -e "${YELLOW}Using existing database.${NC}"
        exit 0
    fi
fi

echo "Creating database 'ryze_nrtax_db'..."
createdb ryze_nrtax_db

echo -e "\n${GREEN}Database setup completed successfully!${NC}"