#!/usr/bin/env perl
# 
# urlargs v1.0.0 (Perl implementation)
# Copyright 2025 Michael Halle (urldecode-wrap@m.halle.us)
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

use strict;
use warnings;
use Getopt::Long;
use File::Temp qw(tempfile);
use URI::Escape;

# Initialize variables
my $dry_run = 0;
my $help = 0;
my $filter_mode = 0;

# Function to show help message
sub show_help_message {
    print <<'EOF';
URLARGS - Run commands with URL-decoded arguments (Perl implementation)

SYNOPSIS
    urlargs.pl [OPTIONS] [--] EXECUTABLE [ARGUMENTS...]
    urlargs.pl --filter [EXECUTABLE [ARGUMENTS...]]

DESCRIPTION
    This script decodes URL-encoded arguments and passes them to the specified 
    executable. It addresses shell quoting challenges in many scripting scenarios,
    particularly ones where scripts call other scripts or arguments like code
    fragments, regular expressions, or SQL queries that might contain special
    characters for the shell are passed as arguments.
    
    In filter mode (--filter), it also decodes URL-encoded input from stdin.

OPTIONS
    --help      Display this detailed help message
    --dry-run   Show decoded arguments without executing the command
    --filter    Process URL-encoded stdin in addition to arguments
    --          End option processing (useful if the executable name begins with --)

USAGE WITH LLMs
    When working with LLMs to generate complex command arguments:
    
    1. Ask the LLM to URL-encode any arguments containing special characters
       (spaces, quotes, semicolons, etc.)
    
    2. Consider wrapping URL-encoded arguments in double quotes if they contain 
       characters that the shell might interpret (like spaces, wildcards, etc.).
       While the percent sign itself isn't generally interpreted by the shell,
       quoting ensures all parts of your encoded argument are properly passed to
       the script
    
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
       - Newlines (%0A)
       - Carriage returns (%0D)
       - Form feeds (%0C)
       - Any other character with special meaning in shells
       
       There is no harm in URL-encoding liberally - non-special characters 
       pass through unchanged, while potentially problematic ones are protected.
       
       Example with find command:
       Original:  find /path -name "file with spaces" -exec grep "pattern" {} \;
       Wrapped:   urlargs.pl find /path -name "file%20with%20spaces" \
                  -exec grep "pattern%20with%20quotes" {} "%3B"

EXAMPLES
    # Basic usage with URL-encoded argument
    urlargs.pl sqlite3 mydatabase.db "SELECT%20*%20FROM%20users"
    
    # Dry run mode to see decoded arguments
    urlargs.pl --dry-run grep "search%20term%20with%20spaces" filename
    
    # Using as a filter to decode URL-encoded content
    echo "SELECT%20*%20FROM%20users" | urlargs.pl --filter
    
    # Reading URL-encoded content, decoding it, and piping to a command
    echo "SELECT%20*%20FROM%20users" | urlargs.pl --filter sqlite3 mydatabase.db
    
    # Complex regex with many special characters
    urlargs.pl grep "%5E%5Bwxy%5D%2B%5C.%2A%24" filename.txt
    
    # Using find with URL-encoded semicolon
    urlargs.pl find /path -name "file%20with%20spaces" -exec grep "pattern" {} "%3B"

    # Working with newlines
    urlargs.pl echo "hello%0Aworld"

NOTES
    - This script automatically detects and decodes ALL arguments
    - Non-URL-encoded arguments are passed through unchanged
    - Double-quoting URL-encoded arguments is recommended if they contain shell metacharacters
    - This script can be used with any executable program
    - Be liberal with URL encoding - encode ANY character that might have special
      meaning in shell contexts (spaces, quotes, semicolons, brackets, braces,
      parentheses, backslashes, exclamation marks, etc.)
    - NEVER use + to represent spaces - always use %20 for spaces
    - Plus signs (+) will pass through unchanged if not encoded, but encoding them as %2B
      is recommended for clarity and consistency
    - Consider placing URL-encoded strings in double quotes if they contain shell metacharacters
    - For find's -exec terminator, encode the semicolon as %3B and put it in double quotes: "%3B"
    - For multi-line code with indentation (e.g., with python -c), ensure spaces are encoded as %20
      and newlines as %0A
    - In filter mode (--filter), stdin is processed line by line, decoding each line
EOF
    exit 0;
}

# Parse command-line options
GetOptions(
    "help" => \$help,
    "dry-run" => \$dry_run,
    "filter" => \$filter_mode,
) or die "Error in command line arguments\n";

# Show help if requested
if ($help) {
    show_help_message();
}

# Handle filter mode without executable (output to stdout)
if ($filter_mode && @ARGV == 0) {
    while (my $line = <STDIN>) {
        chomp $line;
        print uri_unescape($line) . "\n";
    }
    exit 0;
}

# Ensure we have at least one argument (the executable) unless in filter mode
if (@ARGV < 1 && !$filter_mode) {
    die "Error: No executable specified.\nUsage: $0 [--dry-run] [--help] [--filter] EXECUTABLE [ARGUMENTS...]\nTry '$0 --help' for more information.\n";
}

# The executable to run is the first argument
my $executable = shift @ARGV;

# Decode all arguments
my @decoded_args = map { uri_unescape($_) } @ARGV;

# Dry run mode
if ($dry_run) {
    print "Command: $executable\n";
    my $i = 1;
    foreach my $arg (@decoded_args) {
        print "Arg $i: '$arg'\n";
        $i++;
    }
    exit 0;
}

# Execute the command with decoded arguments
if ($filter_mode) {
    # Create a temporary file for decoded stdin content
    my ($fh, $tmp_file) = tempfile();
    
    # Decode stdin and write to temporary file
    while (my $line = <STDIN>) {
        chomp $line;
        print $fh uri_unescape($line) . "\n";
    }
    close $fh;
    
    # Execute command with decoded stdin
    open(STDIN, "<", $tmp_file) or die "Could not reopen stdin: $!";
    exec $executable, @decoded_args or die "Could not execute $executable: $!";
} else {
    # Execute command with decoded arguments only
    exec $executable, @decoded_args or die "Could not execute $executable: $!";
}