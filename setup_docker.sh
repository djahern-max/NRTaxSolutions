#!/bin/bash

# Set text colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}========================================================"
echo -e "       Setting up Docker for RyzeNRTax"
echo -e "========================================================${NC}"

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo -e "${RED}Error: Docker is not installed.${NC}"
    echo -e "Please install Docker before running this script."
    exit 1
fi

if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}Error: Docker Compose is not installed.${NC}"
    echo -e "Please install Docker Compose before running this script."
    exit 1
fi

# Create Docker files
echo -e "\n${YELLOW}Creating Docker files...${NC}"

# Create Backend Dockerfile
cat > backend/Dockerfile << 'EOFDOCKERBACKEND'
FROM python:3.9

WORKDIR /app

COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY . .

CMD ["uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8000"]
EOFDOCKERBACKEND

# Create Frontend Dockerfile
cat > frontend/Dockerfile << 'EOFDOCKERFRONTEND'
FROM node:14

WORKDIR /app

COPY package*.json ./
RUN npm install

COPY . .

EXPOSE 3000

CMD ["npm", "start"]
EOFDOCKERFRONTEND

# Create docker-compose.yml
cat > docker-compose.yml << 'EOFDOCKERCOMPOSE'
version: '3.8'

services:
  db:
    image: postgres:13
    volumes:
      - postgres_data:/var/lib/postgresql/data/
    environment:
      - POSTGRES_USER=postgres
      - POSTGRES_PASSWORD=postgres
      - POSTGRES_DB=ryze_nrtax_db
    ports:
      - "5432:5432"

  backend:
    build: ./backend
    command: uvicorn app.main:app --host 0.0.0.0 --port 8000
    volumes:
      - ./backend:/app
    ports:
      - "8000:8000"
    depends_on:
      - db
    environment:
      - DATABASE_URL=postgresql://postgres:postgres@db/ryze_nrtax_db

  frontend:
    build: ./frontend
    volumes:
      - ./frontend:/app
      - /app/node_modules
    ports:
      - "3000:3000"
    stdin_open: true
    depends_on:
      - backend

volumes:
  postgres_data:
EOFDOCKERCOMPOSE

echo -e "\n${GREEN}Docker setup completed successfully!${NC}"
echo -e "You can start the application using Docker with the command:"
echo -e "${YELLOW}docker-compose up -d${NC}"