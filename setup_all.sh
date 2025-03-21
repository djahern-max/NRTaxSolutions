#!/bin/bash

# RyzeNRTax Setup All Script
# This script automates the complete setup of the RyzeNRTax application

# Set text colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================================"
echo -e "       RyzeNRTax Complete Setup"
echo -e "========================================================${NC}"

# Execute all setup scripts in order
echo -e "\n${YELLOW}Step 1: Setting up backend components...${NC}"
./setup_backend.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}Backend setup failed. Aborting.${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Step 2: Setting up frontend components...${NC}"
./setup_frontend.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}Frontend setup failed. Aborting.${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Step 3: Creating React page components...${NC}"
cd frontend
./create_page_components.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}Page components creation failed. Aborting.${NC}"
    exit 1
fi
cd ..

echo -e "\n${YELLOW}Step 4: Setting up database...${NC}"
./setup_database.sh
if [ $? -ne 0 ]; then
    echo -e "${RED}Database setup failed. Aborting.${NC}"
    exit 1
fi

# Ask if user wants to set up Docker
read -p "Do you want to set up Docker configuration for the application? (y/n) " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "\n${YELLOW}Setting up Docker configuration...${NC}"
    ./setup_docker.sh
    if [ $? -ne 0 ]; then
        echo -e "${RED}Docker setup failed.${NC}"
    fi
fi

echo -e "\n${GREEN}Complete setup successful!${NC}"
echo -e "You can now start the application by running:"
echo -e "${YELLOW}./run_app.sh${NC}"
echo -e "\nOr if you chose to use Docker:"
echo -e "${YELLOW}docker-compose up -d${NC}"