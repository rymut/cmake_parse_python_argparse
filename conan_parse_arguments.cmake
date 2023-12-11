cmake_minimum_required(VERSION 3.0)

find_program(CONAN_COMMAND "conan" REQUIRED)
set(_conan_command install)
execute_process(COMMAND ${CONAN_COMMAND} ${_conan_command} --help
    RESULT_VARIABLE _conan_result
    OUTPUT_VARIABLE _conan_stdout
    ERROR_VARIABLE conan_stderr
    ECHO_ERROR_VARIABLE    # show the text output regardless
    WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})

string(REGEX REPLACE ";" "\\\\;" _conan_stdout "${_conan_stdout}")
string(REGEX REPLACE "\n" ";" _conan_stdout "${_conan_stdout}")

unset(_pos_args)
unset(_opt_args)
# _states:
#   0 - none
#   1 - append positional
#   2 - append optional

set(_positional_args_literals "positional arguments:")
set(_optional_args_literals "options:" "optional arguments:")
set(_state 0)
foreach (_line IN LISTS _conan_stdout)
    if (_state EQUAL 0)
        list(FIND _positional_args_literals "${_line}" _positional_args_found)
        if (_positional_args_found GREATER -1)
            set(_positional_args_found TRUE)
        else()
            set(_positional_args_found FALSE)
        endif()
        
        list(FIND _optional_args_literals "${_line}" _optional_args_found)
        if (_optional_args_found GREATER -1)
            set(_optional_args_found TRUE)
        else()
            set(_optional_args_found FALSE)
        endif()
        if (_positional_args_found)
            set(_state 1)
        elseif (_optional_args_found)
            set(_state 2)
        endif()
    elseif ("${_line}" STREQUAL "") 
        set(_state 0)
    else()
        string(FIND "${_line}" "   " _pos)
        if (NOT _pos EQUAL 0) 
            if (_state EQUAL 1)
                list(APPEND _pos_args "${_line}")
            elseif (_state EQUAL 2)
                list(APPEND _opt_args "${_line}")
            endif()
        endif()
    endif()
#    message(STATUS "${_state}: '${_line}'")
endforeach()

# regex to match positional
unset(_output_pos_args_name)
unset(_output_pos_args_values)
unset(_output_pos_args_index)
set(_index -1)
foreach(_line IN LISTS _pos_args)
    math(EXPR _index "${_index} + 1")
    string(REGEX MATCH [[^  [a-z\-_]+]] _pos_match "${_line}")
    string(STRIP "${_pos_match}" _pos_match)
    if (NOT "${_pos_match}" STREQUAL "")
        message(STATUS "POS IN: '${_pos_match}'")
        string(TOUPPER "${_pos_match}" _pos_name)
        string(STRIP "${_pos_name}" _pos_name)
        list(APPEND _output_pos_args_name "${_pos_name}")
        list(APPEND _output_pos_args_index "${_index}")
        list(APPEND _output_pos_args_values "")
    endif()

    string(REGEX MATCH [[^  {[a-z\-_]+(,[a-z_]+(-[a-z_]+)*)*}]] _pos_match_multi "${_line}")
    if (NOT "${_pos_match_multi}" STREQUAL "")
        string(REPLACE "${_pos_match_multi}" "{" "" _value)
        string(REPLACE "${_value}" "}" "" _value)
        message(STATUS "POS: '${_pos_match_multi}'")
        list(APPEND _output_pos_args_name "ARG${_index}")
        list(APPEND _output_pos_args_index "${_index}")
        list(APPEND _output_pos_args_values "${_value}")
    endif()    
endforeach()

# Two types of positional values
#   POSITION    - have name can store ANY value
#   LITERAL     - dont have name but have set of values available

