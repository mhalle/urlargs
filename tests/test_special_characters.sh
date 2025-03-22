#!/bin/bash

# Special character encoding tests for urldecode-wrap

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

# Test 1: URL-encoded quotes
test_quotes() {
    local result
    result=$("$SCRIPT_PATH" echo "%27single%20quotes%27%20and%20%22double%20quotes%22")
    assert_equals "'single quotes' and \"double quotes\"" "$result" "URL-encoded quotes"
}

# Test 2: URL-encoded special shell characters
test_shell_special_chars() {
    local result
    result=$("$SCRIPT_PATH" echo "%7C%20pipe%20%26%20ampersand%20%3B%20semicolon%20%3E%20redirect")
    assert_equals "| pipe & ampersand ; semicolon > redirect" "$result" "URL-encoded shell special characters"
}

# Test 3: URL-encoded brackets and parentheses
test_brackets() {
    local result
    result=$("$SCRIPT_PATH" echo "%28parentheses%29%20%5Bsquare%20brackets%5D%20%7Bcurly%20braces%7D")
    assert_equals "(parentheses) [square brackets] {curly braces}" "$result" "URL-encoded brackets and parentheses"
}

# Test 4: URL-encoded wildcards and regex special chars
test_wildcards() {
    local result
    result=$("$SCRIPT_PATH" echo "%2A%20asterisk%20%3F%20question%20%5E%20caret%20%24%20dollar")
    assert_equals "* asterisk ? question ^ caret $ dollar" "$result" "URL-encoded wildcards and regex special chars"
}

# Test 5: URL-encoded backslash and backticks
test_escapes() {
    local result
    result=$("$SCRIPT_PATH" echo "%5C%20backslash%20%60backtick%60")
    assert_equals "\\ backslash \`backtick\`" "$result" "URL-encoded backslash and backticks"
}

# Test 6: URL-encoded plus sign
test_plus_sign() {
    local result
    result=$("$SCRIPT_PATH" echo "a%2Bb%20equals%20c")
    assert_equals "a+b equals c" "$result" "URL-encoded plus sign"
}

# Test 7: Complex regex pattern
test_complex_regex() {
    local result
    result=$("$SCRIPT_PATH" echo "%5E%5B%5Cd%5D%2B%5C.%5B%5Cd%5D%2B%24")
    assert_equals "^[\\d]+\\.[\\d]+$" "$result" "Complex regex pattern"
}

# Test 8: URL-encoded Unicode characters
test_unicode() {
    local result
    result=$("$SCRIPT_PATH" echo "%C3%A9%20is%20the%20letter%20e%20with%20acute%20accent")
    assert_equals "é is the letter e with acute accent" "$result" "URL-encoded Unicode characters"
}

# Run all tests
run_all_tests() {
    local failures=0
    
    test_quotes || failures=$((failures + 1))
    test_shell_special_chars || failures=$((failures + 1))
    test_brackets || failures=$((failures + 1))
    test_wildcards || failures=$((failures + 1))
    test_escapes || failures=$((failures + 1))
    test_plus_sign || failures=$((failures + 1))
    test_complex_regex || failures=$((failures + 1))
    test_unicode || failures=$((failures + 1))
    
    return $failures
}

# Run the tests and exit with appropriate status
run_all_tests
exit $?