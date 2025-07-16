#!/bin/bash

# Installation script for zeoran
# ---------------------------------------
# This script automates the installation of zeoran.

# Define installation paths
PREFIX=${PREFIX:-/usr/local}  # Default to /usr/local if not provided
EIGEN_PATH=${EIGEN_PATH:-/usr/local/include/eigen3}  # Default to /usr/local/include/eigen3 if not provided

# Load required modules (if applicable)
echo "Loading required modules..."
# Uncomment and modify the following line if modules are required
# module load gcc/11.2.0 eigen/3.4.0

# Build and install zeoran
echo "Building zeoran..."
make EIGEN_PATH="$EIGEN_PATH" STATIC=1 || { echo "Build failed. Exiting."; exit 1; }

echo "Installing zeoran to $PREFIX..."
make install PREFIX="$PREFIX" || { echo "Installation failed. Exiting."; exit 1; }

# Verify installation
if [ -f "$PREFIX/bin/zeoran" ]; then
    echo "Installation successful!"
    echo "Refer to the executable at $PREFIX/bin/zeoran"
    
    # Check for preprocessing script
    if [ -f "preprocess_cif.py" ]; then
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
