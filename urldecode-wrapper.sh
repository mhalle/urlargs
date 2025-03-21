#!/bin/bash

# Parse command-line options
preview=false
show_help=false
filter_mode=false

# Process all options that start with --
while [[ $# -gt 0 ]]; do
    case "$1" in
        --)
            # End of options marker
            shift
            break
            ;;
        --help)
            show_help=true
            shift
            ;;
        --preview)
            preview=true
            shift
            ;;
        --filter)
            filter_mode=true
            shift
            ;;
        --*)
            echo "Unknown option: $1"
            echo "Try '$0 --help' for more information."
            exit 1
            ;;
        *)
            # First non-option argument is the executable
            break
            ;;
    esac
done

# Show detailed help if requested
if $show_help; then
    cat << 'EOF'
URL DECODE WRAPPER - Run commands with URL-decoded arguments

SYNOPSIS
    urldecode-wrap [OPTIONS] [--] EXECUTABLE [ARGUMENTS...]
    urldecode-wrap --filter [EXECUTABLE [ARGUMENTS...]]

DESCRIPTION
    This script decodes URL-encoded arguments and passes them to the specified 
    executable. It's designed to work with LLM-generated commands containing 
    special characters that would normally require complex shell escaping.
    
    In filter mode (--filter), it also decodes URL-encoded input from stdin.

OPTIONS
    --help      Display this detailed help message
    --preview   Show decoded arguments without executing the command
    --filter    Process URL-encoded stdin in addition to arguments
    --          End option processing (useful if the executable name begins with --)

USAGE WITH LLMs
    When working with LLMs to generate complex command arguments:
    
    1. Ask the LLM to URL-encode any arguments containing special characters
       (spaces, quotes, semicolons, etc.)
    
    2. ALWAYS wrap URL-encoded arguments in double quotes to prevent the shell
       from interpreting special characters before they reach this script
    
    3. For commands with shell metacharacters, encode ALL potentially problematic characters:
       - Spaces (%20) - IMPORTANT: Always use %20 for spaces, never use + signs
       - Plus signs (%2B) - not required but good practice to encode them
       - Quotes (%27 for single, %22 for double)
       - Semicolons (%3B)
       - Asterisks/wildcards (%2A)
       - Question marks (%3F)
       - Square brackets (%5B and %5D)
       - Parentheses (%28 and %29)
       - Angle brackets (%3C and %3E)
       - Pipes (%7C)
       - Ampersands (%26)
       - Dollar signs (%24)
       - Backslashes (%5C)
       - Backticks (%60)
       - Exclamation marks (%21)
       - Any other character with special meaning in shells
       
       There is no harm in URL-encoding liberally - non-special characters 
       pass through unchanged, while potentially problematic ones are protected.
       
       Example with find command:
       Original:  find /path -name "file with spaces" -exec grep "pattern" {} \;
       Wrapped:   urldecode-wrap find /path -name "file%20with%20spaces" \
                  -exec grep "pattern%20with%20quotes" {} "%3B"

EXAMPLES
    # Basic usage with URL-encoded argument
    urldecode-wrap sqlite3 mydatabase.db "SELECT%20*%20FROM%20users"
    
    # Preview mode to see decoded arguments
    urldecode-wrap --preview grep "search%20term%20with%20spaces" filename
    
    # Using as a filter to decode URL-encoded content
    echo "SELECT%20*%20FROM%20users" | urldecode-wrap --filter
    
    # Reading URL-encoded content, decoding it, and piping to a command
    echo "SELECT%20*%20FROM%20users" | urldecode-wrap --filter sqlite3 mydatabase.db
    
    # Complex regex with many special characters
    urldecode-wrap grep "%5E%5Bwxy%5D%2B%5C.%2A%24" filename.txt
    
    # Using find with URL-encoded semicolon
    urldecode-wrap find /path -name "file%20with%20spaces" -exec grep "pattern" {} "%3B"

NOTES
    - This script automatically detects and decodes ALL arguments
    - Non-URL-encoded arguments are passed through unchanged
    - Double-quoting URL-encoded arguments is essential
    - This script can be used with any executable program
    - Be liberal with URL encoding - encode ANY character that might have special
      meaning in shell contexts (spaces, quotes, semicolons, brackets, braces,
      parentheses, backslashes, exclamation marks, etc.)
    - NEVER use + to represent spaces - always use %20 for spaces
    - Plus signs (+) will pass through unchanged if not encoded, but encoding them as %2B
      is recommended for clarity and consistency
    - Always place URL-encoded strings in double quotes
    - For find's -exec terminator, encode the semicolon as %3B and put it in double quotes: "%3B"
    - For multi-line code with indentation (e.g., with python -c), ensure spaces are encoded as %20
      and newlines as %0A
    - In filter mode (--filter), stdin is processed line by line, decoding each line

EOF
    exit 0
fi

# Function to URL decode a string
urldecode() {
    # Replace + with space (but only if we're using standard URL encoding mode)
    local data="$1"
    
    # Decode percent-encoded octets
    local i=0
    local len=${#data}
    local result=""
    
    while [ $i -lt $len ]; do
        local c="${data:$i:1}"
        if [ "$c" = "%" ] && [ $i -lt $((len-2)) ]; then
            local hex="${data:$i+1:2}"
            # Use printf to convert hex to character - preserves whitespace exactly
            local char=$(printf "\\x$hex")
            result+="$char"
            i=$((i+3))
        else
            result+="$c"
            i=$((i+1))
        fi
    done
    
    # Important: Echo without newline to preserve exact whitespace
    printf '%s' "$result"
}

# Process URL-encoded stdin in filter mode
filter_stdin() {
    local line
    local decoded
    
    # Read line by line from stdin
    while IFS= read -r line; do
        decoded=$(urldecode "$line")
        printf "%s\n" "$decoded"
    done
}

# Ensure we have at least one argument (the executable) unless in filter mode
if [ $# -lt 1 ] && [ "$filter_mode" = false ]; then
    echo "Error: No executable specified."
    echo "Usage: $0 [--preview] [--help] [--filter] EXECUTABLE [ARGUMENTS...]"
    echo "Try '$0 --help' for more information."
    exit 1
fi

# Handle filter mode without executable (output to stdout)
if [ "$filter_mode" = true ] && [ $# -eq 0 ]; then
    filter_stdin
    exit 0
fi

# The executable to run is the first argument
executable="$1"
shift

# Process all remaining arguments (decode them)
declare -a decoded_args
for arg in "$@"; do
    # Store decoded argument directly in the array
    # This preserves all special characters without reinterpretation
    decoded_args+=("$(urldecode "$arg")")
done

# Preview mode
if $preview; then
    echo "Command: $executable"
    for i in "${!decoded_args[@]}"; do
        printf "Arg %d: '%s'\n" $((i+1)) "${decoded_args[$i]}"
    done
    exit 0
fi

# Execute the command with decoded arguments
if [ "$filter_mode" = true ]; then
    # Create a temporary file for stdin
    tmp_file=$(mktemp)
    trap 'rm -f "$tmp_file"' EXIT
    
    # Process stdin through the URL decoder and save to temp file
    filter_stdin > "$tmp_file"
    
    # Execute with decoded stdin
    exec "$executable" "${decoded_args[@]}" < "$tmp_file"
else
    # Execute normally without stdin processing
    exec "$executable" "${decoded_args[@]}"
fi
