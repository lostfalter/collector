cmake_minimum_required(VERSION 3.1)

project(LogCollector)

add_compile_options(-std=c++11)

include(cmake/conan.cmake)
include(cmake/build_helper.cmake)

conan_cmake_run(REQUIRES cppzmq/4.6.0 boost/1.74.0 spdlog/1.7.0 nlohmann_json/3.9.1
                BASIC_SETUP CMAKE_TARGETS
                BUILD missing
                SETTINGS compiler.cppstd=11)

add_subdirectory(producer)
add_subdirectory(consumer)
add_subdirectory(server)
add_subdirectory(client)
add_subdirectory(demo)


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