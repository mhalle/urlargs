#!/usr/bin/env bash

# Dry run mode tests for urldecode-wrap

# The script path is passed as the first argument
SCRIPT_PATH="$1"

# Setup temporary directory for test artifacts
TEMP_DIR=$(mktemp -d)
trap 'rm -rf "$TEMP_DIR"' EXIT

# Test helper function to check if output contains expected pattern
assert_contains() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    
    if [[ "$actual" == *"$expected"* ]]; then
        echo "✓ PASS: $test_name"
        return 0
    else
        echo "✗ FAIL: $test_name"
        echo "  Expected to contain: '$expected'"
        echo "  Actual:             '$actual'"
        return 1
    fi
}

# Test 1: Basic dry run mode
test_basic_dry_run() {
    local result
    result=$("$SCRIPT_PATH" --dry-run echo "hello%20world")
    
    assert_contains "Command: echo" "$result" "Dry run shows command"
    assert_contains "hello world" "$result" "Dry run shows decoded argument"
}

# Test 2: Dry run mode with multiple arguments
test_dry_run_multiple_args() {
    local result
    result=$("$SCRIPT_PATH" --dry-run echo "arg1%20with%20spaces" "arg2%20with%20spaces")
    
    assert_contains "Command: echo" "$result" "Dry run shows command"
    assert_contains "arg1 with spaces" "$result" "Dry run shows first decoded argument"
    assert_contains "arg2 with spaces" "$result" "Dry run shows second decoded argument"
}

# Test 3: Dry run mode with complex arguments
test_dry_run_complex_args() {
    local result
    result=$("$SCRIPT_PATH" --dry-run grep "pattern%20with%20%22quotes%22" "file%20name.txt")
    
    assert_contains "Command: grep" "$result" "Dry run shows command"
    assert_contains "pattern with \"quotes\"" "$result" "Dry run shows complex decoded argument"
    assert_contains "file name.txt" "$result" "Dry run shows filename argument"
}

# Test 4: Dry run mode should not execute the command
test_dry_run_no_execution() {
    # Create a marker file that would be removed if the command executed
    local marker_file="$TEMP_DIR/marker.txt"
    echo "marker" > "$marker_file"
    
    # Run in dry run mode a command that would remove the marker file
    "$SCRIPT_PATH" --dry-run rm "$marker_file" > /dev/null
    
    # Check if the marker file still exists
    if [ -f "$marker_file" ]; then
        echo "✓ PASS: Dry run mode does not execute command"
        return 0
    else
        echo "✗ FAIL: Dry run mode executed the command"
        return 1
    fi
}

# Test 5: Argument numbering in dry run output
test_dry_run_arg_numbering() {
    local result
    result=$("$SCRIPT_PATH" --dry-run echo "arg1" "arg2" "arg3")
    
    assert_contains "Arg 1: 'arg1'" "$result" "Dry run shows argument 1 with correct numbering"
    assert_contains "Arg 2: 'arg2'" "$result" "Dry run shows argument 2 with correct numbering"
    assert_contains "Arg 3: 'arg3'" "$result" "Dry run shows argument 3 with correct numbering"
}

# Run all tests
run_all_tests() {
    local failures=0
    
    test_basic_dry_run || failures=$((failures + 1))
    test_dry_run_multiple_args || failures=$((failures + 1))
    test_dry_run_complex_args || failures=$((failures + 1))
    test_dry_run_no_execution || failures=$((failures + 1))
    test_dry_run_arg_numbering || failures=$((failures + 1))
    
    return $failures
}

# Run the tests and exit with appropriate status
run_all_tests
exit $?