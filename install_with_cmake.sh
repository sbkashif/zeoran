#!/bin/bash

# Installation script for zeoran using CMake
# ---------------------------------------
# This script automates the installation of zeoran using CMake.

# Define installation paths
PREFIX="$(pwd)/build"  # Installation will occur in the build directory
EIGEN_PATH="/projects/academic/kaihangs/salmanbi/software/eigen-3.4.0"  # Default Eigen path

# Define default install and eigen paths if not provided
if [ -z "$PREFIX" ]; then
    PREFIX="/usr/local"
    echo "Using default PREFIX: $PREFIX"
fi
if [ -z "$EIGEN_PATH" ]; then
    EIGEN_PATH="/usr/local/include/eigen3"
    echo "Using default EIGEN_PATH: $EIGEN_PATH"
fi


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
    echo "================================================="
    echo "✅ Installation successful!"
    echo "================================================="
    echo "Zeoran executable installed at: $PREFIX/bin/zeoran"
    echo ""
    
    # Add to PATH for current session and provide instructions for permanent addition
    ZEORAN_BIN_DIR="$PREFIX/bin"
    echo "Adding zeoran to PATH for current session..."
    export PATH="$ZEORAN_BIN_DIR:$PATH"
    
    echo ""
    echo "🔧 To make zeoran globally accessible:"
    echo "   Add the following line to your ~/.bashrc or ~/.bash_profile:"
    echo "   export PATH=\"$ZEORAN_BIN_DIR:\$PATH\""
    echo ""
    echo "   Then run: source ~/.bashrc"
    echo ""
    echo "🧪 After adding to PATH, you can run zeoran from anywhere:"
    echo "   zeoran"
    echo ""
    echo "📁 Data files installed at: $PREFIX/share/zeoran/"
    
    # Install preprocessing scripts to make them globally accessible
    if [ -f "../preprocess_cif.py" ]; then
        echo ""
        echo "Installing preprocessors..."
        
        # Install individual preprocessors
        cp "../preprocess_cif.py" "$PREFIX/bin/"
        chmod +x "$PREFIX/bin/preprocess_cif.py"
        
        if [ -f "../preprocess_gro.py" ]; then
            cp "../preprocess_gro.py" "$PREFIX/bin/"
            chmod +x "$PREFIX/bin/preprocess_gro.py"
        fi
        
        # Install universal preprocessor
        if [ -f "../preprocess" ]; then
            cp "../preprocess" "$PREFIX/bin/"
            chmod +x "$PREFIX/bin/preprocess"
        fi
        
        echo ""
        echo "📄 Universal Preprocessor (recommended):"
        echo "   preprocess -i file.cif -n ZEOLITE_NAME           # CIF files"
        echo "   preprocess -i file.gro -n ZEOLITE_NAME -c config.yaml  # GRO files"
        echo "   preprocess --help                               # Show all options"
        echo ""
        echo "📄 Individual Preprocessors also available:"
        echo "   preprocess_cif.py file.cif ZEOLITE_NAME [config.yaml]"
        echo "   preprocess_gro.py file.gro config.yaml ZEOLITE_NAME"
        echo ""
        echo "   After preprocessing, use ZEOLITE_NAME in your generate.input file."
    fi
    
    echo ""
    echo "🚀 Quick test (from this directory):"
    echo "   ./build/bin/zeoran"
    echo "   or if you added to PATH: zeoran"
    echo ""
    echo "🧪 Complete workflow test:"
    echo "   preprocess -i zeoran_data/cif_files/LTA_SI.cif -n LTA_SI"
    echo "   zeoran"
    echo "================================================="
else
    echo "Installation verification failed. Please check the output for errors."
    exit 1
fi
