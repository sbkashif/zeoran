#!/bin/bash

# Installation script for zeoran using CMake
# ---------------------------------------
# This script automates the installation of zeoran using CMake.

# Define installation paths
PREFIX="$(pwd)/build"  # Installation will occur in the build directory
EIGEN_PATH="/projects/academic/kaihangs/salmanbi/software/eigen-3.4.0"  # Default Eigen path

# Clone the repository
echo "Using the repository path: /projects/academic/kaihangs/salmanbi/software/zeoran"
cd /projects/academic/kaihangs/salmanbi/software/zeoran || { echo "Failed to enter repository directory. Exiting."; exit 1; }

# Create build directory
mkdir -p build && cd build || { echo "Failed to create or enter build directory. Exiting."; exit 1; }

# Configure the build with CMake
echo "Configuring the build with CMake..."
cmake .. -DCMAKE_INSTALL_PREFIX="$PREFIX" -DEIGEN_PATH="$EIGEN_PATH" || { echo "CMake configuration failed. Exiting."; exit 1; }

# Build the software
echo "Building zeoran..."
make || { echo "Build failed. Exiting."; exit 1; }

# Install the software
echo "Installing zeoran to $PREFIX..."
make install || { echo "Installation failed. Exiting."; exit 1; }

# Verify installation
if [ -f "$PREFIX/bin/zeoran" ]; then
    echo "Installation successful!"
    echo "Refer to the executable at $PREFIX/bin/zeoran"
    
    # Check for preprocessing script
    if [ -f "../preprocess_cif.py" ]; then
        echo ""
        echo "CIF Preprocessing: You can use the preprocessing script to prepare CIF files:"
        echo "  python preprocess_cif.py path/to/your/file.cif ZEOLITE_NAME"
        echo ""
        echo "After preprocessing, use ZEOLITE_NAME in your generate.input file."
    fi
else
    echo "Installation verification failed. Please check the output for errors."
    exit 1
fi
