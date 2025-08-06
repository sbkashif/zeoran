# zeoran
ZEOlite RANdom generation

This repository is a generalized version of the original [zeoran](https://github.com/promerma/zeoran/tree/main) software developed by Pablo Romero Marimon, Eindhoven University of Technology.

![alt text](https://github.com/promerma/zeoran/blob/main/cover.png)

## Base software description

Main goal of the software is to modify the Si/Al ratio in zeolites. The aluminum substitutions are randomly generated from 4 different probability distributions, implemented by 4 different algorithms:

  1. chains: Al atoms are introduced forming chains of consecutive Al-O-Al bonds. The number and lengths of the chains are given as an input.
  2. clusters: A given number of Al atoms are introduced in a small spatial region.
  3. merw: A given number of Al atoms are introduced "as spread as possibly" in the structure, i.e., maximizing the entropy of the framework.
  4. random: A given number of Al atoms are introduced by sampling a uniform distribution.

For a detailed description of the algorithms used to generate the zeolite frameworks and the program itself, please check the .pdf file available in this repository.

## 🚀 [This REPO] Adapted for generalized workflows

The generalized version of the software, while keeping the original algorithms for modifying Si/Al ratio intact, is designed to be more flexible and user-friendly, allowing for easier integration into various workflows and supporting a wider range of file formats. It also includes a comprehensive testing framework to ensure reproducibility and facilitate development. The immediate use of the modified version is to modify the Si/Al ratio in LTA zeolites which were not covered by the original software.


### Key Features of the Adapted Version
1. **Multi-Format Output Support**: The software now supports both CIF (crystallographic) and GRO/ITP (GROMACS) output formats:
   - **CIF Output**: Traditional crystallographic format with fractional coordinates
   - **GRO Output**: GROMACS coordinate format with Cartesian coordinates in nanometers
   - **ITP Topology**: GROMACS topology files with proper atom definitions and masses
   - **Flexible Format Selection**: Choose output format via preprocessor (`cif`, `gro`, or `all`)
2. **Automated CIF Preprocessing**: The adapted version uses the Atomic Simulation Environment (ASE) to automatically preprocess CIF files, generating all required internal files and allowing immediate use in the `generate.input` file.
3. **GRO File Preprocessing**: Support for GROMACS GRO input files with YAML configuration for unit cell parameters and charge assignments.
4. **Flexible Data Directory Management**: The software supports multiple data directory configurations:
   - **Local directories**: Direct `atom_sites/` and `unit_cell/` directories in the run location
   - **Environment variable**: `ZEORAN_DATA_DIR` for custom data locations
   - **Organized repo structure**: `zeoran_data/` directory for structured file organization
   - **Build directory fallback**: Automatic fallback to installation directory
5. **Modern CMake Build System**: A modern CMake-based build system has been implemented, allowing for:
   - Cross-platform compatibility
   - Dependency management
   - Static linking for high-performance computing environments
6. **Interactive Demo Workflow**: A complete demo workflow script is provided to guide new users through the process of running the software, setting up input parameters, and executing zeoran with their configuration.
7. **Comprehensive Testing Framework**: A robust testing infrastructure has been added to ensure reproducible results and facilitate development. The framework includes fixed random seed support, benchmark inputs, reference outputs, and comparison tools. This ensures that algorithm behavior remains consistent across code changes and allows for regression testing when implementing new features or optimizations.

## Prerequisites
- CMake (version 3.10 or higher)
- GCC or another C++ compiler supporting C++11
- Eigen library (version 3.4.0 or higher)

Once you have installed the prerequisites, please update the required paths in the `install_with_cmake.sh` script. Key inputs include:
- PREFIX: The prefix path where the software will be installed (default is `/usr/local`).
- EIGEN_PATH: The path to the Eigen library (default is `/usr/local/include/eigen3`).

Please refer to the [install_with_cmake.sh](install_with_cmake.sh) script for the exact lines to modify.

## Installation

To install the software, run the following commands:
```bash
# Clone the repository
git clone https://github.com/sbkashif/zeoran.git
cd zeoran
./install_with_cmake.sh
```

## Running an EXISTING zeolite framework

To run the software with an existing zeolite framework, you need to create a `generate.input` file with the required parameters. The basic structure of the `generate.input` is discussed in [Structure of generate.input](#structure-of-generateinput) section.

The software supports flexible data directory configurations:
- **Local directories**: Place `atom_sites/` and `unit_cell/` directories in your run location
- **Environment variable**: Set `ZEORAN_DATA_DIR` to point to your data directory
- **Repo structure**: Use organized `zeoran_data/atom_sites/` and `zeoran_data/unit_cell/` structure
- **Build fallback**: Automatic fallback to installation directory

```bash
# Run with local directories (highest priority)
mkdir atom_sites unit_cell
# copy your zeolite files...
./build/bin/zeoran

# Run with environment variable
export ZEORAN_DATA_DIR=/path/to/your/data
./build/bin/zeoran

# Run from repo with organized structure
ZEORAN_DATA_DIR="$(pwd)/zeoran_data" ./build/bin/zeoran
```

## Running a NEW zeolite framework

Working with a new zeolite framework does **NOT** require reinstallation of the software. Starting with v2.0, generation of required files in `zeoran_data/atom_sites` and `zeoran_data/unit_cell` directories is automated by utilizing the Atomic Simulation Environment (ASE). This allows users to easily set up their zeolite framework instead of manually providing the necessary files.

### Quick workflow for a new zeolite:

1. **Preprocess your input file**:
   ```bash
   # For CIF files (crystallographic format)
   python preprocess_cif.py path/to/your/file.cif ZEOLITE_NAME
   
   # For GRO files (GROMACS format) - requires YAML config
   python preprocess_gro.py path/to/your/file.gro config.yaml ZEOLITE_NAME
   ```

2. **Choose output format** (optional - defaults to input format):
   ```bash
   # Specify output format during preprocessing
   python preprocess_cif.py input.cif ZEOLITE_NAME --output-formats gro
   python preprocess_cif.py input.cif ZEOLITE_NAME --output-formats all
   ```

3. **Update generate.input** with your zeolite name:
   ```bash
   # Edit generate.input to use ZEOLITE_NAME as the first line
   ```

4. **Run zeoran** (no reinstallation needed):
   ```bash
   ./build/bin/zeoran
   ```

### Output Format Options

The software supports multiple output formats that can be controlled during preprocessing:

- **`cif`**: Traditional crystallographic format with fractional coordinates
- **`gro`**: GROMACS coordinate format with Cartesian coordinates (nm) plus ITP topology file
- **`all`**: Generate all supported formats (CIF and GRO/ITP files) for the same structure

Examples:
```bash
# Generate only CIF output
python preprocess_cif.py structure.cif LTA_TEST -o cif

# Generate only GRO/ITP output  
python preprocess_cif.py structure.cif LTA_TEST -o gro

# Generate all formats
python preprocess_cif.py structure.cif LTA_TEST -o all
```

### Complete automated workflow:

The demo workflow script handles data directory organization automatically:

```bash
# Run the interactive demo (includes preprocessing and execution)
./demo_workflow.sh path/to/your/file.cif ZEOLITE_NAME
```
This demo script:

1. Preprocesses your CIF file to generate the necessary internal files in the `zeoran_data/` structure
2. Sets the appropriate `ZEORAN_DATA_DIR` environment variable for organized file management
3. Rebuilds the software with the new zeolite framework (optional)
4. Generates the `generate.input` file with the required parameters
5. Runs zeoran with your configuration using the organized data directory structure


### Structure of generate.input
The generate.input file needs to have a particular structure. Please, note that he number of parameters and their order cannot be changed. This structure has a fixed part, and a part that depends on the algorithm we aim to use (chains/clusters/merw/random), since they require different parameters. Next, we specify the format of the input file in each case:

#### chains:

```
Zeolite (MFI/MOR/FAU/RHO/MEL/DDR/TON/new)
Algorithm (chains/clusters/merw/random)
Name_of_output_directory
Number_of_structures_to_be_generated
Number_of_chains
Number_of_substitutions_in_first_chain
Number_of_substitutions_in_second_chain
...
Number_of_substitutions_in_last_chain
```

#### clusters:

```
Zeolite (MFI/MOR/FAU/RHO/MEL/DDR/TON/new)
Algorithm (chains/clusters/merw/random)
Name_of_output_directory
Number_of_structures_to_be_generated
Number_of_substitutions
```
	
#### merw:

```
Zeolite (MFI/MOR/FAU/RHO/MEL/DDR/TON/new)
Algorithm (chains/clusters/merw/random)
Name_of_output_directory
Number_of_structures_to_be_generated
Number_of_substitutions
Number_of_equilibration_steps
Number_of_visits
```

NOTE: The last two parameters are optional. If they are missing the default values are 100 and 20 respectively. Note that if changed, both of them need to be specified. More information about these parameters can be found in the file generate_zeolite_frameworks.pdf.

#### random:

```
Zeolite (MFI/MOR/FAU/RHO/MEL/DDR/TON/new)
Algorithm (chains/clusters/merw/random)
Name_of_output_directory
Number_of_structures_to_be_generated
Number_of_substitutions
```

## For Developers

### Repository organization

  1. `zeoran_data/atom_sites`: Contains the atomic positions of all the atoms forming a single unit cell of each zeolite. The structure of a line of this file is: atom_id atom_type x y z charge.
  2. `zeoran_data/unit_cell`: Contains the basic information of the unit cell of each framework.
  3. `Makefile`: Script to compile and build the program -- base software version.
  4. `CMakeLists.txt`: CMake build script for the project, allowing for cross-platform builds and dependency management. 
  5. `zeoran.cpp`: Contains all the functions implemented to run the program, including the main function.
  6. `generate.input`: Input file template.
  7. `zeoran.pdf`: Detailed explanation of the program.
  8. `global.h`: Contains the definition of the global variables and structures used in the program.
  9. `headers.h`: Contains the headers of all the functions written in the file "zeoran.cpp".
  10. `libraries.h`: Contains all the libraries used.
  11. `INSTALLATION.md`: Detailed build and installation instructions.
  12. `developer_notes.md`: Detailed documentation of algorithms, implementation, and recent updates.
  13. `tests/`: Directory containing test suite for ensuring reproducibility and validating code changes.
  14. `log.md`: Contains the current state of the program and changes and improvements that still need to be done.
  15. `cover.png`: Cover figure of the README.md file.

### Testing Framework

A comprehensive test suite has been added to ensure reproducibility and facilitate development:

#### Key Features

- **Fixed Random Seeds**: Tests use controlled random seeds to ensure reproducible results
- **Benchmark Inputs**: Predefined input files covering different zeolites and algorithms
- **Reference Benchmarks**: Baseline output files for verifying code changes
- **Comparison Tools**: Scripts to validate algorithm behavior consistency

#### Basic Test Usage

```bash
# Run all tests with a fixed random seed
cd tests
RANDOM_SEED=12345 ./run_tests.sh

# Compare test results with reference benchmarks
./compare_benchmarks.sh

# Validate reproducibility of random seeds
./validate_reproducibility.sh
```

The testing framework is essential for:
- Verifying algorithm correctness across different parameters
- Ensuring reproducibility of stochastic processes
- Regression testing when modifying the codebase
- Benchmarking performance before/after optimizations

For detailed information on the test suite, including advanced usage, adding new tests, and troubleshooting, please refer to the [Tests README](tests/README.md).



## Project Maintenance Notes

See [developer_notes](developer_notes.md) for detailed documentation of the implementation and recent updates.

## License
This project is licensed under the MIT License. See `LICENSE.md` for details.


