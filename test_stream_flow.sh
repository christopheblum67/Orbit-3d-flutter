#!/bin/bash
# Test script for stream flow diagnostic
# Run from project root: bash test_stream_flow.sh

set -e

echo "=========================================="
echo "Orbit3D Stream Flow Diagnostic"
echo "=========================================="

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

TEST_URL="https://draap.online/series/169503400638842/1593574628/7819"
UA_CHROME="Mozilla/5.0 (Linux; Android 14; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Mobile Safari/537.36"
UA_EXOPLAYER="ExoPlayer/2.19.1"

function test_head() {
    echo -e "\n${YELLOW}Test 1: HEAD request${NC}"
    curl -s -o /dev/null -w "HTTP %{http_code}" -X HEAD -H "User-Agent: $UA_CHROME" "$TEST_URL"
    echo ""
}

function test_get_chrome() {
    echo -e "\n${YELLOW}Test 2: GET with Chrome UA${NC}"
    curl -s -o /dev/null -w "HTTP %{http_code}" -H "User-Agent: $UA_CHROME" -H "Accept: */*" -H "Referer: https://draap.online/" "$TEST_URL"
    echo ""
}

function test_get_exoplayer() {
    echo -e "\n${YELLOW}Test 3: GET with ExoPlayer UA${NC}"
    curl -s -o /dev/null -w "HTTP %{http_code}" -H "User-Agent: $UA_EXOPLAYER" -H "Accept: */*" -H "Referer: https://draap.online/" "$TEST_URL"
    echo ""
}

function test_session() {
    echo -e "\n${YELLOW}Test 4: Session with cookie jar${NC}"
    COOKIE_JAR=$(mktemp)
    
    # Step 1: Load homepage
    echo "Loading homepage..."
    curl -s -c "$COOKIE_JAR" -H "User-Agent: $UA_CHROME" "https://draap.online/" > /dev/null
    
    # Show cookies
    echo "Cookies captured:"
    grep -v '^#' "$COOKIE_JAR" | awk '{print "  " $6 "=" $7}'
    
    # Step 2: Try stream with cookies
    echo "Trying stream with cookies..."
    curl -s -o /dev/null -w "HTTP %{http_code}" -b "$COOKIE_JAR" \
        -H "User-Agent: $UA_CHROME" -H "Accept: */*" -H "Referer: https://draap.online/" \
        "$TEST_URL"
    echo ""
    
    rm "$COOKIE_JAR"
}

function test_cf_clearance_hunt() {
    echo -e "\n${YELLOW}Test 5: Hunt for cf_clearance (multiple requests)${NC}"
    COOKIE_JAR=$(mktemp)
    
    for i in {1..10}; do
        echo -n "Attempt $i: "
        curl -s -c "$COOKIE_JAR" -b "$COOKIE_JAR" \
            -H "User-Agent: $UA_CHROME" \
            "https://draap.online/" > /dev/null
        
        CF_CLEARANCE=$(grep 'cf_clearance' "$COOKIE_JAR" | awk '{print $7}')
        if [ -n "$CF_CLEARANCE" ]; then
            echo -e "${GREEN}FOUND cf_clearance!${NC}"
            echo "Value: ${CF_CLEARANCE:0:50}..."
            echo ""
            echo "=== COPY THIS VALUE FOR TEST 6 ==="
            echo "cf_clearance=$CF_CLEARANCE"
            echo "=================================="
            rm "$COOKIE_JAR"
            return 0
        else
            echo "not yet"
        fi
        sleep 3
    done
    
    echo -e "${RED}cf_clearance NOT found after 10 attempts${NC}"
    echo "All cookies:"
    grep -v '^#' "$COOKIE_JAR" | awk '{print "  " $6 "=" $7}'
    rm "$COOKIE_JAR"
    return 1
}

function test_with_cf_clearance() {
    echo -e "\n${YELLOW}Test 6: Test stream with cf_clearance${NC}"
    read -p "Paste cf_clearance value (from test 5): " CF_CLEARANCE
    
    if [ -z "$CF_CLEARANCE" ]; then
        echo "Skipped"
        return
    fi
    
    curl -s -o /dev/null -w "HTTP %{http_code}" \
        -H "User-Agent: $UA_CHROME" \
        -H "Accept: */*" \
        -H "Referer: https://draap.online/" \
        -H "Cookie: cf_clearance=$CF_CLEARANCE" \
        "$TEST_URL"
    echo ""
}

# Main
echo "Target URL: $TEST_URL"
echo ""

test_head
test_get_chrome
test_get_exoplayer
test_session
test_cf_clearance_hunt
test_with_cf_clearance

echo -e "\n${YELLOW}=========================================="
echo "Done. Check results above."
echo "==========================================${NC}"