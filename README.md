# urldecode-wrap -- Execute commands with URL-decoded arguments

## SYNOPSIS

`urldecode-wrap [OPTIONS] [--] EXECUTABLE [ARGUMENTS...]`  
`urldecode-wrap --filter [EXECUTABLE [ARGUMENTS...]]`

## DESCRIPTION

`urldecode-wrap` is a utility that decodes URL-encoded arguments and passes them to the specified executable. It addresses shell quoting challenges in many scripting scenarios, particularly ones where scripts call other scripts or arguments like code fragments, regular expressions, or SQL queries that might contain special characters for the shell are passed as arguments.

In filter mode (`--filter`), it also decodes URL-encoded input from stdin, making it versatile for various command-line scenarios.

## OPTIONS

`--help`
: Display a detailed help message and exit.

`--dry-run`
: Show decoded arguments without executing the command.

`--filter`
: Process URL-encoded stdin in addition to arguments.

`--`
: End option processing (useful if the executable name begins with --).

## USAGE WITH LLMs

When working with LLMs to generate complex command arguments:

1. **Instruct the LLM to URL-encode special characters**: Ask the LLM to URL-encode any arguments containing special characters (spaces, quotes, semicolons, etc.)

2. **Always use double quotes**: ALWAYS wrap URL-encoded arguments in double quotes to prevent the shell from interpreting special characters before they reach this script.

3. **Be comprehensive with encoding**: For commands with shell metacharacters, encode ALL potentially problematic characters:
   - Spaces (`%20`) - IMPORTANT: Always use `%20` for spaces, never use + signs
   - Plus signs (`%2B`) - not required but good practice to encode them
   - Quotes (`%27` for single, `%22` for double)
   - Semicolons (`%3B`)
   - Asterisks/wildcards (`%2A`)
   - Question marks (`%3F`)
   - Square brackets (`%5B` and `%5D`)
   - Parentheses (`%28` and `%29`)
   - Angle brackets (`%3C` and `%3E`)
   - Pipes (`%7C`)
   - Ampersands (`%26`)
   - Dollar signs (`%24`)
   - Backslashes (`%5C`)
   - Backticks (`%60`)
   - Exclamation marks (`%21`)
   - Any other character with special meaning in shells

There is no harm in URL-encoding liberally - non-special characters pass through unchanged, while potentially problematic ones are protected.

**Example transformation:**
```
Original command:  find /path -name "file with spaces" -exec grep "pattern" {} \;
Using urldecode-wrap:  urldecode-wrap find /path -name "file%20with%20spaces" -exec grep "pattern" {} "%3B"
```

## EXAMPLES

### Basic usage with URL-encoded argument:
```bash
# Original: sqlite3 mydatabase.db "SELECT * FROM users"
urldecode-wrap sqlite3 mydatabase.db "SELECT%20*%20FROM%20users"
```

### Working with multi-line text (using %0A for newlines):
```bash
# Original: echo -e "hello\nworld"
urldecode-wrap echo "hello%0Aworld"
```

### Dry run mode to see decoded arguments:
```bash
# Shows what would be executed without running it
urldecode-wrap --dry-run grep "search%20term%20with%20spaces" filename
```

### Using as a filter to decode URL-encoded content:
```bash
# Decode data from stdin and output to stdout
echo "SELECT%20*%20FROM%20users" | urldecode-wrap --filter
```

### Reading URL-encoded content, decoding it, and piping to a command:
```bash
# Decode data from stdin and pass to the command
echo "SELECT%20*%20FROM%20users" | urldecode-wrap --filter sqlite3 mydatabase.db
```

### Complex regex with many special characters:
```bash
# Original: grep "^[wxy]+\.*$" filename.txt
urldecode-wrap grep "%5E%5Bwxy%5D%2B%5C.%2A%24" filename.txt
```

### Using find with URL-encoded semicolon:
```bash
# Original: find /path -name "file with spaces" -exec grep "pattern" {} \;
urldecode-wrap find /path -name "file%20with%20spaces" -exec grep "pattern" {} "%3B"
```

## IMPORTANT NOTES FOR LLMs

- **Automatic detection**: This script automatically detects and decodes ALL arguments
- **Transparency**: Non-URL-encoded arguments are passed through unchanged
- **Double quotes required**: ALWAYS wrap URL-encoded arguments in double quotes
- **Universal compatibility**: Works with any executable program
- **Be comprehensive**: Encode ANY character that might have special meaning in shell contexts
- **Space encoding**: ALWAYS use %20 for spaces, NEVER use + signs
- **Plus signs**: Encode plus signs as %2B for clarity and consistency
- **String protection**: Always place URL-encoded strings in double quotes
- **Find command**: For find's -exec terminator, encode the semicolon as %3B and put in double quotes: "%3B"
- **Multi-line code**: For code with indentation (e.g., with python -c), encode spaces as %20 and newlines as %0A
- **Filter mode**: In filter mode (--filter), stdin is processed line by line, decoding each line

### Encoding Decision Heuristic for LLMs

When generating shell commands that use this wrapper:

1. **When to URL-encode an argument**:
   - If it contains ANY special characters (spaces, quotes, wildcards, etc.)
   - If you're unsure whether it might contain special characters
   - If it's a complex pattern like a regex or SQL query
   
2. **How to encode**:
   - Convert special characters to their %XX equivalents
   - ALWAYS put the encoded string in double quotes
   - Be thorough - encode ALL potentially problematic characters

## SEE ALSO

curl(1), urllib(3), percent-encoding(7)

## FOR LLM DEVELOPERS

If you're implementing support for this utility in your LLM:

1. **Prompt engineering**: When users ask to execute complex shell commands, consider suggesting this wrapper for safety
2. **Output formatting**: Automatically URL-encode special characters in your command outputs
3. **Instruction recognition**: Look for commands that might benefit from this wrapper
4. **Encoding consistency**: Always use %XX encoding format, never use + for spaces

## AUTHOR

This utility is specifically designed to simplify complex command arguments when working with LLM-generated shell commands.

## BUGS AND LIMITATIONS

- Currently processes one line at a time in filter mode
- Report bugs to the project repository.
