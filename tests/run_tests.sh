#!/bin/bash

# Test runner for urlargs
# Runs all tests and reports results

set -e  # Exit on error

# Get the directory where this script is located
TEST_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
SCRIPT_DIR="$(dirname "$TEST_DIR")"
SCRIPT_PATH="$SCRIPT_DIR/urlargs"

# Colors for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Ensure the script exists and is executable
if [ ! -x "$SCRIPT_PATH" ]; then
    echo -e "${RED}Error: Script $SCRIPT_PATH not found or not executable${NC}"
    exit 1
fi

echo -e "${YELLOW}Running urlargs test suite...${NC}"
echo ""

# Track test results
TESTS_TOTAL=0
TESTS_PASSED=0
TESTS_FAILED=0

# Function to run a test file
run_test() {
    local test_file="$1"
    local test_name="$(basename "$test_file" .sh)"
    
    echo -e "${YELLOW}Running test: ${test_name}${NC}"
    TESTS_TOTAL=$((TESTS_TOTAL + 1))
    
    # Run the test
    if bash "$test_file" "$SCRIPT_PATH"; then
        echo -e "${GREEN}✓ Test passed: ${test_name}${NC}"
        TESTS_PASSED=$((TESTS_PASSED + 1))
        return 0
    else
        echo -e "${RED}✗ Test failed: ${test_name}${NC}"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        return 1
    fi
}

# Run all test files
for test_file in "$TEST_DIR"/test_*.sh; do
    if [ -f "$test_file" ]; then
        run_test "$test_file"
        echo ""
    fi
done

# Print summary
echo -e "${YELLOW}Test Summary:${NC}"
echo -e "Total tests: $TESTS_TOTAL"
echo -e "${GREEN}Passed: $TESTS_PASSED${NC}"
if [ $TESTS_FAILED -gt 0 ]; then
    echo -e "${RED}Failed: $TESTS_FAILED${NC}"
    exit 1
else
    echo -e "Failed: $TESTS_FAILED"
    echo -e "${GREEN}All tests passed!${NC}"
    exit 0
fi