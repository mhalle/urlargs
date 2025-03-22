# urlargs (Perl implementation)

This is a Perl implementation of the urlargs utility, which decodes URL-encoded arguments and passes them to a specified executable.

## Features

- Works across all platforms where Perl is available
- Decodes URL-encoded arguments and stdin content
- Compatible with all shells since it's using Perl
- Support for filter mode to process URL-encoded stdin
- Dry run mode to preview decoded arguments

## Requirements

- Perl 5.8.0 or newer
- Required Perl modules:
  - URI::Escape (for URL decoding)
  - Getopt::Long (for argument parsing)
  - File::Temp (for temporary file handling)

## Installation

1. Ensure you have Perl installed
2. Install required Perl modules if not already available:
   ```
   cpan URI::Escape Getopt::Long File::Temp
   ```
3. Make the script executable:
   ```
   chmod +x urlargs.pl
   ```
4. Optional: Move the script to a directory in your PATH

## Usage

Basic usage with URL-encoded argument:
```
./urlargs.pl sqlite3 mydatabase.db "SELECT%20*%20FROM%20users"
```

Using as a filter to decode URL-encoded content:
```
echo "SELECT%20*%20FROM%20users" | ./urlargs.pl --filter
```

Dry run mode to see decoded arguments:
```
./urlargs.pl --dry-run grep "search%20term%20with%20spaces" filename
```

For full documentation, run:
```
./urlargs.pl --help
```