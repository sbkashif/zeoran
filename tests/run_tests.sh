#!/bin/bash

# Simple test runner for zeoran
# This script runs tests with fixed seeds to ensure reproducible results

# Set default seed if not specified
if [ -z "$RANDOM_SEED" ]; then
    export RANDOM_SEED=12345
    echo "Using default random seed: $RANDOM_SEED"
fi

# Define constants
ZEORAN_BINARY="/projects/academic/kaihangs/salmanbi/software/zeoran/build/bin/zeoran"
TEST_INPUT_DIR="benchmark_inputs"
TEST_OUTPUT_DIR="benchmark_outputs"

# Check if binary exists and is executable
if [ -x "$ZEORAN_BINARY" ]; then
    echo "Using binary: $ZEORAN_BINARY"
else
    echo "Error: Zeoran binary not found or not executable at $ZEORAN_BINARY"
    echo "Please build the project first."
    exit 1
fi

# Ensure output directory exists
mkdir -p $TEST_OUTPUT_DIR

# Function to run a single test case
run_test() {
    test_name=$1
    
    echo "Running test: $test_name with seed $RANDOM_SEED"
    
    # Create a temporary directory for test output
    test_output_dir="$TEST_OUTPUT_DIR/${test_name}"
    mkdir -p "$test_output_dir"
    
    # Copy the input file to the main directory with the standard name
    cp "$TEST_INPUT_DIR/${test_name}.input" "../generate.input"
    
    # Extract output directory from the input file (line 3)
    output_dir=$(sed -n '3p' "$TEST_INPUT_DIR/${test_name}.input")
    echo "Output directory specified in input file: $output_dir"
    
    # Create the output directory structure if it doesn't exist
    mkdir -p "../$output_dir"
    
    # Run the command with the specified seed
    cd ..
    
    # Always answer 'yes' to overwrite prompt
    echo "yes" | "$ZEORAN_BINARY"
    
    # Check if output directory exists and copy files to test output directory
    if [ -d "$output_dir" ]; then
        echo "Output files successfully created in $output_dir"
        
        # List the files that were created
        if ls "$output_dir"/*.cif 1> /dev/null 2>&1; then
            echo "Generated files:"
            ls -l "$output_dir"/*.cif
        else
            echo "Warning: No .cif files found in $output_dir"
        fi
    else
        echo "Warning: No output directory '$output_dir' found for test $test_name"
    fi
    
    cd tests
    echo "Test $test_name completed"
}

echo "========================================================"
echo "Starting Zeoran Tests with seed: $RANDOM_SEED"
echo "========================================================"

# Test cases
run_test "MOR_chains"
run_test "MOR_clusters"
run_test "MOR_merw"
run_test "MOR_random"
run_test "MFI_chains"
run_test "FAU_chains"

echo "========================================================"
echo "All Tests Completed"
echo "========================================================"
