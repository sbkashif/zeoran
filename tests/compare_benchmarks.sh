#!/bin/bash

# Simple script to compare benchmark outputs with reference benchmarks

echo "===== Comparing benchmark outputs with references ====="
differences=0

# Loop through all test cases in the reference directory
for ref_dir in benchmark_reference/*; do
    if [ -d "$ref_dir" ]; then
        test_name=$(basename "$ref_dir")
        echo "Checking test case: $test_name"
        
        # Check if output directory exists
        out_dir="benchmark_outputs/$test_name"
        if [ ! -d "$out_dir" ]; then
            echo "  ERROR: No output directory found for test $test_name"
            differences=$((differences + 1))
            continue
        fi
        
        # Compare each file in the reference directory
        for ref_file in "$ref_dir"/*.cif; do
            if [ -f "$ref_file" ]; then
                file_name=$(basename "$ref_file")
                out_file="$out_dir/$file_name"
                
                if [ ! -f "$out_file" ]; then
                    echo "  ERROR: Missing output file $file_name"
                    differences=$((differences + 1))
                    continue
                fi
                
                # Compare the files
                if diff -q "$ref_file" "$out_file" > /dev/null; then
                    echo "  PASS: $file_name matches reference"
                else
                    echo "  FAIL: $file_name differs from reference"
                    differences=$((differences + 1))
                fi
            fi
        done
        
        # Check for extra files in output directory
        for out_file in "$out_dir"/*.cif; do
            if [ -f "$out_file" ]; then
                file_name=$(basename "$out_file")
                ref_file="$ref_dir/$file_name"
                
                if [ ! -f "$ref_file" ]; then
                    echo "  ERROR: Extra output file $file_name"
                    differences=$((differences + 1))
                fi
            fi
        done
    fi
done

# Show summary
echo ""
echo "===== Comparison Summary ====="
if [ $differences -eq 0 ]; then
    echo "All tests PASSED: No differences found between benchmark outputs and references"
else
    echo "FAILED: Found $differences differences between benchmark outputs and references"
    echo "This suggests that code changes have affected the algorithm behavior"
fi

exit $differences
