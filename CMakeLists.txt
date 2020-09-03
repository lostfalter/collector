cmake_minimum_required(VERSION 3.1)

project(LogCollector)

include(cmake/build_helper.cmake)

add_subdirectory(producer)
add_subdirectory(consumer)


find_program(regularFormatter clang-format)
if(regularFormatter)
    # use collected format source files
    get_property(allFormatFiles GLOBAL PROPERTY ALL_FORMAT_SOURCE_FILES)
    if(allFormatFiles)
        # convert list to multi lines data
        string (REGEX REPLACE "(^|[^\\\\]);" "\\1\n" lines "${allFormatFiles}")
        file(WRITE ${CMAKE_CURRENT_BINARY_DIR}/format_file_list ${lines})
        add_custom_target(
            FormatAll ALL
            COMMAND python format.py -rq -f ${CMAKE_CURRENT_BINARY_DIR}/format_file_list
            WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
            COMMENT "Full format")

        if(TARGET FastFormat)
            add_dependencies(FormatAll FastFormat)
        endif()
    endif()
endif()