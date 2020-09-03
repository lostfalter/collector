cmake_minimum_required(VERSION 3.1)

project(producer)

CollectSourceFiles(PRODUCER_SOURCE_FILES ${PROJECT_SOURCE_DIR}/src)
add_executable(${PROJECT_NAME} ${PRODUCER_SOURCE_FILES})
AutoFormatCode(${PROJECT_NAME} ${PRODUCER_SOURCE_FILES})