# Type of optional 
unset(_output_opt_args_name)
unset(_output_opt_args_short)
unset(_output_opt_args_full)
unset(_output_opt_args_value) # TRUE - has value, FALSE - never have value
unset(_output_opt_args_value_required) # TRUE - requird; FALSE optional - will be empty string
# regex to match begining 
foreach(_line IN LISTS _opt_args)
    string(REGEX MATCH [[^  --?[a-z:]+((-[a-z]+)*)?( [^ ]?[A-Z_:]+[^ ,]?)?(, --?[a-z:]+((-[a-z]+)*)?( [A-Z_:]+)?)?]] _opt_match "${_line}")
    if (NOT "${_opt_match}" STREQUAL "")
        string(STRIP "${_opt_match}" _opt_match)
        string(FIND "${_opt_match}" "--" _opt_long_pos)
        string(REPLACE ", " ";" _opt_match_list "${_opt_match}")
        list(LENGTH _opt_match_list _opt_has_alternative)
        string(REPLACE " " ";" _opt_match_list "${_opt_match_list}")
        list(REMOVE_ITEM _opt_match_list "")
        list(LENGTH _opt_match_list _opt_list_count)
        message("opt in: ${_opt_match_list}")
        unset(_opt_short)
        unset(_opt_full)
        unset(_opt_name)
        unset(_opt_value)
        set(_opt_value_requred TRUE)
        if (_opt_list_count GREATER 2 )
            list(GET _opt_match_list 1 _opt_value)
        elseif(_opt_list_count GREATER 1 AND _opt_has_alternative EQUAL 1)
            list(GET _opt_match_list 1 _opt_value)
        endif()
        if (DEFINED _opt_value)
            string(FIND "${_opt_value}" "[" _pos)
            if (_pos EQUAL 0)
                set(_opt_value_requred FALSE)
                string(REPLACE "[" "" _opt_value "${_opt_value}")
                string(REPLACE "]" "" _opt_value "${_opt_value}")
            endif()
            string(TOUPPER "${_opt_value}" _opt_name)
        endif()
        if (_opt_long_pos EQUAL -1)
            # only short argument
            list(GET _opt_match_list 0 _opt_short)
        elseif (_opt_long_pos EQUAL 0)
            # long first 
            # short might be next
            list(GET _opt_match_list 0 _opt_full)
            if (DEFINED _opt_value AND _opt_list_count GREATER 2)
                list(GET _opt_match_list 2 _opt_short)
            elseif (NOT DEFINED _opt_value AND _opt_list_count EQUAL 2)
                list(GET _opt_match_list 1 _opt_short)
            endif()
        else() 
            list(GET _opt_match_list 0 _opt_short)
            if ((DEFINED _opt_value)  AND _opt_list_count GREATER 2)
                list(GET _opt_match_list 2 _opt_full)
            elseif ((NOT DEFINED _opt_value) AND _opt_list_count EQUAL 2)
                list(GET _opt_match_list 1 _opt_full)
            endif()
        endif()
        if (NOT DEFINED _opt_name)
            if (DEFINED _opt_full)
                string(TOUPPER "${_opt_full}" _opt_name)
                string(SUBSTRING "${_opt_name}" 2 -1 _opt_name)
            elseif (DEFINED _opt_short)
                string(TOUPPER "${_opt_short}" _opt_name)
                string(SUBSTRING "${_opt_name}" 1 -1 _opt_name)
            endif()
            string(REPLACE "-" "_" _opt_name "${_opt_name}")
        endif()
        message("OPT: ${_opt_name} short '${_opt_short}' full '${_opt_full}', value: '${_opt_value}', value required '${_opt_value_requred}'")
        list(APPEND _output_opt_args_name "${_opt_name}")
        list(APPEND _output_opt_args_short "${_opt_short}")
        list(APPEND _output_opt_args_full "${_opt_full}")
        if (DEFINED _opt_value)
            list(APPEND _output_opt_args_value TRUE)
        else()
            list(APPEND _output_opt_args_value FALSE) 
        endif()
        list(APPEND _output_opt_args_value_required "${_opt_value_requred}")        
    else()
        message(FATAL_ERROR "Cannot format parameter '${_line}' please report issue with the project")
    endif()
endforeach()


#[=======================================================================[.rst:
_argparse_sanatize_name
~~~~~~~~~~~~~~~~~~~~~~~

NAME - name to set
ARGN - list of names
returns first matching
#]=======================================================================]
function(_argparse_sanatize_name NAME)
    foreach (_name IN ITEMS ${ARGN})
        string(REGEX REPLACE "^[:_-]+" "" _name "${_name}")
        string(REGEX REPLACE "[:_-]+$" "" _name "${_name}")
        string(REGEX REPLACE "[^a-zA-Z0-9:_-]" "" _name "${_name}")
        if (NOT _name STREQUAL "")
            string(REGEX REPLACE "[:_-]" "_" _name "${_name}")
            string(TOUPPER "${_name}" _name)
            set(${NAME} "${_name}" PARENT_SCOPE)
            return()
        endif()
    endforeach()
    message(FATAL_ERROR "Not valid ARGN")
