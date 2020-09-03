##
# @brief this file provides util function to build project
##
CMAKE_MINIMUM_REQUIRED(VERSION 2.8)

# collect source files under folder and automatically generate source group in IDE
function(CollectSourceFiles sourceFiles sourceDir)
    function(PopulateSourceFolder sourceDir allSources sourceGroupFolder)
        function(CreateSourceGroups groupStart sources root)
            foreach(CURRENT_FILE ${sources})
                get_filename_component(DIR_PATH ${CURRENT_FILE} DIRECTORY)
                file(RELATIVE_PATH SOURCE_GROUP_PATH ${root} ${DIR_PATH})
                if(SOURCE_GROUP_PATH)
                    string(REPLACE "/" "\\" SOURCE_GROUP_PATH ${SOURCE_GROUP_PATH})
                    string(REPLACE "\\" "\\\\" SOURCE_GROUP_PATH ${SOURCE_GROUP_PATH})
                endif()
                source_group("${groupStart}\\${SOURCE_GROUP_PATH}" FILES ${CURRENT_FILE})
            endforeach(CURRENT_FILE)
        endfunction(CreateSourceGroups)

        file(GLOB_RECURSE CURRENT_SOURCES
                 ${sourceDir}/*.cpp
                 ${sourceDir}/*.c
                 ${sourceDir}/*.cc)
        file(GLOB_RECURSE CURRENT_HEADERS
                 ${sourceDir}/*.h
                 ${sourceDir}/*.hpp)
        set(${allSources} ${CURRENT_SOURCES} ${CURRENT_HEADERS} PARENT_SCOPE)

        CreateSourceGroups("${sourceGroupFolder}\\Sources" "${CURRENT_SOURCES}" ${sourceDir})
        CreateSourceGroups("${sourceGroupFolder}\\Headers" "${CURRENT_HEADERS}" ${sourceDir})
    endfunction(PopulateSourceFolder)

    # try to collect files by typical structure
    PopulateSourceFolder(${sourceDir}/include API_HEADER "Api")
    PopulateSourceFolder(${sourceDir}/src CURRENT_SRC "")
    set(${sourceFiles} ${API_HEADER} ${CURRENT_SRC} PARENT_SCOPE)
    if (NOT API_HEADER AND NOT CURRENT_SRC)
        # try to collect files directly
        PopulateSourceFolder(${sourceDir} ALL_SRC "")
        set(${sourceFiles} ${ALL_SRC} PARENT_SCOPE)
    endif()
endfunction(CollectSourceFiles)

function(AddUnitTest srcFolder libName dependLibs...)
    include_directories(${PROJECT_SOURCE_DIR}/${srcFolder}/src)
    CollectSourceFiles(SRC_UNITTEST ${PROJECT_SOURCE_DIR}/${srcFolder})

    set(dependencies ${ARGV2})
    foreach(arg IN LISTS ARGN)
        set(dependencies ${dependencies} ${arg})
    endforeach()

    if(ENABLE_TEST_BUNDLE)
        find_package(XCTest REQUIRED)
        set(BUNDLE_NAME ${libName}Tests)

        # First two parameters are bundle name and target library name.
        # It's important since Xcode will auto generate connection between them.
        target_link_libraries(${libName} PRIVATE ${dependencies})
        tn_add_framework(${libName} Security)
        xctest_add_bundle(${BUNDLE_NAME} ${libName}
            ${SRC_UNITTEST} ${CMAKE_SOURCE_DIR}/cmake/gtest_loader.mm)
        # test bundle doesn't support unity build
        set_target_properties(${BUNDLE_NAME} PROPERTIES UNITY_BUILD OFF)
        # Do not add internal dependencies here, or cmake will generate
        # additional test schemes, which is really annoy.
        # So we use private link command instead on static libraries.

        # Test name doesn't matter and will not be added into RUN_TESTS target.
        xctest_add_test(XCTest.${BUNDLE_NAME} ${BUNDLE_NAME})
    endif()

    if(ENABLE_UNIT_TEST)
        set(TARGET_NAME ${libName}Unittest)
        add_executable(${TARGET_NAME} ${SRC_UNITTEST})
        tn_add_framework(${TARGET_NAME} Security)
        target_link_libraries(${TARGET_NAME} ${libName} ${dependencies})
        target_compile_definitions(${TARGET_NAME} PUBLIC TASDK_NO_EXPORT)

        set(UNIT_TEST_REPORT_PATH ${CMAKE_SOURCE_DIR}/build/test_result/${PROJECT_NAME}/)

        if(ENABLE_COVERAGE)
            set_target_properties(${TARGET_NAME} PROPERTIES LINK_FLAGS "--coverage")

            set(COVERAGE_DIR ${CMAKE_SOURCE_DIR}/build/coverage/${PROJECT_NAME}/)

            set(COVERAGE_PIECE_PATH ${CMAKE_SOURCE_DIR}/build/TASDK-${CMAKE_PLATFORM}/)
            set(COVERAGE_FILE ${COVERAGE_DIR}${TARGET_NAME}.info)
            set(COVERAGE_XML ${COVERAGE_DIR}coverage.xml)
            set(COVERAGE_RESULT ${COVERAGE_DIR})

            set(CollectCoverage ${TARGET_NAME}Coverage)
            add_custom_target(${CollectCoverage} ALL
                COMMAND ${CMAKE_COMMAND} -E remove_directory ${COVERAGE_DIR}
                COMMAND ${CMAKE_COMMAND} -E make_directory ${COVERAGE_DIR}
                COMMAND ${CMAKE_COMMAND} -E remove_directory ${UNIT_TEST_REPORT_PATH}
                COMMAND ${CMAKE_COMMAND} -E make_directory ${UNIT_TEST_REPORT_PATH}
                COMMAND ${LCOV_PATH} -d ${COVERAGE_PIECE_PATH} -z -q
                COMMAND ${TARGET_NAME} --gtest_output=xml:${UNIT_TEST_REPORT_PATH}
                COMMAND ${LCOV_PATH} -d ${COVERAGE_PIECE_PATH} -d ${PROJECT_SOURCE_DIR}/src -d ${PROJECT_SOURCE_DIR}/include --no-external --rc lcov_branch_coverage=1 -c -o ${COVERAGE_FILE}
                COMMAND ${GENHTML_PATH} ${COVERAGE_FILE} --branch-coverage -o ${COVERAGE_RESULT}
                COMMAND python ${CMAKE_SOURCE_DIR}/tools/coverage/lcov_cobertura.py ${COVERAGE_FILE} -b . -o ${COVERAGE_XML}
                DEPENDS ${TARGET_NAME}
                WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                COMMENT "Collect coverage data for ${TARGET_NAME}")

            if(ENABLE_SONAR_SCANNER)
                get_property(coverageDependencies GLOBAL PROPERTY SonarAnalyzeDependencies)
                set(coverageDependencies ${coverageDependencies} ${CollectCoverage})
                if(TARGET SonarAnalyze)
                    message(STATUS "Add dependencies for SonarAnalyze: ${coverageDependencies}")
                    add_dependencies(SonarAnalyze ${coverageDependencies})
                elseif()
                    message(STATUS "No sonar target")
                endif()
                set_property(GLOBAL PROPERTY SonarAnalyzeDependencies ${coverageDependencies})
            endif()
        else()
            add_test(NAME ${TARGET_NAME} COMMAND ${TARGET_NAME})
            add_custom_target(CTEST_${TARGET_NAME} ALL
                COMMAND ${CMAKE_CTEST_COMMAND} --output-on-failure
                POST_BUILD COMMAND ${TARGET_NAME} --gtest_output=xml:${UNIT_TEST_REPORT_PATH}
                DEPENDS ${TARGET_NAME})
        endif()
    endif()
endfunction(AddUnitTest)

# Auto format code when build target on local machine
function(AutoFormatCode targetName sources...)
    if (NOT DEFINED ENV{JENKINS_HOME})
        if(NOT TARGET FastFormat)
            find_program(fastFormatter git-clang-format)
            if(fastFormatter)
                set(DEFAULT_EXTENSIONS "c,h,C,H,cpp,hpp,cc,hh,c++,h++,cxx,hxx")
                add_custom_target(FastFormat
                    COMMAND python ${fastFormatter} -f --style file --extensions ${DEFAULT_EXTENSIONS}
                    WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
                    COMMENT "Fast format")
            else()
                add_custom_target(FastFormat
                    COMMENT "Empty fast format")
            endif()
        endif()
        add_dependencies(${targetName} FastFormat)

        # collect all format source files
        set(FORMAT_SOURCE_FILES ${ARGV1})
        foreach(arg IN LISTS ARGN)
            set(FORMAT_SOURCE_FILES ${FORMAT_SOURCE_FILES} ${arg})
        endforeach()

        get_property(allFormatFiles GLOBAL PROPERTY ALL_FORMAT_SOURCE_FILES)
        set(allFormatFiles ${allFormatFiles} ${FORMAT_SOURCE_FILES})
        set_property(GLOBAL PROPERTY ALL_FORMAT_SOURCE_FILES ${allFormatFiles})
    endif()
endfunction()

##
# Add framework library to the target on OSX
#
# @param[in]  targetName    the name of the target
# @param[in]  frameworks    a list of names of framework library
##
function(tn_add_framework targetName frameworks)
    if(DEFINED TN_PLATFORM_OSX)
        set(FRAMEWORK_NAMES ${frameworks})
        foreach(arg IN LISTS ARGN)
            set(FRAMEWORK_NAMES ${FRAMEWORK_NAMES} ${arg})
        endforeach()

        foreach(frameworkName IN LISTS FRAMEWORK_NAMES)
            target_link_libraries(${targetName} PRIVATE "-framework ${frameworkName}")
        endforeach()
    endif()
endfunction(tn_add_framework)
