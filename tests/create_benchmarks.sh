#!/bin/bash

# Script to create benchmark references
# This will save the current outputs as reference benchmarks

echo "Creating benchmark references from current outputs..."

# Define directories
OUTPUT_DIR="benchmark_outputs"
REFERENCE_DIR="benchmark_reference"

# Ensure reference directory exists
mkdir -p $REFERENCE_DIR

# Copy all outputs to reference directory
cp -r $OUTPUT_DIR/* $REFERENCE_DIR/

echo "Reference benchmarks created successfully in $REFERENCE_DIR"
echo "These will be used for comparison when testing code changes."
