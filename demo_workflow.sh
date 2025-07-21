#!/bin/bash
# demo_workflow.sh
# Demonstrates the complete workflow for using zeoran with CIF file preprocessing

# Exit on error
set -e

echo "================================================="
echo "Zeoran Demo Workflow with CIF Preprocessing"
echo "================================================="

# Check if a CIF file was provided
if [ "$#" -ne 2 ]; then
    echo "Usage: $0 <cif_file> <zeolite_name>"
    echo "Example: $0 zeoran_data/cif_files/Framework_0_initial_1_1_1_P1.cif LTA"
    exit 1
fi

CIF_FILE=$1
ZEOLITE_NAME=$2

# Get absolute path to the repo directory for zeoran_data
REPO_DIR=$(cd "$(dirname "$0")" && pwd)

echo "Step 1: Preprocessing CIF file"
echo "-------------------------------------------------"
python preprocess_cif.py "$CIF_FILE" "$ZEOLITE_NAME"
echo ""

# Check if zeoran needs to be built
echo "Step 2: Checking zeoran installation"
echo "-------------------------------------------------"

# Check if zeoran is already built
if [ -f "./build/bin/zeoran" ]; then
    echo "✓ Zeoran is already built and ready to use."
    echo "  (No reinstallation needed when processing new CIF files)"
    echo ""
else
    echo "Zeoran not found. Building for first time..."
    echo "Select installation method:"
    echo "1) CMake (recommended)"
    echo "2) Traditional Make"
    read -p "Enter choice [1]: " INSTALL_CHOICE
    
    if [ -z "$INSTALL_CHOICE" ] || [ "$INSTALL_CHOICE" = "1" ]; then
        echo "Using CMake installation..."
        ./install_with_cmake.sh
    elif [ "$INSTALL_CHOICE" = "2" ]; then
        echo "Using traditional Make installation..."
        ./install_traditional_make.sh
    else
        echo "Invalid choice. Exiting."
        exit 1
    fi
    echo ""
fi

# Create input file
echo "Step 3: Setting up generate.input file"
echo "-------------------------------------------------"
echo "Select algorithm:"
echo "1) chains (Al atoms forming chains)"
echo "2) clusters (Al atoms in a spatial region)"
echo "3) merw (Maximal Entropy Random Walk)"
echo "4) random (Uniform distribution)"
read -p "Enter choice [4]: " ALG_CHOICE

if [ -z "$ALG_CHOICE" ] || [ "$ALG_CHOICE" = "4" ]; then
    ALGORITHM="random"
elif [ "$ALG_CHOICE" = "1" ]; then
    ALGORITHM="chains"
    # Check if using LTA_SI, which may have issues with chains algorithm
    if [[ "$ZEOLITE_NAME" == *"LTA"* ]]; then
        echo "⚠️  Warning: The 'chains' algorithm may fail with LTA structures due to their connectivity patterns."
        echo "   Consider using the 'random' algorithm instead for LTA structures."
        echo ""
        read -p "Do you want to continue with 'chains' algorithm anyway? (y/n) [n]: " CONTINUE_CHOICE
        if [ -z "$CONTINUE_CHOICE" ] || [ "$CONTINUE_CHOICE" != "y" ]; then
            echo "Switching to 'random' algorithm..."
            ALGORITHM="random"
        fi
    fi
elif [ "$ALG_CHOICE" = "2" ]; then
    ALGORITHM="clusters"
elif [ "$ALG_CHOICE" = "3" ]; then
    ALGORITHM="merw"
else
    echo "Invalid choice. Using random algorithm."
    ALGORITHM="random"
fi

# Create output directory
OUTPUT_DIR="Output_${ZEOLITE_NAME}_${ALGORITHM}"
mkdir -p "$OUTPUT_DIR"

# Create input file
INPUT_FILE="generate.input"
echo "Creating $INPUT_FILE..."
echo "$ZEOLITE_NAME" > "$INPUT_FILE"
echo "$ALGORITHM" >> "$INPUT_FILE"
echo "$OUTPUT_DIR" >> "$INPUT_FILE"
echo "10" >> "$INPUT_FILE"  # Number of structures

# Add algorithm-specific parameters
case $ALGORITHM in
    chains)
        echo "2" >> "$INPUT_FILE"  # Number of chains
        echo "5" >> "$INPUT_FILE"  # Length of first chain
        echo "5" >> "$INPUT_FILE"  # Length of second chain
        ;;
    clusters)
        echo "10" >> "$INPUT_FILE"  # Number of substitutions
        ;;
    merw)
        echo "10" >> "$INPUT_FILE"  # Number of substitutions
        echo "100" >> "$INPUT_FILE"  # Equilibration steps
        echo "10" >> "$INPUT_FILE"  # Number of visits
        ;;
    random)
        echo "10" >> "$INPUT_FILE"  # Number of substitutions
        ;;
esac

echo "Created $INPUT_FILE with the following content:"
cat "$INPUT_FILE"
echo ""

