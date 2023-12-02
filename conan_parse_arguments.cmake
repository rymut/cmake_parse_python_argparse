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