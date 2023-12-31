cmake_minimum_required(VERSION 3.0)

if(POLICY CMP0054)
  cmake_policy(SET CMP0054 NEW)
endif()

#[=======================================================================[.rst:
_arg_sanatize_name
~~~~~~~~~~~~~~~~~~

.. code-block:: cmake

  _arg_sanatize_name(<OUTPUT> <INPUT> [<INPUT> ...])

``<OUTPUT>`` - variable that will contain sanitized name
``<INPUT>`` - input text
#]=======================================================================]
function(_arg_sanatize_name output)
  foreach(item IN ITEMS ${ARGN})
    string(REGEX REPLACE "^[:_-]+" "" name "${item}")
    string(REGEX REPLACE "[:_-]+$" "" name "${name}")
    string(REGEX REPLACE "[^a-zA-Z0-9:_-]" "" name "${name}")
    if(NOT name STREQUAL "")
      string(REGEX REPLACE "[:_-]" "_" name "${name}")
      string(TOUPPER "${name}" name)
      set(${output}
          "${name}"
          PARENT_SCOPE)
      return()
    endif()
  endforeach()
  message(FATAL_ERROR "Not valid ARGN")
endfunction()

#[=======================================================================[.rst:
_arg_optional_arguments_split
~~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: cmake

  _arg_optional_arguments_split(<INPUT> <SHORT> <LONG> <ORDER>)

``<INPUT>`` - string containing optional arguments line, can contain
              comment
``<SHORT>`` - variable name where short part with value will be stored
``<LONG>`` - variable name where short part with value will be stored
``<ORDER>`` - 0 if short argument is first, 1 if long argument is first
#]=======================================================================]
function(_arg_optional_arguments_split text short long long_first)
  string(STRIP "${text}" input)
  string(REGEX REPLACE ";" "\\\\;" input "${input}")

  string(FIND "${input}" "  " args_len)
  if(${args_len} EQUAL -1)
    string(LENGTH "${input}" args_len)
  endif()
  string(SUBSTRING "${input}" 0 ${args_len} args)
  string(FIND "${args}" ", " arg0_end)
  string(FIND "${args}" "-" arg0_beg)
  set(arg0_len ${arg0_end})
  if(arg0_end EQUAL -1)
    set(arg1_beg 0)
    set(arg1_len 0)
  else()
    math(EXPR arg1_beg "${arg0_end} + 2")
    math(EXPR arg1_len "${args_len} - ${arg1_beg}")
  endif()
  set(arg0 "")
  if(arg0_end GREATER_EQUAL -1)
    string(SUBSTRING "${args}" ${arg0_beg} ${arg0_len} arg0)
  endif()
  set(arg1 "")
  if(arg1_len GREATER 0)
    string(SUBSTRING "${args}" ${arg1_beg} ${arg1_len} arg1)
  endif()
  string(FIND "${args}" "--" _long_pos)
  if(_long_pos EQUAL -1)
    set(long_text "")
    set(short_text "${arg0}")
    set(order 0)
  elseif(_short_pos EQUAL -1)
    set(long_text "${arg0}")
    set(short_text "")
    set(order 1)
  elseif(_long_pos EQUAL 0)
    set(long_text "${arg0}")
    set(short_text "${arg1}")
    set(order 1)
  else()
    set(long_text "${arg1}")
    set(short_text "${arg0}")
    set(order 0)
  endif()
  string(STRIP "${long_text}" long_text)
  string(STRIP "${short_text}" short_text)
  set(${short}
      "${short_text}"
      PARENT_SCOPE)
  set(${long}
      "${long_text}"
      PARENT_SCOPE)
  set(${long_first}
      "${order}"
      PARENT_SCOPE)
endfunction()

#[=======================================================================[.rst:
_arg_optional_argument_split
~~~~~~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: cmake

  _arg_optional_argument_split(<INPUT> <NAME> <VALUE>)

