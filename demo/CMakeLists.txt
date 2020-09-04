cmake_minimum_required(VERSION 3.1)

project(demo)

CollectSourceFiles(DEMO_SOURCE_FILES ${PROJECT_SOURCE_DIR}/src)
add_executable(${PROJECT_NAME} ${DEMO_SOURCE_FILES})
target_link_libraries(${PROJECT_NAME} PRIVATE CONAN_PKG::boost)

AutoFormatCode(${PROJECT_NAME} ${DEMO_SOURCE_FILES})

add_dependencies(${PROJECT_NAME} producer)
add_dependencies(${PROJECT_NAME} consumer)

add_custom_command(
    TARGET demo 
    PRE_BUILD
    COMMAND ${CMAKE_COMMAND} -E copy
        $<TARGET_FILE:producer>
        $<TARGET_FILE_DIR:demo>
    COMMAND ${CMAKE_COMMAND} -E copy
        $<TARGET_FILE:consumer>
        $<TARGET_FILE_DIR:demo>
)
