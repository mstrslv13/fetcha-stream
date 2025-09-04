#!/bin/bash

# Process monitoring script for yt-dlp-MAX testing

echo "==================================="
echo "yt-dlp-MAX Process Monitor"
echo "==================================="
echo ""

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to count yt-dlp processes
count_processes() {
    ps aux | grep -E "yt-dlp|Python.*yt-dlp" | grep -v grep | wc -l | tr -d ' '
}

# Function to show process details
show_processes() {
    ps aux | grep -E "yt-dlp" | grep -v grep | awk '{printf "PID: %5s CPU: %5s%% MEM: %5s%% CMD: %.50s...\n", $2, $3, $4, $11}'
}

# Initial state
echo "Starting process monitoring..."
echo "Press Ctrl+C to stop"
echo ""

# Main monitoring loop
while true; do
    clear
    echo "==================================="
    echo "yt-dlp-MAX Process Monitor"
    echo "$(date '+%Y-%m-%d %H:%M:%S')"
    echo "==================================="
    echo ""
    
    COUNT=$(count_processes)
    
    if [ "$COUNT" -eq 0 ]; then
        echo -e "${GREEN}✓ No yt-dlp processes running${NC}"
    elif [ "$COUNT" -le 3 ]; then
        echo -e "${YELLOW}⚡ $COUNT yt-dlp process(es) running (normal)${NC}"
    else
        echo -e "${RED}⚠ WARNING: $COUNT yt-dlp processes running!${NC}"
    fi
    
    echo ""
    echo "Active Processes:"
    echo "-----------------"
    
    if [ "$COUNT" -gt 0 ]; then
        show_processes
    else
        echo "None"
    fi
    
    echo ""
    echo "System Stats:"
    echo "-----------------"
    
    # CPU usage
    CPU_USAGE=$(ps aux | grep -E "yt-dlp|Python.*yt-dlp" | grep -v grep | awk '{sum+=$3} END {printf "%.1f", sum}')
    if [ -z "$CPU_USAGE" ]; then
        CPU_USAGE="0.0"
    fi
    echo "Total CPU Usage by yt-dlp: ${CPU_USAGE}%"
    
    # Memory usage
    MEM_USAGE=$(ps aux | grep -E "yt-dlp|Python.*yt-dlp" | grep -v grep | awk '{sum+=$4} END {printf "%.1f", sum}')
    if [ -z "$MEM_USAGE" ]; then
        MEM_USAGE="0.0"
    fi
    echo "Total Memory Usage by yt-dlp: ${MEM_USAGE}%"
    
    # Check for zombie processes
    ZOMBIES=$(ps aux | grep -E "yt-dlp.*<defunct>" | wc -l | tr -d ' ')
    if [ "$ZOMBIES" -gt 0 ]; then
        echo -e "${RED}⚠ Zombie processes detected: $ZOMBIES${NC}"
    fi
    
    sleep 1
done