``<INPUT>`` - string containing argument with optional value to split
``<NAME>`` - string containing name of argument (--<name> or -<name>)
``<VALUE>`` - string containing value of argument
#]=======================================================================]
function(_arg_optional_argument_split text name_out value_out)
  string(STRIP "${text}" arg)
  string(FIND "${arg}" " " name_end)
  string(FIND "${arg}" "-" name_beg)
  string(LENGTH "${arg}" arg_len)
  set(value_beg 0)
  set(value_len 0)
  if(name_end EQUAL -1)
    set(name_end ${arg_len})
  else()
    math(EXPR value_beg "${name_end} + 1")
    if(name_end GREATER_EQUAL arg_len)
      set(value_beg 0)
    else()
      math(EXPR value_len "${arg_len} - ${value_beg}")
    endif()
  endif()
  set(name_len 0)
  if(name_end GREATER name_beg)
    math(EXPR name_len "${name_end} - ${name_beg}")
  endif()
  string(SUBSTRING "${arg}" ${name_beg} ${name_len} name)
  string(SUBSTRING "${arg}" ${value_beg} ${value_len} value)
  set(${name_out}
      "${name}"
      PARENT_SCOPE)
  set(${value_out}
      "${value}"
      PARENT_SCOPE)
endfunction()

#[=======================================================================[.rst:
_arg_optional_parse
~~~~~~~~~~~~~~~~~~~

.. code-block:: cmake

  _arg_optional_parse(<PREFIX> <OPTS>)

``<PREFIX>`` - prefix used to set values
``<OPTS>`` - List which each contains optional argument line

Outputs:
``<PREFIX>_NAME`` - Name of value
``<PREFIX>_USAGE`` - part which will be used during usage help
``<PREFIX>_SHORT`` - short part
``<PREFIX>_LONG`` - long part
``<PREFIX>_NARG`` - type of value
``<PREFIX>_CHOICES`` - chocies comma separated
#]=======================================================================]
function(_arg_optional_parse prefix opts)
  set(name "")
  set(usage "")
  set(short "")
  set(long "")
  set(narg "")
  set(choices "")
  foreach(opt IN LISTS opts)
    _arg_optional_arguments_split("${opt}" optshort optlong optorder)
    if((NOT optshort) AND (NOT optlong))
      message(FATAL_ERROR "invalid option '${opt}' '${optshort}' '${optlong}'")
    endif()
    if(optshort)
      _arg_optional_argument_split("${optshort}" optshortname optshort_value)
      string(SUBSTRING "${optshortname}" 1 -1 optname_fallback)
    else()
      set(optshortname "")
      set(optshort_value "")
    endif()
    if(optlong)
      _arg_optional_argument_split("${optlong}" optlongname optlong_value)
      string(SUBSTRING "${optlongname}" 2 -1 optname_fallback)
    else()
      set(optlongname "")
      set(optlong_value "")
    endif()
    if("${optorder}" EQUAL "0")
      set(optusage "${optshort}")
      set(opt_value "${optshort_value}")
    else()
      set(optusage "${optlong}")
      set(opt_value "${optlong_value}")
    endif()
    _arg_value_parse("${opt_value}" optname optnarg optchoices)
    if(NOT optname)
      _arg_sanatize_name(optname "${optname_fallback}")
    endif()
    set(name "${name};${optname}")
    set(usage "${usage};${optusage}")
    set(short "${short};${optshortname}")
    set(long "${long};${optlongname}")
    set(narg "${narg};${optnarg}")
    set(choices "${choices};${optchoices}")
  endforeach()
  if(NOT "${name}" STREQUAL "")
    string(SUBSTRING "${name}" 1 -1 name)
    string(SUBSTRING "${usage}" 1 -1 usage)
    string(SUBSTRING "${short}" 1 -1 short)
    string(SUBSTRING "${long}" 1 -1 long)
    string(SUBSTRING "${narg}" 1 -1 narg)
    string(SUBSTRING "${choices}" 1 -1 choices)
  endif()
  set("${prefix}_NAME"
      "${name}"
      PARENT_SCOPE)
  set("${prefix}_USAGE"
      "${usage}"
      PARENT_SCOPE)
  set("${prefix}_SHORT"
      "${short}"
      PARENT_SCOPE)
  set("${prefix}_LONG"
      "${long}"
      PARENT_SCOPE)
  set("${prefix}_NARG"
      "${narg}"
      PARENT_SCOPE)
  set("${prefix}_CHOICES"
      "${choices}"
      PARENT_SCOPE)
endfunction()

#[=======================================================================[.rst:
_arg_output_split
~~~~~~~~~~~~~~~~~

.. code-block:: cmake

  _arg_output_split(<USAGE> <POS> <OPT> <INPUT> <COMMAND> <ARGS>)

