# Zeoran Test Suite

This directory contains test cases and benchmarks for the Zeoran software.

## Directory Structure

- `benchmark_inputs/`: Contains input files for different test cases
- `benchmark_outputs/`: Contains output files from the current version of the code
- `benchmark_reference/`: Contains reference output files from the original version of the code

## Test Scripts

1. `run_tests.sh` - Main script to run tests with different inputs
2. `compare_benchmarks.sh` - Script to compare outputs with reference benchmarks
3. `create_benchmarks.sh` - Script to create new reference benchmarks
4. `test_cif_processing.sh` - Script to test CIF file preprocessing functionality
5. `compare_structures.py` - Python script to compare zeoran structure files for equivalence

## Running Tests

### Basic Usage

```bash
# Run all predefined tests with default seed (12345)
./run_tests.sh

# Run tests with a specific random seed
RANDOM_SEED=54321 ./run_tests.sh

# Compare outputs with reference benchmarks
./compare_benchmarks.sh

# Test CIF file preprocessing
./test_cif_processing.sh

# Compare structure files directly
./compare_structures.py path/to/structure1.txt path/to/structure2.txt
```

### Simple Workflow

1. Run the tests to generate outputs
   ```bash
   ./run_tests.sh
   ```

2. Create reference benchmarks (first time or after validating changes)
   ```bash
   ./create_benchmarks.sh
   ```

3. Make changes to the source code

4. Rebuild the project
   ```bash
   cd ..
   ./install_with_cmake.sh
   cd tests
   ```

## CIF Processing Tests

The `test_cif_processing.sh` script tests the CIF file preprocessing functionality, which uses ASE (Atomic Simulation Environment) to extract structure data from CIF files.

### Structure Comparison Tool

The `compare_structures.py` script can compare two structure files to verify they represent the same atomic structure, even if atoms are listed in a different order.

```bash
# Basic comparison
./compare_structures.py zeoran_data/atom_sites/LTA.txt zeoran_data/atom_sites/LTA_SI.txt

# Adjust bin size for coordinate comparison
./compare_structures.py --bin-size 0.005 file1.txt file2.txt

# Show detailed comparison output
./compare_structures.py --verbose file1.txt file2.txt
```

This tool is particularly useful for:
1. Validating that CIF preprocessing produces correct structures
2. Comparing structures generated from different CIF formats
3. Verifying that symmetry operations are correctly expanded
   ```

5. Run tests again to generate new outputs
   ```bash
   ./run_tests.sh
   ```

6. Compare with reference benchmarks
   ```bash
   ./compare_benchmarks.sh
   ```

## Benchmark References

The `benchmark_reference/` directory contains the output files from the original implementation. 
These serve as reference points for comparing outputs after code modifications.

To create new reference benchmarks:
```bash
# Run tests with the current code
./run_tests.sh

# Create reference benchmarks
./create_benchmarks.sh
```

## Adding New Tests

To add a new test case:

1. Create a new input file in `benchmark_inputs/` directory following the format:
   ```
   ZEOLITE_TYPE
   ALGORITHM_TYPE
   OUTPUT_DIRECTORY
   NUM_STRUCTURES
   [ALGORITHM SPECIFIC PARAMETERS]
   ```

2. Add the test case to the `run_tests.sh` script:
   ```bash
   run_test "NEW_TEST_NAME"
   ```

3. Run the tests and create new reference benchmarks.

## Fixed Random Seed

The code now supports using a fixed random seed via the RANDOM_SEED environment variable:

```bash
# The default seed is 12345 if not specified
./run_tests.sh

# Specify a different seed
RANDOM_SEED=54321 ./run_tests.sh
```

## Troubleshooting

If test outputs differ from references:

1. Check the comparison results to see which files differ
2. Verify the random seed is being properly set
3. Examine the code changes to identify what's causing the differences

Remember that differences aren't always bad - if you've intentionally improved an algorithm,
you'll want to create new reference benchmarks after validating the changes.