endfunction()

#[=======================================================================[.rst:
_argparse
~~~~~~~~~

ARG
METAVAR - value name (or upercase LONG )
NARGS - numberic, ?, *, +
CHOICES - list of CHOICE values
REQUIRED - if string does not start with '[' literal
parse INPUT

choice or metavar - matches regex '[a-zA-Z0-9][a-zA-Z0-9_:-]*'
optional value starts with `[` and ands with `]` literal 
* value is `[metavar ...]`
+ value is `metavar [metavar ...]`
? value is `[metavar]`
numer value conains `metavar( metavar)*`
chocies are `{choise(,choice)}`
#]=======================================================================]
function(_args_split INPUT SHORT LONG)
    string(STRIP "${INPUT}" _input)
    string(REGEX REPLACE ";" "\\\\;" _input "${_input}")

    # logic the same
    # -s VALUE, --long VALUE  comment
    # | ||    | |           ^- args_end
    # | ||    | ^- long_beg
    # | ||    ^- sep_beg
    # | |^- value_beg
    # | ^- arg_end
    # ^- arg_beg=0

    # -s VALUE  comment
    # | ||    ^- args_end
    # | |^- value_beg
    # | ^- arg_end
    # ^- arg_beg=0
    # sep_beg = -1, 
    # long_beg = -1

    # --long VALUE  comment
    # |     ||    ^- args_len
    # |     |^- value_beg
    # |     ^- arg_end
    # ^- long_beg = arg_beg = 0
    # sep_beg = -1, 

    string(FIND "${_input}" "  " _args_len)
    string(SUBSTRING "${_input}" 0 ${_args_len} _args)
    string(FIND "${_args}" ", " _arg0_end)
    string(FIND "${_args}" "-" _arg0_beg)
    set(_arg0_len ${_arg0_end})
    if (_arg0_end EQUAL -1)
        set(_arg1_beg 0)
        set(_arg1_len 0)
    else()
        math(EXPR _arg1_beg "${_arg0_end} + 2")
        math(EXPR _arg1_len "${_args_len} - ${_arg1_beg}")
    endif()
    set(_arg0 "")
    if (_arg0_len GREATER 0) 
        string(SUBSTRING "${_args}" ${_arg0_beg} ${_arg0_len} _arg0)
    endif()
    set(_arg1 "")
    if (_arg1_len GREATER 0) 
        string(SUBSTRING "${_args}" ${_arg1_beg} ${_arg1_len} _arg1)
    endif()
    string(FIND "${_args}" "--" _long_pos)
    if (_long_pos EQUAL -1)
        set(_long_text "")
        set(_short_text "${_arg0}")
    elseif(_long_pos EQUAL 0) 
        set(_long_text "${_arg0}")
        set(_short_text "${_arg1}")
    else()
        set(_long_text "${_arg1}")
        set(_short_text "${_arg0}")
    endif()
    string(STRIP "${_long_text}" _long_text)
    string(STRIP "${_short_text}" _short_text)
    set(${SHORT} "${_short_text}" PARENT_SCOPE)
    set(${LONG} "${_long_text}" PARENT_SCOPE)
endfunction()

function(_arg_parse INPUT PREFIX)
    string(STRIP "${INPUT}" _arg)
    string(FIND "${_arg}" " " _name_end)
    string(FIND "${_arg}" "-" _name_beg)
    string(LENGTH "${_arg}" _arg_len)
    set(_value_beg 0)
    set(_value_len 0)
    if (_name_end EQUAL -1)
        set(_name_end ${_arg_len})
    else()
        math(EXPR _value_beg "${_name_end} + 1")
        if (_name_end GREATER_EQUAL _arg_len)
            set(_value_beg 0)
        else()
            math(EXPR _value_len "${_arg_len} - ${_value_beg}")
        endif()
    endif()
    set(_name_len 0)
    if (_name_end GREATER _name_beg)
        math(EXPR _name_len "${_name_end} - ${_name_beg}")
    endif()
    string(SUBSTRING "${_arg}" ${_name_beg} ${_name_len} _name)
    string(SUBSTRING "${_arg}" ${_value_beg} ${_value_len} _value)
    set(${PREFIX}_NAME "${_name}" PARENT_SCOPE)
    set(${PREFIX}_VALUE "${_value}" PARENT_SCOPE)
