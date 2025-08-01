#!/bin/bash

# Configuration
APP_NAME="nextjs-app"
APP_DIR="$(cd "$(dirname "$0")" && pwd)"
PID_FILE=".nextjs.pid"
LOG_FILE=".nextjs.log"
PORT=3000
NODE_CMD="pnpm dev"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to find process using port
find_pid_by_port() {
    # Try lsof first (more reliable)
    if command -v lsof >/dev/null 2>&1; then
        lsof -ti:$PORT 2>/dev/null
    # Fall back to netstat
    elif command -v netstat >/dev/null 2>&1; then
        netstat -tlnp 2>/dev/null | grep ":$PORT " | awk '{print $7}' | cut -d'/' -f1
    fi
}

# Function to check if process is running
is_running() {
    local pid=$1
    [ -n "$pid" ] && kill -0 "$pid" 2>/dev/null
}

# Start function
start() {
    echo -e "${YELLOW}Starting $APP_NAME...${NC}"
    
    # Check if something is already running on the port
    EXISTING_PID=$(find_pid_by_port)
    if [ -n "$EXISTING_PID" ]; then
        echo -e "${YELLOW}Port $PORT is already in use by process $EXISTING_PID${NC}"
        
        # Save the PID for future reference
        echo $EXISTING_PID > $PID_FILE
        echo -e "${GREEN}Saved PID to $PID_FILE${NC}"
        return 1
    fi
    
    # Check if we have a PID file and if that process is running
    if [ -f "$PID_FILE" ]; then
        PID=$(cat $PID_FILE)
        if is_running $PID; then
            echo -e "${YELLOW}$APP_NAME is already running (PID: $PID)${NC}"
            return 1
        else
            # Clean up stale PID file
            rm -f $PID_FILE
        fi
    fi
    
    # Start the server
    cd "$APP_DIR"
    nohup $NODE_CMD > "$LOG_FILE" 2>&1 &
    PID=$!
    echo $PID > $PID_FILE
    
    # Wait for server to start (check for up to 15 seconds)
    echo -n "Waiting for server to start"
    for i in {1..15}; do
        if grep -q "Ready in\|Local:" "$LOG_FILE" 2>/dev/null; then
            echo ""
            echo -e "${GREEN}$APP_NAME started successfully (PID: $PID)${NC}"
            echo -e "${GREEN}Server running at: http://localhost:$PORT${NC}"
            echo -e "${GREEN}View logs: $0 logs${NC}"
            return 0
        fi
        
        # Check if process died
        if ! is_running $PID; then
            echo ""
            echo -e "${RED}Server process died unexpectedly${NC}"
            echo -e "${RED}Check logs: $0 logs${NC}"
            rm -f $PID_FILE
            return 1
        fi
        
        printf "."
        sleep 1
    done
    
    echo ""
    echo -e "${YELLOW}Server started but may still be initializing${NC}"
    echo -e "${YELLOW}Check logs: $0 logs${NC}"
}

# Stop function
stop() {
    echo -e "${YELLOW}Stopping $APP_NAME...${NC}"
    
    # Try to get PID from file first
    if [ -f "$PID_FILE" ]; then
        PID=$(cat $PID_FILE)
    else
        # Try to find by port
        PID=$(find_pid_by_port)
        if [ -z "$PID" ]; then
            echo -e "${YELLOW}No server found running on port $PORT${NC}"
            return 1
        fi
        echo -e "${YELLOW}Found server on port $PORT (PID: $PID)${NC}"
    fi
    
    # Stop the process
    if is_running $PID; then
        kill $PID 2>/dev/null
        
        # Wait for graceful shutdown (up to 5 seconds)
        for i in {1..5}; do
            if ! is_running $PID; then
                echo -e "${GREEN}$APP_NAME stopped successfully${NC}"
                rm -f $PID_FILE
                return 0
            fi
            sleep 1
        done
        
        # Force kill if still running
        echo -e "${YELLOW}Force stopping...${NC}"
        kill -9 $PID 2>/dev/null
        rm -f $PID_FILE
        echo -e "${GREEN}$APP_NAME force stopped${NC}"
    else
        echo -e "${YELLOW}Process $PID is not running${NC}"
        rm -f $PID_FILE
    fi
}

# Restart function
restart() {
    echo -e "${YELLOW}Restarting $APP_NAME...${NC}"
    stop
    sleep 2
    start
}

# Status function
status() {
    # Check PID file first
    if [ -f "$PID_FILE" ]; then
        PID=$(cat $PID_FILE)
        if is_running $PID; then
            echo -e "${GREEN}$APP_NAME is running${NC}"
            echo -e "  PID: $PID"
            echo -e "  Port: $PORT"
            echo -e "  PID file: $PID_FILE"
            echo -e "  Log file: $LOG_FILE"
            
            # Show process info
            echo -e "\nProcess info:"
            ps -p $PID -o pid,vsz,rss,comm,etime --no-headers
            return 0
        else
            echo -e "${YELLOW}PID file exists but process is not running${NC}"
            rm -f $PID_FILE
        fi
    fi
    
    # Check by port
    PID=$(find_pid_by_port)
    if [ -n "$PID" ]; then
        echo -e "${GREEN}$APP_NAME is running on port $PORT${NC}"
        echo -e "  PID: $PID (no PID file)"
        echo -e "  Port: $PORT"
        echo -e "\nProcess info:"
        ps -p $PID -o pid,vsz,rss,comm,etime --no-headers 2>/dev/null || echo "  Unable to get process details"
    else
        echo -e "${RED}$APP_NAME is not running${NC}"
    fi
}

# Logs function
logs() {
    if [ ! -f "$LOG_FILE" ]; then
        echo -e "${YELLOW}No log file found at $LOG_FILE${NC}"
        return 1
    fi
    
    echo -e "${GREEN}Showing logs from $LOG_FILE${NC}"
    echo -e "${GREEN}Press Ctrl+C to stop${NC}"
    echo "----------------------------------------"
    tail -f "$LOG_FILE"
}

# Main switch
case "$1" in
    start)
        start
        ;;
    stop)
        stop
        ;;
    restart)
        restart
        ;;
    status)
        status
        ;;
    logs)
        logs
        ;;
    *)
        echo "Usage: $0 {start|stop|restart|status|logs}"
        echo ""
        echo "Commands:"
        echo "  start   - Start the development server"
        echo "  stop    - Stop the development server"
        echo "  restart - Restart the development server"
        echo "  status  - Show server status"
        echo "  logs    - Tail the server logs"
        exit 1
        ;;
esac

exit 0