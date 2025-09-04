#!/bin/bash

echo "==================================="
echo "yt-dlp-MAX Operational Tests"
echo "==================================="
echo ""

# Test URLs (using short videos for quick testing)
VALID_URL="https://www.youtube.com/watch?v=aqz-KE-bpKQ"  # Big Buck Bunny trailer (30 seconds)
INVALID_URL="https://invalid-domain-that-doesnt-exist-12345.com/video"
SLOW_URL="https://httpstat.us/200?sleep=60000"  # Simulates slow response

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Helper functions
check_processes() {
    COUNT=$(ps aux | grep -E "yt-dlp" | grep -v grep | wc -l | tr -d ' ')
    echo "Active yt-dlp processes: $COUNT"
    return $COUNT
}

cleanup_check() {
    echo -n "Checking for cleanup... "
    sleep 2
    check_processes
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Clean!${NC}"
        return 0
    else
        echo -e "${RED}✗ Processes still running!${NC}"
        ps aux | grep -E "yt-dlp" | grep -v grep
        return 1
    fi
}

# Test 1: Basic functionality
test_basic() {
    echo -e "\n${YELLOW}Test 1: Basic Download and Cleanup${NC}"
    echo "--------------------------------------"
    echo "1. Open yt-dlp-MAX"
    echo "2. Paste this URL: $VALID_URL"
    echo "3. Download the video"
    echo "4. Wait for completion"
    echo ""
    read -p "Press Enter when download is complete..."
    
    cleanup_check
}

# Test 2: Timeout test
test_timeout() {
    echo -e "\n${YELLOW}Test 2: Timeout Handling${NC}"
    echo "--------------------------------------"
    echo "1. Paste this invalid URL: $INVALID_URL"
    echo "2. Try to download"
    echo "3. Wait for timeout (should fail quickly)"
    echo ""
    read -p "Press Enter when the download fails/times out..."
    
    cleanup_check
}

# Test 3: Cancel test
test_cancel() {
    echo -e "\n${YELLOW}Test 3: Cancel/Pause Test${NC}"
    echo "--------------------------------------"
    echo "1. Start downloading: $VALID_URL"
    echo "2. Cancel or pause the download mid-way"
    echo ""
    read -p "Press Enter after canceling..."
    
    cleanup_check
}

# Test 4: Multiple downloads
test_concurrent() {
    echo -e "\n${YELLOW}Test 4: Concurrent Downloads${NC}"
    echo "--------------------------------------"
    echo "1. Add these URLs to queue:"
    echo "   - https://www.youtube.com/watch?v=aqz-KE-bpKQ"
    echo "   - https://www.youtube.com/watch?v=YE7VzlLtp-4"  
    echo "   - https://www.youtube.com/watch?v=_OBlgSz8sSM"
    echo "2. Start downloading all"
    echo ""
    read -p "Press Enter while downloads are running..."
    
    check_processes
    echo "Expected: 3 or fewer processes (based on your concurrent limit)"
    
    read -p "Press Enter when all downloads complete..."
    cleanup_check
}

# Test 5: App quit test
test_quit() {
    echo -e "\n${YELLOW}Test 5: App Quit Cleanup${NC}"
    echo "--------------------------------------"
    echo "1. Start a download"
    echo "2. Quit the app while downloading (Cmd+Q)"
    echo ""
    read -p "Press Enter after quitting the app..."
    
    cleanup_check
}

# Main menu
while true; do
    echo -e "\n${GREEN}Select a test to run:${NC}"
    echo "1) Basic Download Test"
    echo "2) Timeout Test"
    echo "3) Cancel/Pause Test"
    echo "4) Concurrent Downloads Test"
    echo "5) App Quit Test"
    echo "6) Run All Tests"
    echo "7) Check Current Processes"
    echo "8) Kill All yt-dlp Processes"
    echo "0) Exit"
    
    read -p "Enter choice: " choice
    
    case $choice in
        1) test_basic ;;
        2) test_timeout ;;
        3) test_cancel ;;
        4) test_concurrent ;;
        5) test_quit ;;
        6) 
            test_basic
            test_timeout
            test_cancel
            test_concurrent
            test_quit
            echo -e "\n${GREEN}All tests complete!${NC}"
            ;;
        7) 
            check_processes
            ps aux | grep -E "yt-dlp" | grep -v grep
            ;;
        8) 
            echo "Killing all yt-dlp processes..."
            killall -9 yt-dlp 2>/dev/null
            killall -9 Python 2>/dev/null
            echo "Done."
            ;;
        0) exit 0 ;;
        *) echo "Invalid choice" ;;
    esac
done