endfunction()

#[=======================================================================[.rst:
_arg_value
~~~~~~~~~~

.. code-block:: cmake

  _arg_value(<OUTPUT> <NARG> <NAME> <CHOCISES>)

Set output to format of value of <NARG> type name and choices
#]=======================================================================]
function(_arg_value output narg name choices)
    if (NOT "${choices}" STREQUAL "")
        set(name "{${choices}}")
    endif()
    set(_value "")
    if ("${narg}" STREQUAL "?")
        set(_value "[${name}]")
    elseif ("${narg}" STREQUAL "*")
        set(_value "[${name} ...]")
    elseif ("${narg}" STREQUAL "+")
        set(_value "${name} [${name} ...]")
    elseif ("${narg}" STREQUAL "1")
        set(_value "${name}")
    elseif ("${narg}" GREATER 1)
        set(_value "${name}")
        foreach(item RANGE 2 ${narg} 1)
            set(_value "${_value} ${name}")
        endforeach()
    else()
        set(_value "")
    endif()
    set(${output} "${_value}" PARENT_SCOPE)
endfunction()

#[=======================================================================[.rst:
_arg_value_parse
~~~~~~~~~~~~~~~~

.. code-block:: cmake

  _arg_value_parse(<INPUT> <PREFIX>)

Function used to split single option to its name, input formats:
- `-<short> --<long> [value_format]`
- `--<long> -<short> [value_format]`
- `-<short> [value_format]`
- `--<long> [value_format]`

