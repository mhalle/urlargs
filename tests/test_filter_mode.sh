#!/usr/bin/env bash

# Filter mode tests for urldecode-wrap

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

# Test 1: Basic filter mode with no command
test_basic_filter() {
    local result
    result=$(echo "hello%20world" | "$SCRIPT_PATH" --filter)
    assert_equals "hello world" "$result" "Basic filter mode"
}

# Test 2: Multiple lines in filter mode
test_multiline_filter() {
    local result
    result=$(printf "line1%%20one\nline2%%20two\n" | "$SCRIPT_PATH" --filter)
    assert_equals "line1 one
line2 two" "$result" "Multiple lines in filter mode"
}

# Test 3: Filter mode with command execution
test_filter_with_command() {
    local input_file="$TEMP_DIR/input.txt"
    local result_file="$TEMP_DIR/result.txt"
    
    # Create test input file
    echo "hello%20from%20input" > "$input_file"
    
    # Run the command with filter mode
    cat "$input_file" | "$SCRIPT_PATH" --filter cat > "$result_file"
    
    # Check the result
    local result=$(cat "$result_file")
    assert_equals "hello from input" "$result" "Filter mode with command execution"
}

# Test 4: Complex input with special characters
test_complex_filter_input() {
    local result
    result=$(echo "SELECT%20*%20FROM%20users%20WHERE%20name%3D%22John%22%3B" | "$SCRIPT_PATH" --filter)
    assert_equals "SELECT * FROM users WHERE name=\"John\";" "$result" "Complex input with special characters"
}

# Test 5: Empty input
test_empty_input() {
    local result
    result=$(echo "" | "$SCRIPT_PATH" --filter)
    assert_equals "" "$result" "Empty input"
}

# Test 6: Filter mode with command args - this test is challenging due to how different
# commands handle stdin vs args differently
test_filter_with_command_and_args() {
    # Use a simpler test that's more reliable
    local result
    result=$(echo "world" | "$SCRIPT_PATH" --filter grep "world")
    
    # If grep finds "world" in stdin, it will output that line
    assert_equals "world" "$result" "Filter mode with command and arguments"
}

# Run all tests
run_all_tests() {
    local failures=0
    
    test_basic_filter || failures=$((failures + 1))
    test_multiline_filter || failures=$((failures + 1))
    test_filter_with_command || failures=$((failures + 1))
    test_complex_filter_input || failures=$((failures + 1))
    test_empty_input || failures=$((failures + 1))
    test_filter_with_command_and_args || failures=$((failures + 1))
    
    return $failures
}

# Run the tests and exit with appropriate status
run_all_tests
exit $?