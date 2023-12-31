if(NOT CMAKE_SCRIPT_MODE_FILE)
  message(FATAL_ERROR "usage: cmake -P ${CMAKE_CURRENT_LIST_FILE}")
  return()
endif()
include("${CMAKE_CURRENT_LIST_DIR}/../conan_parse_arguments.cmake")

set(CMD_NAME "conan")
set(CMD_ARGS "install")
set(CMD_HELP "-h")
_arg_get_command_output(CMD_STDOUT "${CMD_NAME}" "${CMD_ARGS}" ${CMD_HELP})
_arg_output_split(USE POS OPT "${CMD_STDOUT}" "${CMD_NAME}" "${CMD_ARGS}")
#[[
message("output:")
foreach(line IN LISTS USE)
  message("USE: '${line}'")
endforeach()
message("")
foreach(line IN LISTS OPT)
  message("OPT: '${line}'")
endforeach()
message("")
foreach(line IN LISTS POS)
  message("POS: '${line}'")
endforeach()
message("")

_arg_optional_parse(RES "${OPT}")

list(LENGTH RES_NAME LEN)
if(${LEN} GREATER 0)
  math(EXPR LEN "${LEN}-1")
  foreach(idx RANGE 0 ${LEN} 1)
    list(GET RES_NAME ${idx} ARG_NAME)
    list(GET RES_LONG ${idx} ARG_LONG)
    list(GET RES_SHORT ${idx} ARG_SHORT)
    list(GET RES_USAGE ${idx} ARG_USAGE)
    list(GET RES_NARG ${idx} ARG_NARG)
    message("OPT ${idx}: "
            "'${ARG_NAME}' long: '${ARG_LONG}' short: '${ARG_SHORT}' "
            "usage: '${ARG_USAGE}', narg: ${ARG_NARG}")
  endforeach()
endif()
#]]

_arg_parse(
  test ${CMD_NAME} "${CMD_ARGS}" ARG_USED
  "--build=never;-vtrace;-pr:a=default;-pr:h=msvc;-b=libh264;-p:a=test")
message("used args ${ARG_USED}")
message("unparsed args: ${test_UNPARSED_ARGUMENTS}")