Where `<short> is short name argument, and `long` is long name argument.
Values format is optional and should be written as an uppercase:
- no value (narg=0) - flag
- `[NAME]` - optional single or none value (narg=?)
- `[NAME ...]` - optional single or many values (narg=*)
- `NAME [NAME ...]` - required one or many values (narg=+)
- `NAME NAME` - two required values (narg=2) and so on.

Name of value can consists of any characters except `{}[] ;.`
Special case is chooice values then `NAME` must match regex:
``{[a-zA-Z_0-9]+(,[a-zA-Z_0-9]+)+}`` - name output will be "".

``<PREFIX>_NAME`` - name of optional value
    set to "" if argument is flag or choices option, 
    not empty string for value
``<PREFIX>_NARG`` - type of arguments
    - 0 - no arguments requrired (flag only) - empty string as input,
    - <n> - number or arguments required
      where n > 0 require n-arugments, for example
      storted as `VALUE VALUE` for 2 etc.,
    - '?' none or one argument (argument not required) - stored as `[VALUE]`,
    - '*' none or more arguments - sored as `[VALUE ...]`,
    - '+' at least one or more arguments (required) - stored as `VALUE [VALUE ...]`
``<PREFIX>_CHOICES`` - choices to select - "" if type can be any string list of arguments  
    extracted from `{[a-z_]+(,[a-z]+)+}` regex with VALUE

Required can be computed from ``<PREFIX>_NARGS``

#]=======================================================================]
function(_arg_value_parse INPUT PREFIX)
    string(STRIP "${INPUT}" _input)
    if (_input STREQUAL "")
        # no value string - this is flag
        set(_name "")
        set(_nargs "")
        set(_choices "")
    else()
        string(FIND "${_input}" "{" _curly_bracket_beg)
        string(FIND "${_input}" "}" _curly_bracket_end)
        set(_values "${_input}")
        if ((${_curly_bracket_beg} GREATER -1) AND (${_curly_bracket_end} GREATER -1))
            math(EXPR _choices_beg "${_curly_bracket_beg} + 1")
            math(EXPR _choices_len "${_curly_bracket_end} - ${_choices_beg}")
            if (_choices_len LESS_EQUAL 0)
                message(FATAL_ERROR "Invalid value wrong syntax { } positions in string `${_input}`")
            endif()
            string(SUBSTRING "${_input}" ${_choices_beg} ${_choices_len} _choices)
            string(REPLACE "{${_choices}}" "CHOICES" _values "${_input}")
        elseif(NOT (${_curly_bracket_beg} EQUAL -1 AND ${_curly_bracket_end} EQUAL -1))
            message(FATAL_ERROR "Invalid value wrong syntax invalid { } in string `${_input}`")
        endif()
        string(REPLACE MATCH [[\s\s+]] " " _values "${_values}")
        string(STRIP "${_values}" _values)
        string(FIND "${_values}" "[" _first_squere_bracket_open_pos)
        string(FIND "${_values}" "]" _first_squere_bracket_close_pos)
        string(FIND "${_values}" " " _first_space_pos)

        math(EXPR _value_beg "${_first_squere_bracket_open_pos} + 1")
        if (_value_beg GREATER _first_space_pos AND _first_space_pos GREATER -1)
            set(_value_beg 0)
        endif()
        string(LENGTH "${_values}" _value_end)
        if (_first_squere_bracket_close_pos GREATER_EQUAL 0)
            SET(_value_end ${_first_squere_bracket_close_pos})
        endif()
        if (_first_space_pos GREATER_EQUAL 0 AND _first_space_pos LESS _value_end)
            set(_value_end ${_first_space_pos})
        endif()
        math(EXPR _value_len "${_value_end} - ${_value_beg}")
        string(SUBSTRING "${_values}" ${_value_beg} ${_value_len} _name)
    
        string(REPLACE " " ";" _values_list "${_values}")
        string(FIND "${_values}" "..." _dots_pos)
        if (_dots_pos GREATER -1)
            if ("${_values}" STREQUAL "[${_name} ...]")
                set(_narg "*")
            elseif("${_values}" STREQUAL "${_name} [${_name} ...]")
                set(_narg "+")
            endif()
        else()
            if ("${_values}" STREQUAL "[${_name}]")
                set(_narg "?")
            elseif("${_values}" STREQUAL "${_name}")
                set(_narg 1)
            else()
                list(LENGTH _values_list _narg)
                list(REMOVE_ITEM _values_list "${_name}")
                if (NOT "${_values_list}" STREQUAL "")
                    message(FATAL_ERROR "invalid N element argument format")
                endif()
            endif()
        endif()
    endif()
    # sanity checks
    if ("${_narg}" STREQUAL "")
        set(_name "")
        set(_nargs "")
        set(_choices "")
    endif()
    _arg_value(_target_values "${_narg}" "${_name}" "${_choices}")
    if (NOT "${_target_values}" STREQUAL "${_input}")
        set(_name "")
        set(_nargs "")
        set(_choices "")
    endif()
    if (NOT "${_choices}" STREQUAL "")
        set(_name "")
        string(REGEX MATCH [[^[a-zA-Z_0-9]+(,[a-zA-Z_0-9]+)+$]] _choices_match "${_choices}")
        if (NOT _choices_match)
            set(_name "")
            set(_nargs "")
            set(_choices "")
        endif()
    endif()
    # setting output
    string(TOUPPER "${_name}" _name)
    message(STATUS "${_input} = ${_name}: ${_narg} (${_choices})")
    set(${PREFIX}_NAME "${_name}" PARENT_SCOPE)
    set(${PREFIX}_NARG "${_narg}" PARENT_SCOPE)
    set(${PREFIX}_CHOICES "${_choices}" PARENT_SCOPE)
endfunction()

_args_split("  --test VALUE, -t VALUE [VALUE ...]  ; testing ;" SHORT_RAW LONG_RAW)
_arg_parse("${SHORT_RAW}" SHORT_RAW)

message("VALUE STRING '${SHORT_RAW_VALUE}'")
_arg_value_parse("" VAL)
_arg_value_parse("VALUE" VAL)
_arg_value_parse("VALUE VALUE" VAL)
_arg_value_parse("[VALUE]" VAL)
_arg_value_parse("[VALUE ...]" VAL)
_arg_value_parse("VALUE [VALUE ...]" VAL)
_arg_value_parse("" VAL)
_arg_value_parse("{aa,bb}" VAL)
_arg_value_parse("{aa,bb} {aa,bb}" VAL)
_arg_value_parse("{aa,bb} {aa,bb} {aa,bb} {aa,bb} {aa,bb} {aa,bb}" VAL)
_arg_value_parse("[{aa,bb}]" VAL)
_arg_value_parse("[{aa,bb} ...]" VAL)
_arg_value_parse("{aa,bb} [{aa,bb} ...]" VAL)
_arg_value_parse("{aaA,1 bb} [{aa,1bb} ...]" VAL)

#[=======================================================================[.rst:
it uses argparse form python 
it will ouotput it by 
```bash
> python prog.py --help
usage: prog.py [-h] echo

positional arguments:
  echo

options:
  -h, --help  show this help message and exit
```

find `positional arguments' 

#]=======================================================================]
