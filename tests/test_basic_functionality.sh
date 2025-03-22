#!/bin/bash

# Basic functionality tests for urldecode-wrap

# The script path is passed as the first argument
SCRIPT_PATH="$1"

# Setup temporary directory for test artifacts
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Test helper function to check if output matches expected result
assert_equals() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    if [ "$expected" = "$actual" ]; then
        echo "✓ PASS: $test_name"
        return 0
    else
        echo "✗ FAIL: $test_name"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        return 1
    fi
}

# Test 1: Basic command execution with no URL encoding
test_basic_execution() {
    local result
    result=$("$SCRIPT_PATH" echo "hello world")
    assert_equals "hello world" "$result" "Basic command execution"
}

# Test 2: URL-encoded spaces
test_encoded_spaces() {
    local result
    result=$("$SCRIPT_PATH" echo "hello%20world")
    assert_equals "hello world" "$result" "URL-encoded spaces"
}

# Test 3: Multiple URL-encoded arguments
test_multiple_encoded_args() {
    local result
    result=$("$SCRIPT_PATH" echo "hello%20world" "foo%20bar")
    assert_equals "hello world foo bar" "$result" "Multiple URL-encoded arguments"
}

# Test 4: Mixed encoded and non-encoded arguments
test_mixed_args() {
    local result
    result=$("$SCRIPT_PATH" echo "hello%20world" normal "foo%20bar")
    assert_equals "hello world normal foo bar" "$result" "Mixed encoded and non-encoded arguments"
}

# Test 5: Preserving quotes in URL-encoded arguments
test_preserve_quotes() {
    local result
    result=$("$SCRIPT_PATH" echo "%22quoted%20text%22")
    assert_equals "\"quoted text\"" "$result" "Preserving quotes in URL-encoded arguments"
}

# Test 6: URL-encoded newlines
test_encoded_newlines() {
    local result
    result=$("$SCRIPT_PATH" echo "line1%0Aline2")
    assert_equals "line1
line2" "$result" "URL-encoded newlines"
}

# Run all tests
run_all_tests() {
    local failures=0
    
    test_basic_execution || failures=$((failures + 1))
    test_encoded_spaces || failures=$((failures + 1))
    test_multiple_encoded_args || failures=$((failures + 1))
    test_mixed_args || failures=$((failures + 1))
    test_preserve_quotes || failures=$((failures + 1))
    test_encoded_newlines || failures=$((failures + 1))
    
    return $failures
}

# Run the tests and exit with appropriate status
run_all_tests
exit $?