cmake_minimum_required(VERSION 3.10)

# Project name and version
project(zeoran VERSION 1.0)

# Set C++ standard
set(CMAKE_CXX_STANDARD 11)
set(CMAKE_CXX_STANDARD_REQUIRED True)

# Options for static linking and Eigen path
option(STATIC "Enable static linking" OFF)
set(EIGEN_PATH "${CMAKE_INSTALL_PREFIX}/include/eigen3" CACHE PATH "Path to Eigen headers")

# Compiler flags
if(STATIC)
    set(CMAKE_EXE_LINKER_FLAGS "${CMAKE_EXE_LINKER_FLAGS} -static-libstdc++")
endif()

# Include directories
include_directories(${EIGEN_PATH})

# Source files
set(SOURCES
    zeoran.cpp
    global.h
    headers.h
    libraries.h
)

# Output directories
set(CMAKE_RUNTIME_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/bin)
set(CMAKE_LIBRARY_OUTPUT_DIRECTORY ${CMAKE_BINARY_DIR}/lib)

# Add executable
add_executable(zeoran ${SOURCES})

# Installation
install(TARGETS zeoran DESTINATION bin)
install(DIRECTORY zeoran_data/atom_sites DESTINATION share/zeoran)
install(DIRECTORY zeoran_data/unit_cell DESTINATION share/zeoran)