Split output to usage lines, positional lines optional lines and input
lines
#]=======================================================================]
function(
  _arg_output_split
  usage
  pos
  opt
  text
  cmd
  args)
  string(REGEX REPLACE ";" "\\\\;" input "${text}")
  string(REGEX REPLACE "\n" ";" input "${input}")

  set(usage_args_literals "usage:")
  set(positional_args_literals "positional arguments:")
  set(optional_args_literals "options:" "optional arguments:")
  set(skip_startswith "   ")
  set(arg_text_separator "  ")

  set(has_pos FALSE)
  set(has_opt FALSE)
  set(has_use FALSE)
  unset(use_lines)
  unset(use_line)
  unset(pos_lines)
  unset(optlines)

  # State machine to process input _states: "ready" - 0 "use" - 1 usage "pos" -
  # 2 append positional "opt" - 3 - append optional
  set(state "ready")
  foreach(line IN LISTS input)
    if("${state}" STREQUAL "ready")
      set(next_state "${state}")
      if(NOT has_use)
        foreach(literal IN LISTS usage_args_literals)
          string(FIND "${line}" "${literal}" literal_pos)
          if(${literal_pos} EQUAL 0)
            string(LENGTH "${literal}" literal_len)
            string(SUBSTRING "${line}" ${literal_len} -1 line)
            set(has_use TRUE)
            set(next_state "use")
            break()
          endif()
        endforeach()
      endif()
      if(next_state STREQUAL state AND NOT has_pos)
        list(FIND positional_args_literals "${line}" literal_pos)
        if(${literal_pos} GREATER -1)
          set(next_state "pos")
        endif()
      endif()
      if(next_state STREQUAL state AND NOT has_opt)
        list(FIND optional_args_literals "${line}" literal_pos)
        if(${literal_pos} GREATER -1)
          set(next_state "opt")
        endif()
      endif()
      set(state "${next_state}")
    elseif("${line}" STREQUAL "")
      set(state "ready")
    else()
      string(FIND "${line}" "${skip_startswith}" _pos)
      if(NOT _pos EQUAL 0)
        string(STRIP "${line}" line)
        string(FIND "${line}" "${arg_text_separator}" _line_pos)
        string(SUBSTRING "${line}" 0 ${_line_pos} line)
        if("${state}" STREQUAL "pos")
          list(APPEND pos_lines "${line}")
        elseif("${state}" STREQUAL "opt")
          list(APPEND optlines "${line}")
        endif()
      endif()
    endif()
    if(state STREQUAL "use")
      string(STRIP "${line}" line)
      string(FIND "${line}" "${cmd}" _part_pos)
      string(FIND "${line}" " " _space_pos)
      if(${_part_pos} EQUAL 0)
        math(EXPR _start_pos "${_space_pos}+1")
        string(SUBSTRING "${line}" ${_start_pos} -1 line)
        string(FIND "${line}" "${args} " _part_pos)
        if(${_part_pos} EQUAL 0 AND NOT args STREQUAL "")
          string(LENGTH "${args} " _start_pos)
          string(SUBSTRING "${line}" ${_start_pos} -1 line)
        endif()
      endif()

      if("${use_line}" STREQUAL "")
        set(use_line "${line}")
      else()
        set(use_line "${use_line} ${line}")
      endif()
    elseif(NOT use_line STREQUAL "")
      list(APPEND use_lines "${use_line}")
      set(use_line "")
      set(has_use FALSE)
    endif()
  endforeach()

  # regex to match positional
  set("${usage}"
      "${use_lines}"
      PARENT_SCOPE)
  set("${pos}"
      "${pos_lines}"
      PARENT_SCOPE)
  set("${opt}"
      "${optlines}"
      PARENT_SCOPE)
endfunction()

#[=======================================================================[.rst:
_arg_value
~~~~~~~~~~

.. code-block:: cmake

  _arg_value(<OUTPUT> <NARG> <NAME> <CHOCISES>)

Set output to format of value of <NARG> type name and choices
#]=======================================================================]
function(_arg_value output narg name choices)
  if(NOT "${choices}" STREQUAL "")
    set(name "{${choices}}")
  endif()
  set(value "")
  if("${narg}" STREQUAL "?")
    set(value "[${name}]")
  elseif("${narg}" STREQUAL "*")
    set(value "[${name} ...]")
  elseif("${narg}" STREQUAL "+")
    set(value "${name} [${name} ...]")
  elseif("${narg}" STREQUAL "1")
    set(value "${name}")
  elseif("${narg}" GREATER 1)
    set(value "${name}")
    foreach(item RANGE 2 ${narg} 1)
      set(value "${value} ${name}")
    endforeach()
  else()
    set(value "")
  endif()
  set(${output}
      "${value}"
      PARENT_SCOPE)
