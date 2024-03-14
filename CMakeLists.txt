cmake_minimum_required(VERSION 3.24)
project(example)

add_executable(${PROJECT_NAME})

target_sources(${PROJECT_NAME}
    PRIVATE
        src/main.cpp
)