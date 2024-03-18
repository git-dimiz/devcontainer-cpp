cmake_minimum_required(VERSION 3.24)
project(example)

add_executable(${PROJECT_NAME})

target_sources(${PROJECT_NAME}
    PRIVATE
        src/main.cpp
)

if(CMAKE_EXPORT_COMPILE_COMMANDS)
    include(ProcessorCount)
    ProcessorCount(N)
    set(IWYU_TOOL_EXE "iwyu_tool.py" CACHE STRING "Optional path to a different executable")
    set(FIX_INCLUDES_EXE "fix_includes.py" CACHE STRING "Optional path to a different executable")
    set(RUN_CLANG_TIDY_EXE "run-clang-tidy" CACHE STRING "Optional path to a different executable")

    add_custom_target(iwyu
        COMMAND
        ${IWYU_TOOL_EXE}
        -p ${CMAKE_BINARY_DIR}
        --jobs ${N}
        -- -Xiwyu
        --error
        -Xiwyu
        --mapping_file=${CMAKE_SOURCE_DIR}/.lint/iwyu.imp
    )

    add_custom_target(fix-includes
        COMMAND
        ${IWYU_TOOL_EXE}
        -p ${CMAKE_BINARY_DIR}
        --jobs ${N}
        -- -Xiwyu
        --error
        -Xiwyu
        --mapping_file=${CMAKE_SOURCE_DIR}/.lint/iwyu.imp
        | ${FIX_INCLUDES_EXE}
        --noreorder
        --nosafe_headers
    )

    add_custom_target(clang-tidy
        COMMAND
        ${RUN_CLANG_TIDY_EXE}
        -p ${CMAKE_BINARY_DIR}
        -j ${N}
    )

    add_custom_target(check-format
        COMMAND
        find
        ${CMAKE_SOURCE_DIR}/src
        -iname '*.h' -o
        -iname '*.hpp' -o
        -iname '*.cpp'
        | xargs clang-format -n --Werror
    )

    add_custom_target(clang-format
        COMMAND
        find
        ${CMAKE_SOURCE_DIR}/src
        -iname '*.h' -o
        -iname '*.hpp' -o
        -iname '*.cpp'
        | xargs clang-format -i
    )
endif()