endfunction()

#[=======================================================================[.rst:
_arg_value_parse
~~~~~~~~~~~~~~~~

.. code-block:: cmake

  _arg_value_parse(<INPUT> <NAME> <NARG> <CHOICES>)

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

``<NAME>`` - name of optional value
    set to "" if argument is flag or choices option,
    not empty string for value
``<NARG>`` - type of arguments
    - 0 - no arguments required (flag only) - empty string as input,
    - <n> - number or arguments required
      where n > 0 require n-arugments, for example
      storted as `VALUE VALUE` for 2 etc.,
    - '?' none or one argument (argument not required) - stored as `[VALUE]`,
    - '*' none or more arguments - sored as `[VALUE ...]`,
    - '+' at least one or more arguments (required) - stored as `VALUE [VALUE ...]`
``<CHOICES>`` - choices to select - "" if type can be any string list of arguments
    extracted from `{[a-z_]+(,[a-z]+)+}` regex with VALUE

Required can be computed from ``<NARGS>``

#]=======================================================================]
function(_arg_value_parse text name_out narg_out choices_out)
  string(STRIP "${text}" input)
  if(input STREQUAL "")
    # no value string - this is flag
    set(name "")
    set(narg "0")
    set(choices "")
  else()
    string(FIND "${input}" "{" curly_bracket_beg)
    string(FIND "${input}" "}" curly_bracket_end)
    set(values "${input}")
    set(choices "")
    if((${curly_bracket_beg} GREATER -1) AND (${curly_bracket_end} GREATER -1))
      math(EXPR choices_beg "${curly_bracket_beg} + 1")
      math(EXPR choices_len "${curly_bracket_end} - ${choices_beg}")
      if(choices_len LESS_EQUAL 0)
        message(
          FATAL_ERROR
            "Invalid value wrong syntax { } positions in string `${input}`")
      endif()
      string(SUBSTRING "${input}" ${choices_beg} ${choices_len} choices)
      string(REPLACE "{${choices}}" "CHOICES" values "${input}")
    elseif(NOT (${curly_bracket_beg} EQUAL -1 AND ${curly_bracket_end} EQUAL -1
               ))
      message(
        FATAL_ERROR
          "Invalid value wrong syntax invalid { } in string `${input}`")
    endif()
    string(REPLACE MATCH [[\s\s+]] " " values "${values}")
    string(STRIP "${values}" values)
    string(FIND "${values}" "[" _first_squere_bracket_open_pos)
    string(FIND "${values}" "]" _first_squere_bracket_close_pos)
    string(FIND "${values}" " " _first_space_pos)

    math(EXPR value_beg "${_first_squere_bracket_open_pos} + 1")
    if(value_beg GREATER _first_space_pos AND _first_space_pos GREATER -1)
      set(value_beg 0)
    endif()
    string(LENGTH "${values}" value_end)
    if(_first_squere_bracket_close_pos GREATER_EQUAL 0)
      set(value_end ${_first_squere_bracket_close_pos})
    endif()
    if(_first_space_pos GREATER_EQUAL 0 AND _first_space_pos LESS value_end)
      set(value_end ${_first_space_pos})
    endif()
    math(EXPR value_len "${value_end} - ${value_beg}")
    string(SUBSTRING "${values}" ${value_beg} ${value_len} name)

    string(REPLACE " " ";" values_list "${values}")
    string(FIND "${values}" "..." dots_pos)
    if(dots_pos GREATER -1)
      if("${values}" STREQUAL "[${name} ...]")
        set(narg "*")
      elseif("${values}" STREQUAL "${name} [${name} ...]")
        set(narg "+")
      endif()
    else()
      if("${values}" STREQUAL "[${name}]")
        set(narg "?")
      elseif("${values}" STREQUAL "${name}")
        set(narg 1)
      else()
        list(LENGTH values_list narg)
        list(REMOVE_ITEM values_list "${name}")
        if(NOT "${values_list}" STREQUAL "")
          message(FATAL_ERROR "invalid N element argument format")
        endif()
      endif()
    endif()
  endif()
  # sanity checks
  if("${narg}" STREQUAL "")
    set(name "")
    set(narg "")
    set(choices "")
  endif()
  _arg_value(_targetvalues "${narg}" "${name}" "${choices}")
  if(NOT "${_targetvalues}" STREQUAL "${input}")
    set(name "")
    set(narg "")
    set(choices "")
  endif()
  if(NOT "${choices}" STREQUAL "")
    set(name "")
    string(REGEX MATCH [[^[a-zA-Z_0-9]+(,[a-zA-Z_0-9]+)+$]] choices_match
                 "${choices}")
    if(NOT choices_match)
      set(name "")
      set(narg "")
      set(choices "")
    endif()
  endif()

  # setting output
  string(TOUPPER "${name}" name)
  set(${name_out}
      "${name}"
      PARENT_SCOPE)
  set(${narg_out}
      "${narg}"
      PARENT_SCOPE)
  set(${choices_out}
      "${choices}"
      PARENT_SCOPE)
