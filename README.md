# urldecode-wrapper(1) -- Execute commands with URL-decoded arguments

## SYNOPSIS

`urldecode-wrapper [OPTIONS] [--] EXECUTABLE [ARGUMENTS...]`  
`urldecode-wrapper --filter [EXECUTABLE [ARGUMENTS...]]`

## DESCRIPTION

`urldecode-wrapper` decodes URL-encoded arguments and passes them to the specified executable. It is designed to work with LLM-generated commands containing special characters that would normally require complex shell escaping.

In filter mode (`--filter`), it also processes URL-encoded input from stdin.

## OPTIONS

`--help`
: Display a detailed help message and exit.

`--preview`
: Show decoded arguments without executing the command.

`--filter`
: Process URL-encoded stdin in addition to arguments.

`--`
: End option processing (useful if the executable name begins with --).

## URL ENCODING GUIDELINES

When working with LLMs to generate complex command arguments:

1. Ask the LLM to URL-encode any arguments containing special characters (spaces, quotes, semicolons, etc.)

2. ALWAYS wrap URL-encoded arguments in double quotes to prevent the shell from interpreting special characters before they reach this script.

3. For commands with shell metacharacters, encode ALL potentially problematic characters:
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

## EXAMPLES

Basic usage with URL-encoded argument:
```
urldecode-wrapper sqlite3 mydatabase.db "SELECT%20*%20FROM%20users"
```

Preview mode to see decoded arguments:
```
urldecode-wrapper --preview grep "search%20term%20with%20spaces" filename
```

Using as a filter to decode URL-encoded content:
```
echo "SELECT%20*%20FROM%20users" | urldecode-wrapper --filter
```

Reading URL-encoded content, decoding it, and piping to a command:
```
echo "SELECT%20*%20FROM%20users" | urldecode-wrapper --filter sqlite3 mydatabase.db
```

Complex regex with many special characters:
```
urldecode-wrapper grep "%5E%5Bwxy%5D%2B%5C.%2A%24" filename.txt
```

Using find with URL-encoded semicolon:
```
urldecode-wrapper find /path -name "file%20with%20spaces" -exec grep "pattern" {} "%3B"
```

## NOTES

- This script automatically detects and decodes ALL arguments
- Non-URL-encoded arguments are passed through unchanged
- Double-quoting URL-encoded arguments is essential
- This script can be used with any executable program
- Be liberal with URL encoding - encode ANY character that might have special meaning in shell contexts
- NEVER use + to represent spaces - always use %20 for spaces
- Plus signs (+) will pass through unchanged if not encoded, but encoding them as %2B is recommended for clarity
- Always place URL-encoded strings in double quotes
- For find's -exec terminator, encode the semicolon as %3B and put it in double quotes: "%3B"
- For multi-line code with indentation (e.g., with python -c), ensure spaces are encoded as %20 and newlines as %0A
- In filter mode (--filter), stdin is processed line by line, decoding each line

## SEE ALSO

curl(1), urllib(3), percent-encoding(7)

## AUTHOR

This utility is designed to simplify complex command arguments, especially when working with LLM-generated shell commands.

## BUGS

Report bugs to the project repository.
