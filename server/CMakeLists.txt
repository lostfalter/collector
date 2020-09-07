cmake_minimum_required(VERSION 3.1)

project(server)

CollectSourceFiles(SERVER_SOURCE_FILES ${PROJECT_SOURCE_DIR}/src)
add_executable(${PROJECT_NAME} ${SERVER_SOURCE_FILES})
target_link_libraries(${PROJECT_NAME} PRIVATE CONAN_PKG::cppzmq CONAN_PKG::spdlog)
AutoFormatCode(${PROJECT_NAME} ${SERVER_SOURCE_FILES})