endfunction()

#[=======================================================================[.rst:
_arg_get_command_output
~~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: cmake

  _arg_get_command_output(<OUTPUT> <COMMAND> <OPTION> [<HELP> ...])

get command output:

``<OUTPUT>`` - where to store stdout stream
``<COMMAND>`` - command to find
``<OPTION>`` - option to set to command
``<HELP>`` - help flag by default equal `-h`

Output will result stdout for command, or empty string if command
is not found, or result code is different than 0
#]=======================================================================]
function(_arg_get_command_output output_var command_name command_option)
  find_program(command_filepath "${command_name}" REQUIRED NO_CACHE)
  set(command_help "${ARGN}")
  if("${command_help}" STREQUAL "")
    set(command_help "-h")
  endif()
  set(command_output "")
  if(command_filepath)
    execute_process(
      COMMAND ${command_filepath} ${command_option} ${command_help}
      RESULT_VARIABLE command_result
      OUTPUT_VARIABLE command_output
      ERROR_VARIABLE command_error ECHO_ERROR_VARIABLE # show the text output
                                                       # regardless
      WORKING_DIRECTORY ${CMAKE_CURRENT_BINARY_DIR})
    if(NOT ${command_result} EQUAL 0)
      set(command_output "")
    endif()
  endif()
  set("${output_var}"
      "${command_output}"
      PARENT_SCOPE)
endfunction()

#[=======================================================================[.rst:
_arg_parse_usage
~~~~~~~~~~~~~~~~~~~~~~

.. code-block:: cmake

  _arg_parse_usage(<PREFIX> <USAGE> <ARGS>)

get command output:

``<PREFIX>`` - where to store stdout stream
``<USAGE>`` - command to find
``args`` - argument to pass
#]=======================================================================]
function(_arg_parse_usage usage)

endfunction()

function(sort_by_length out_var idx_var short long)
  set(out "")
  set(idx "")
  set(max_len "0")
  list(LENGTH short short_count)
  list(LENGTH long long_count)
  if(NOT ${short_count} EQUAL ${long_count})
    message(FATAL_ERROR "list must have the same number of elements")
  endif()
  if(${short_count} EQUAL 0)
    set(${out_var}
        ""
        PARENT_SCOPE)
    set(${idx_var}
        ""
        PARENT_SCOPE)
    return()
  endif()
  math(EXPR count "${short_count} - 1")

  foreach(item IN LISTS short long)
    string(LENGTH "${item}" item_len)
    if("${item_len}" GREATER "${max_len}")
      set(max_len ${item_len})
    endif()
  endforeach()
  if("${max_len}" GREATER 0)
    foreach(len RANGE ${max_len} 1 -1)
      foreach(index RANGE 0 ${count} 1)
        list(GET long ${index} opt)
        string(LENGTH "${opt}" opt_len)
        if("${opt_len}" EQUAL "${len}")
          set(out "${out};${opt}")
          set(idx "${idx};${index}")
        endif()
        list(GET short ${index} opt)
        string(LENGTH "${opt}" opt_len)
        if("${opt_len}" EQUAL "${len}")
          set(out "${out};${opt}")
          set(idx "${idx};${index}")
        endif()
      endforeach()
    endforeach()
    if(NOT "${out}" STREQUAL "")
      list(REMOVE_AT out 0)
      list(REMOVE_AT idx 0)
    endif()
  endif()
  set(${out_var}
      "${out}"
      PARENT_SCOPE)
  set(${idx_var}
      "${idx}"
      PARENT_SCOPE)
