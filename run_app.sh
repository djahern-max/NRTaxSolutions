#!/bin/bash

# Set text colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================================"
echo -e "       Starting RyzeNRTax Application"
echo -e "========================================================${NC}"

# Check if the backend and frontend directories exist
if [ ! -d "backend" ] || [ ! -d "frontend" ]; then
    echo -e "${RED}Error: Could not find backend or frontend directories.${NC}"
    echo -e "Please run the setup scripts first."
    exit 1
fi

# Start backend server
echo -e "\n${YELLOW}Starting backend server...${NC}"
cd backend || exit
source venv/bin/activate
echo -e "Initializing database..."
python app/db/init_db.py
echo -e "Starting FastAPI server..."
nohup uvicorn app.main:app --reload --host 0.0.0.0 --port 8000 > backend.log 2>&1 &
BACKEND_PID=$!
echo -e "Backend server started with PID: $BACKEND_PID"
cd ..

# Start frontend development server
echo -e "\n${YELLOW}Starting frontend development server...${NC}"
cd frontend || exit
nohup npm start > frontend.log 2>&1 &
FRONTEND_PID=$!
echo -e "Frontend development server started with PID: $FRONTEND_PID"
cd ..

echo -e "\n${GREEN}RyzeNRTax application is now running!${NC}"
echo -e "Backend: http://localhost:8000"
echo -e "Frontend: http://localhost:3000"
echo -e "API Documentation: http://localhost:8000/docs"
echo -e ""
echo -e "Press Ctrl+C to stop the servers."

# Create a file to store the PIDs
echo "$BACKEND_PID $FRONTEND_PID" > .app_pids

# Setup signal handler
trap cleanup INT

cleanup() {
    echo -e "\n${YELLOW}Stopping servers...${NC}"
    if [ -f .app_pids ]; then
        read -r BACKEND_PID FRONTEND_PID < .app_pids
        kill $BACKEND_PID $FRONTEND_PID 2>/dev/null
        rm .app_pids
    fi
    echo -e "${GREEN}Application stopped.${NC}"
    exit 0
}

# Keep the script running
while true; do
    sleep 1
done