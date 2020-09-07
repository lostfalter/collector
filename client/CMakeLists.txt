cmake_minimum_required(VERSION 3.1)

project(client)

CollectSourceFiles(CLIENT_SOURCE_FILES ${PROJECT_SOURCE_DIR}/src)
add_executable(${PROJECT_NAME} ${CLIENT_SOURCE_FILES})
target_link_libraries(${PROJECT_NAME} PRIVATE
    CONAN_PKG::cppzmq CONAN_PKG::spdlog CONAN_PKG::nlohmann_json)
AutoFormatCode(${PROJECT_NAME} ${CLIENT_SOURCE_FILES})
