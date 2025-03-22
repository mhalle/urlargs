# Test Suite for urldecode-wrap

This directory contains a comprehensive test suite for the `urldecode-wrap` utility.

## Running the Tests

To run the complete test suite:

```bash
./run_tests.sh
```

The test runner will execute all test files and report the results, including the number of passed and failed tests.

## Individual Test Files

The test suite is organized into the following test files:

1. **test_basic_functionality.sh**: Tests the core functionality of executing commands with decoded arguments
2. **test_filter_mode.sh**: Tests the filter mode for processing stdin
3. **test_special_characters.sh**: Tests decoding of various special characters
4. **test_dry_run_mode.sh**: Tests the dry run mode functionality
5. **test_edge_cases.sh**: Tests edge cases and error handling

## Adding New Tests

To add a new test file:

1. Create a new file named `test_*.sh` in this directory
2. Follow the structure of existing test files
3. Implement test cases using the helper functions
4. Make the script executable with `chmod +x test_new_file.sh`

Each test file should:
- Accept the script path as its first argument
- Use helper functions for assertions
- Return a non-zero exit code if any tests fail

## Test Helper Functions

- `assert_equals`: Compares actual output to expected output
- `assert_contains`: Checks if output contains expected text
- `assert_fails`: Verifies that a command fails as expected

## Test Environment

Each test file creates a temporary directory for test artifacts, which is automatically cleaned up when the test completes.