#!/bin/bash

# Set text colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${YELLOW}Stopping NR Tax Solutions application...${NC}"

if [ -f .app_pids ]; then
    read -r BACKEND_PID FRONTEND_PID < .app_pids
    echo -e "Stopping backend server (PID: $BACKEND_PID)..."
    kill $BACKEND_PID 2>/dev/null || echo -e "${RED}Backend server was not running.${NC}"
    
    echo -e "Stopping frontend server (PID: $FRONTEND_PID)..."
    kill $FRONTEND_PID 2>/dev/null || echo -e "${RED}Frontend server was not running.${NC}"
    
    rm .app_pids
    echo -e "${GREEN}Application stopped.${NC}"
else
    echo -e "${RED}No running application found.${NC}"
    echo -e "If the application is still running, you may need to manually kill the processes."
fi