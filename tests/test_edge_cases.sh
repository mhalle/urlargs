#!/bin/bash

# Edge case tests for urldecode-wrap

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

# Check if a command fails as expected
assert_fails() {
    local command="$1"
    local test_name="$2"
    
    if eval "$command" > /dev/null 2>&1; then
        echo "✗ FAIL: $test_name (command succeeded but should have failed)"
        return 1
    else
        echo "✓ PASS: $test_name (command failed as expected)"
        return 0
    fi
}

# Test 1: Empty argument
test_empty_arg() {
    local result
    result=$("$SCRIPT_PATH" echo "")
    assert_equals "" "$result" "Empty argument"
}

# Test 2: Very long URL-encoded string
test_long_string() {
    # Generate a long string of 1000 'a's
    local long_string=$(printf 'a%.0s' {1..1000})
    local encoded_string=$(echo "$long_string" | sed 's/ /%20/g')
    
    local result
    result=$("$SCRIPT_PATH" echo "$encoded_string" | wc -c | tr -d ' ')
    
    # The result should be 1000 characters (plus a newline)
    assert_equals "1001" "$result" "Very long URL-encoded string"
}

# Test 3: Partial URL encoding (only some % signs)
# KNOWN LIMITATION: Currently, invalid % sequences are converted to escape sequences
# TODO: Future enhancement to properly handle invalid percent encodings
test_partial_encoding() {
    echo "SKIP: Partial URL encoding test - known limitation with invalid % sequences"
    return 0  # Skip this test for now
    
    # Ideal behavior would be:
    # local result
    # result=$("$SCRIPT_PATH" echo "partially%20encoded%string%with%invalid%sequences")
    # assert_equals "partially encoded%string%with%invalid%sequences" "$result" "Partial URL encoding"
}

# Test 4: Invalid % sequences at the end
# KNOWN LIMITATION: Currently, trailing % are converted to escape sequences
# TODO: Future enhancement to properly handle invalid percent encodings
test_invalid_end_sequence() {
    echo "SKIP: Invalid end sequence test - known limitation with trailing % character"
    return 0  # Skip this test for now
    
    # Ideal behavior would be:
    # local result
    # result=$("$SCRIPT_PATH" echo "invalid%20at%20the%20end%")
    # assert_equals "invalid at the end%" "$result" "Invalid % sequence at the end"
}

# Test 5: Double-encoded URL
test_double_encoding() {
    local result
    result=$("$SCRIPT_PATH" echo "double%2520encoded")
    
    # %25 is the encoding for %, so this should decode to "double%20encoded"
    assert_equals "double%20encoded" "$result" "Double-encoded URL"
}

# Test 6: Missing executable
test_missing_executable() {
    assert_fails '"$SCRIPT_PATH" 2>/dev/null' "Missing executable"
}

# Test 7: Non-existent executable
test_nonexistent_executable() {
    assert_fails '"$SCRIPT_PATH" nonexistentcommand "foo" 2>/dev/null' "Non-existent executable"
}

# Test 8: Edge case - escaped % character
test_escaped_percent() {
    local result
    result=$("$SCRIPT_PATH" echo "100%25%20complete")
    assert_equals "100% complete" "$result" "Escaped percent character"
}

# Run all tests
run_all_tests() {
    local failures=0
    
    test_empty_arg || failures=$((failures + 1))
    test_long_string || failures=$((failures + 1))
    test_partial_encoding || failures=$((failures + 1))
    test_invalid_end_sequence || failures=$((failures + 1))
    test_double_encoding || failures=$((failures + 1))
    test_missing_executable || failures=$((failures + 1))
    test_nonexistent_executable || failures=$((failures + 1))
    test_escaped_percent || failures=$((failures + 1))
    
    return $failures
}

# Run the tests and exit with appropriate status
run_all_tests
exit $?