endfunction()

#[=======================================================================[.rst:
_arg_parse_find_arg
~~~~~~~~~~~~~~~~~~~

.. code-block:: cmake

  _arg_parse_find_arg(<INDEX> <HAS_VALUE> <VALUE> <ARGUMENT> [<LENGTH_SORTED_ARGS> ...])


``<INDEX>`` - -1 if element was not found or list is empty
``<HAS_VALUE>`` - TRUE if value is found false otherwise
``<VALUE>`` - "" if no value is found or value otherwise
``<ARGUMENT>`` - argument to parse
``<ARGN>`` - sorted by length arguments
#]=======================================================================]
function(_arg_parse_find_arg index_var has_value_var value_var argument)
  list(LENGTH ARGN argn_count)
  set(index -1)
  set(has_value FALSE)
  set(val "")
  if(NOT "${argn_count}" EQUAL "0")

    math(EXPR argn_count "${argn_count} - 1")
    foreach(argn_index RANGE 0 ${argn_count} 1)
      list(GET ARGN ${argn_index} item)
      # check argument
      if("${item}" STREQUAL "${argument}")
        set(index "${argn_index}")
        break()
      endif()
      # check --?.+=<value>
      string(FIND "${argument}" "${item}=" pos_with_equal)
      if("${pos_with_equal}" EQUAL "0")
        set(index "${argn_index}")
        string(LENGTH "${item}=" opt_with_equal_count)
        set(has_value TRUE)
        string(SUBSTRING "${argument}" ${opt_with_equal_count} -1 val)
        break()
      endif()
      # check if "\-.<value>"
      string(LENGTH "${item}" item_count)
      string(FIND "${argument}" "${item}" pos_no_equal)
      if(("${item_count}" EQUAL "2") AND ("${pos_no_equal}" EQUAL "0"))
        set(index "${argn_index}")
        set(has_value TRUE)
        string(SUBSTRING "${argument}" 2 -1 val)
        break()
      endif()
    endforeach()
  endif()
  set(${index_var}
      ${index}
      PARENT_SCOPE)
  set(${has_value_var}
      ${has_value}
      PARENT_SCOPE)
  set(${value_var}
      ${val}
      PARENT_SCOPE)
endfunction()

#[=======================================================================[.rst:
_arg_is_value
~~~~~~~~~~~~~

.. code-block:: cmake

  _arg_is_value(<OUTPUT> <TEXT>)

Check if ``<TEXT>`` is value, value cannot start with `-`

``<OUTPUT>`` - set to TRUE if ``<TEXT>`` can be value, false otherwise
``<TEXT>`` - text to check
#]=======================================================================]
function(_arg_is_value out_var text)
  string(FIND "${text}" "-" pos)
  if("${pos}" EQUAL "0")
    set(${out_var}
        FALSE
        PARENT_SCOPE)
  else()
    set(${out_var}
        TRUE
        PARENT_SCOPE)
  endif()
endfunction()

#[=======================================================================[.rst:
_arg_append_value
~~~~~~~~~~~~~~~~~

.. code-block:: cmake

  _arg_append_value(<VAR> <VAL>)

Append variable to list ``<VAR>``.

``<VAR>`` - variable name
``<VAL>`` - value
#]=======================================================================]
macro(_ARG_APPEND_VALUE var val)
  if(DEFINED ${var})
    set(${var} "${${var}};${val}")
  else()
    set(${var} "${val}")
  endif()
endmacro()

#[=======================================================================[.rst:
_arg_parse
~~~~~~~~~~

.. code-block:: cmake

  _arg_parse(<PREFIX> <COMMAND_NAME> <COMMAND_OPTION> <USED> [<INPUT> ...])

get command output:

``<PREFIX>`` - where to store stdout stream
``<COMMAND_NAME>`` - command to find
``<COMAND_OPTION>`` - argument to pass
``<USED>`` - used variables
``<INPUT>`` - input

Reserved parameter names:
``<PREFIX>_UNPARSED_ARGUMENTS`` - store argument that were not parsed

