# Cmake Parse Python argparse

Implementation of parser for Python argparse commands arguments, based on help message.

## Functions

### Input functions

- `_arg_prase` - parse input arguments

### Output functions

- `_arg_get_command_output` - get command output
- `_arg_output_split` - splits command line output to optional/positional/usage parts

### Optional argument functions

- `_arg_optional_parse` - parse list of arguments
- `_arg_optional_arguments_split` - split argument to long and short argument
- `_arg_optional_argument_split` - split long or short argument to name and value

### Value functions

- `_arg_value` - formats passed arguments to VALUE format string
- `_arg_value_parse` - parse string value FORMAT

### Helpers

- `_arg_sanatize_name` convert name to suffix of variable

## To do

- [x] Detect `positional arguments`
- [x] Detect `options` / `optional arguments`
    - [x] Match short name
    - [x] Match long name
- [ ] Detect subcommands
- [x] Extract positional arguments
- [x] Extract optional
- [ ] Prase input in style of `cmake_parse_arguments`
- [ ] Parse usage to get number of arguments
- [x] Bug: Wrong detection of `-nr, --no-remote`
- [x] Name fallback should always choose long name (if present)
- [x] Set narg when optional value is flag
- [ ] Parse positional arguments
- [ ] Verify choice values
- [ ] `_arg_is_value` - should check if -3.14 is passed correctly as value

## Limitations

Script can detect usage of: '+', '?', '*', 0, n arguments
It cannot detect `action` being used: 'store', 'count' for this reason all values will be added to the list.

## Format

Scrit can parse custom arguments parsers:

- positional arguments
- optional arguments and it value
    - must be in single line
- optional arguments:
    - short name must match regex `-[a-z:-]+`
    - long name must match regex `--[a-z:-]+` regex
    - short and long options must be separated by `, ` literal
- optional argument help will be separated by at least two spaces '  ' literal. 
- optional argument values:
    - value name must match regex `[A-Z_]+` - for basic value
    - value name must match regex `{[A-Z_]+(,[A-Z_]+)*}` - for chocice list
    - common styles:
        - `[NAME]` - will denote optional value, only last    
        argument will be stored
        example: `--arg-star A` will store list "A"
        example: `--arg-star A --arg-star B` will store "B"
        example: `--arg-star` will store ""
        nargs type `?`
        - `[NAME ...]` - will denote optional value that can be a list, only last    
        argument will be stored
        example: `--arg-star A B C` will store list "A;B;C"
        example: `--arg-star A B C --arg-star D` will store "D"
        example: `--arg-star` will store ""
        nargs type `*`
        - `NAME [NAME ...]` - will denote at leas one value in list, only last argument will be stored
        example: `--arg-plus A B C` will store list "A;B;C"
        example: `--arg-plus A B C --arg-star D` will store "D"
        example: `--arg-star A` will store "A"
        nargs type `+`
        - `NAME` - will denote single required value
        example: `--arg-num1 A` will store list "A"
        example: `--arg-num1 A --arg-num1 B` will store list "B"
        nargs type `1`
        - `NAME NAME` - or any other number will require 2 values 
        example: `--arg-num2 A B ` will store list "A;B"
        example: `--arg-num2 A B --arg-num2 C D` will store list "C;D"
        nargs type `2` bigger number will require denoted number of values   

  
  -h, --help            show this help message and exit
  --all
  --id ID [ID ...]
  -s SKIP, --skip SKIP
  -l LIMIT, --limit LIMIT

### Formating variables

Options can be passed as: 
-v 10
--verbose 10
-v=10
--verbose=10
  
If short option is exactly 2 letters long value can be passed directly after option:
-v10

Value after set value cannot start from with "-".

Setting is fully valid sets none/empty string as argument
-v=
--verbose=

