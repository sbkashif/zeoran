#!/bin/bash
# test_cif_processing.sh
#
# This script tests the CIF preprocessing functionality by:
# 1. Preprocessing various CIF files 
# 2. Comparing the generated structures with reference structures
# 3. Reporting success or failure

set -e  # Exit on any error

# Set color codes for output
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Navigate to project root
cd "$(dirname "$0")/.."
ROOT_DIR=$(pwd)

echo -e "${YELLOW}=========================================${NC}"
echo -e "${YELLOW}     Testing CIF File Preprocessing      ${NC}"
echo -e "${YELLOW}=========================================${NC}"

# Make sure the Python script exists
if [ ! -f "preprocess_cif.py" ]; then
    echo -e "${RED}Error: preprocess_cif.py not found in project root${NC}"
    exit 1
fi

# Check for Python and ASE
if ! command -v python &> /dev/null; then
    echo -e "${RED}Error: Python not found. Please install Python.${NC}"
    exit 1
fi

# Try to import ASE to check if it's installed
python -c "import ase" &> /dev/null
if [ $? -ne 0 ]; then
    echo -e "${RED}Error: ASE (Atomic Simulation Environment) not found.${NC}"
    echo "Please install ASE with: pip install ase"
    exit 1
fi

# Create a temporary directory for test outputs
TEST_DIR="${ROOT_DIR}/tests/temp_cif_test"
mkdir -p "$TEST_DIR"

# Test function for preprocessing and comparison
test_cif_processing() {
    local cif_file=$1
    local framework=$2
    local reference_file=$3
    
    echo -e "\nTesting: ${YELLOW}${framework}${NC} (${cif_file})"
    
    # Preprocess the CIF file
    echo "Preprocessing CIF file..."
    python preprocess_cif.py "$cif_file" "${framework}_test" 2>&1 | tee "$TEST_DIR/${framework}_preprocess.log"
    
    if [ ! -f "zeoran_data/atom_sites/${framework}_test.txt" ]; then
        echo -e "${RED}Error: Failed to generate atom_sites file for ${framework}${NC}"
        return 1
    fi
    
    if [ ! -f "zeoran_data/unit_cell/${framework}_test.txt" ]; then
        echo -e "${RED}Error: Failed to generate unit_cell file for ${framework}${NC}"
        return 1
    fi
    
    # Compare with reference if provided
    if [ -n "$reference_file" ] && [ -f "$reference_file" ]; then
        echo "Comparing with reference structure..."
        
        # Use the comparison script
        python tests/compare_structures.py "$reference_file" "zeoran_data/atom_sites/${framework}_test.txt" --bin-size 0.01 | tee "$TEST_DIR/${framework}_comparison.log"
        
        # Check if comparison was successful
        if grep -q "Overall structural similarity: 100.00%" "$TEST_DIR/${framework}_comparison.log"; then
            echo -e "${GREEN}✓ Structure matches reference (100% similarity)${NC}"
            return 0
        else
            echo -e "${RED}✗ Structure does not match reference${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠ No reference file provided for comparison${NC}"
        return 0
    fi
}

# Run tests for each test case
echo "Running CIF processing tests..."

# Test 1: LTA_SI with reference to LTA
echo -e "\n${YELLOW}Test 1: LTA_SI (with symmetry operations)${NC}"
test_cif_processing "zeoran_data/cif_files/LTA_SI.cif" "LTA_SI" "zeoran_data/atom_sites/LTA.txt"
TEST1_RESULT=$?

# Add more tests as needed
# test_cif_processing "path/to/cif" "framework_name" "path/to/reference"

# Cleanup
echo -e "\n${YELLOW}Cleaning up test files...${NC}"
rm -f "zeoran_data/atom_sites/LTA_SI_test.txt"
rm -f "zeoran_data/unit_cell/LTA_SI_test.txt"
# Add more test files to clean up as needed

# Report overall results
echo -e "\n${YELLOW}=========================================${NC}"
echo -e "${YELLOW}            Test Results                 ${NC}"
echo -e "${YELLOW}=========================================${NC}"

if [ $TEST1_RESULT -eq 0 ]; then
    echo -e "Test 1: LTA_SI ${GREEN}PASSED${NC}"
else
    echo -e "Test 1: LTA_SI ${RED}FAILED${NC}"
fi

# Add more test results as needed

# Overall status
if [ $TEST1_RESULT -eq 0 ]; then  # Add more conditions as more tests are added
    echo -e "\n${GREEN}All CIF preprocessing tests passed!${NC}"
    exit 0
else
    echo -e "\n${RED}Some CIF preprocessing tests failed.${NC}"
    exit 1
fi