#]=======================================================================]
function(_arg_parse prefix command_name command_args used)
  # get parse values
  _arg_get_command_output(command_output "${command_name}" "${command_args}")
  _arg_output_split(command_usage command_positional command_optional
                    "${command_output}" "${command_name}" "${command_args}")
  # prase arguments
  _arg_optional_parse(opts "${command_optional}")

  foreach(opt_name IN LISTS opts_NAME)
    unset(${prefix}_${opt_name} PARENT_SCOPE)
    unset(local_${opt_name})
  endforeach()
  sort_by_length(opts_sorted opts_index "${opts_SHORT}" "${opts_LONG}")
  list(LENGTH opts_sorted opts_sorted_count)
  if("${opts_sorted}" EQUAL "0")
    # to do setting values output
    message(FATAL_ERROR "no option to be parsed")
    return()
  endif()
  math(EXPR opts_sorted_count "${opts_sorted_count} - 1")
  set(arguments "${ARGN}")
  set(positionals "")
  unset(arg_unparsed)
  while(NOT "${arguments}" STREQUAL "")
    list(GET arguments 0 argument)
    list(REMOVE_AT arguments 0)
    _arg_parse_find_arg(sorted_pos has_val val "${argument}" ${opts_sorted})
    if("${sorted_pos}" EQUAL -1)
      _arg_is_value(is_value "${argument}")
      if(is_value)
        set(positionals "${positionals};${argument}")
      else()
        list(APPEND arg_unparsed "${argument}")
      endif()
      continue()
    endif()
    list(GET opts_index ${sorted_pos} opt_index)
    list(GET opts_NAME ${opt_index} opt_name)
    list(GET opts_NARG ${opt_index} opt_narg)
    list(GET opts_CHOICES ${opt_index} opt_choices)
    if(has_val)
      set(can_have_equal "+;?;*;1")
      list(FIND can_have_equal "${opt_narg}" can_have_equal_pos)
      if("${opt_narg}" EQUAL "0")
        message(
          WARNING "Optional argument '${argument}' should not have a value")
      elseif("${can_have_equal_pos}" EQUAL "-1")
        message(
          FATAL_ERROR
            "Optional argument should not be passed by '=' in argument '${argument}' of type ${opt_narg}"
        )
      endif()
      message("=${val}")
      _arg_append_value(local_${opt_name} "${val}")
    elseif(NOT "${opt_narg}" STREQUAL "0")
      if("${opt_narg}" STREQUAL "?" OR "${opt_narg}" STREQUAL "*")
        if("${arguments}" STREQUAL "")
          # no arguments left
          continue()
        endif()
        list(GET arguments 0 argument_value)
        _arg_is_value(is_value "${argument_value}")
        if(is_value)
          list(REMOVE_AT arguments 0)
          _arg_append_value(local_${opt_name} "${argument_value}")
        endif()
      else()
        set(count "${opt_narg}")
        if("${opt_narg}" STREQUAL "+")
          set(count "1")
        endif()
        list(LENGTH arguments arguments_count)
        if("${arguments_count}" < "${count}")
          message(
            FATAL_ERROR
              "argument '${argument}' requires ${count} values but ${arguments_count} is passed"
          )
        endif()
        math(EXPR count "${count} - 1")
        set(values "")
        foreach(offset RANGE 0 count)
          list(GET arguments ${offset} argument_value)
          _arg_is_value(is_value "${argument_value}")
          if(NOT is_value)
            message(
              FATAL_ERROR
                "Value is required for argument '${argument}' but '${argument_value}' is found"
            )
          endif()
          set(values "${values};${argument_value}")
        endforeach()
        list(REMOVE_AT 0 values)
        _arg_append_value(local_${opt_name} "${values}")
      endif()
    endif()
  endwhile()

  unset(arg_used)
  foreach(opt_name IN LISTS opts_NAME)
    if(DEFINED local_${opt_name})
      set(${prefix}_${opt_name}
          "${local_${opt_name}}"
          PARENT_SCOPE)
      list(APPEND arg_used "${opt_name}")
    endif()
  endforeach()
  if(DEFINED arg_unparsed)
    list(APPEND arg_used "UNPARSED_ARGUMENTS")
    set(${prefix}_UNPARSED_ARGUMENTS
        "${arg_unparsed}"
        PARENT_SCOPE)
  endif()
  set(${used}
      "${arg_used}"
      PARENT_SCOPE)
endfunction()