# Run zeoran
echo "Step 4: Running zeoran"
echo "-------------------------------------------------"

# Debug: Print the contents of the unit cell and atom sites files
echo "Debugging information:"
if [ -f "zeoran_data/unit_cell/${ZEOLITE_NAME}.txt" ]; then
    echo "Unit cell file content:"
    cat "zeoran_data/unit_cell/${ZEOLITE_NAME}.txt"
else
    echo "Warning: Unit cell file not found at zeoran_data/unit_cell/${ZEOLITE_NAME}.txt"
fi

echo ""
if [ -f "zeoran_data/atom_sites/${ZEOLITE_NAME}.txt" ]; then
    echo "First 5 lines of atom sites file:"
    head -n 5 "zeoran_data/atom_sites/${ZEOLITE_NAME}.txt"
    echo "Total lines in atom sites file: $(wc -l < "zeoran_data/atom_sites/${ZEOLITE_NAME}.txt")"
else
    echo "Warning: Atom sites file not found at zeoran_data/atom_sites/${ZEOLITE_NAME}.txt"
fi

echo ""
echo "Running zeoran..."

# Let zeoran use its natural data directory priority:
# 1. Current directory (./zeoran_data/) - for newly processed CIF files
# 2. Install location (build/share/zeoran/) - for standard zeolite database
# This means no reinstallation needed when processing new CIF files locally

# Try to run zeoran normally first
if [ -f "build/bin/zeoran" ]; then
    echo "Found zeoran in build/bin"
    
    # Set ZEORAN_DATA_DIR to point to repo's zeoran_data for organized structure
    export ZEORAN_DATA_DIR="$REPO_DIR/zeoran_data"
    echo "Setting ZEORAN_DATA_DIR to: $ZEORAN_DATA_DIR"
    
    # Run from current directory to ensure paths are correct
    echo "Attempting to run zeoran normally..."
    ./build/bin/zeoran < <(echo "yes")
    ZEORAN_EXIT_CODE=$?
    
    if [ $ZEORAN_EXIT_CODE -ne 0 ]; then
        echo "Zeoran exited with error code $ZEORAN_EXIT_CODE."
        echo "Trying with debug options..."
        
        cp build/bin/zeoran ./zeoran_debug
        
        # Check if gdb is available
        if command -v gdb &> /dev/null; then
            echo "Running with gdb to debug the crash:"
            ZEORAN_DATA_DIR="$REPO_DIR/zeoran_data" echo "run" | gdb -q ./zeoran_debug
        else
            echo "GDB not available, running with extra verbosity:"
            ZEORAN_DATA_DIR="$REPO_DIR/zeoran_data" ZEORAN_DEBUG=1 ./zeoran_debug < <(echo "yes")
        fi
        rm -f ./zeoran_debug
    else
        echo "Zeoran completed successfully."
    fi
elif [ -f "./bin/zeoran" ]; then
    echo "Found zeoran in ./bin"
    
    echo "Attempting to run zeoran normally..."
    ./bin/zeoran < <(echo "yes")
    ZEORAN_EXIT_CODE=$?
    
    if [ $ZEORAN_EXIT_CODE -ne 0 ]; then
        echo "Zeoran exited with error code $ZEORAN_EXIT_CODE."
        echo "Trying with debug options..."
        
        cp ./bin/zeoran ./zeoran_debug
        
        # Check if gdb is available
        if command -v gdb &> /dev/null; then
            echo "Running with gdb to debug the crash:"
            echo "run" | gdb -q ./zeoran_debug
        else
            echo "GDB not available, running with extra verbosity:"
            ZEORAN_DEBUG=1 ./zeoran_debug < <(echo "yes")
        fi
        rm -f ./zeoran_debug
    else
        echo "Zeoran completed successfully."
    fi
else
    echo "Error: Could not find zeoran executable. Please check installation."
    exit 1
fi

echo ""
if [ $? -eq 0 ]; then
    # Check if any output files were actually created
    if [ -z "$(ls -A "$OUTPUT_DIR")" ]; then
        echo "================================================="
        echo "⚠️  Warning: Workflow completed but no output files were created."
        echo "This may occur if:"
        echo " 1. The algorithm cannot find valid Al placements for this structure"
        echo " 2. The zeolite connectivity prevents the requested distribution pattern"
        echo ""
        echo "Try again with a different algorithm or parameters:"
        echo " - 'random' algorithm is most reliable for all structures"
        echo " - Reduce the number or length of chains for the 'chains' algorithm"
        echo " - Ensure the zeolite structure file is properly formatted"
        echo "================================================="
    else
        echo "================================================="
        echo "Workflow completed successfully!"
        echo "Check the '$OUTPUT_DIR' directory for results."
        echo "================================================="
    fi
else
    echo "================================================="
    echo "Error encountered while running zeoran."
    echo "Please check the debugging information above."
    echo "================================================="
fi
