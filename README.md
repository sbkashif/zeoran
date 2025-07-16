# zeoran
ZEOlite RANdom generation

This repository is a generalized version of the original zeoran software. `zeron` is used to generate zeolite frameworks with different aluminum distributions. The original software was developed by Pablo Romero Marimon as part of their Master's thesis at the Eindhoven University of Technology for generating CIF files after modifying the Si/Al ratio. The software was eventually used for the writing of the paper:

P. Romero-Marimon *et al.*, "Adsorption of carbon dioxide in non-Löwenstein zeolites".

![alt text](https://github.com/promerma/zeoran/blob/main/cover.png)

## Base software author's information
	Pablo Romero Marimon
	Eindhoven University of Technology
	Department of Applied Physics
	Materials Simulation and Modelling group
	March 24, 2023

## Adapted for generalized workflows by:

```
Salman Bin Kashif
Shi Research Group
Department of Chemical and Biological Engineering
University at Buffalo
July 2025
```

The modified version of the software is designed to be more flexible and user-friendly, allowing for easier integration into various workflows and supporting a wider range of file formats. It also includes a comprehensive testing framework to ensure reproducibility and facilitate development. The immediate use of the modified version is to modify the Si/Al ratio in LTA zeolites which were not covered by the original software. 

The corresponding publication information for the LTA zeolite framework will be provided soon.

## Base software description
Main goal of the software is to modify the Si/Al ratio in zeolites. The aluminum substitutions are randomly generated from 4 different probability distributions, implemented by 4 different algorithms:

  1. chains: Al atoms are introduced forming chains of consecutive Al-O-Al bonds. The number and lengths of the chains are given as an input.
  2. clusters: A given number of Al atoms are introduced in a small spatial region.
  3. merw: A given number of Al atoms are introduced "as spread as possibly" in the structure, i.e., maximizing the entropy of the framework.
  4. random: A given number of Al atoms are introduced by sampling a uniform distribution.

For a detailed description of the algorithms used to generate the zeolite frameworks and the program itself, please check the .pdf file available in this repository. The software is entirely written in C/C++.

## Adapted version description

There are three key updates in this adapted version:

1. **Build system**: The original software had hardcoded installation and dependency paths which limited portability. This version implements a CMake-based build system (the industry standard for C++ projects) that automatically handles dependency management and cross-platform compatibility. Special consideration has been given to high-performance computing environments with support for static linking and custom installation paths, making it deployable on clusters without requiring administrative privileges.

2. **Supporting more file formats**: The original software only generated CIF files as output needed more user interventions to modiffy the standard CIF files into the format required by the source code. We are used Automated Simulation Environment (ASE) to generate process the CIF files, or any other input file to automatically generate the required input files for the zeoran software. This allows users to work with a wider range of file formats and simplifies the workflow for generating zeolite frameworks.

3. **Comprehensive testing framework**: A robust testing infrastructure has been added to ensure reproducible results and facilitate development. The framework includes fixed random seed support, benchmark inputs, reference outputs, and comparison tools. This ensures that algorithm behavior remains consistent across code changes and allows for regression testing when implementing new features or optimizations.

## Content
Here the content of the repository is described. 

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


## Installation and Building

### Prerequisites
- CMake (version 3.10 or higher)
- GCC or another C++ compiler supporting C++11
- Eigen library (version 3.4.0 or higher)

### Quick Installation

For quick installation using CMake (recommended), but modify the installation and dependency paths in the script as needed:

```bash
./install_with_cmake.sh
```

For detailed installation instructions including build options, configuration parameters, and advanced usage, please refer to the [Detailed Installation Guide](INSTALLATION.md).

## Basic Usage

To run the program, prepare an input file named `generate.input` in the current directory and run the executable:

```bash
./zeoran
```

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

## How to work with a new zeolite

The repository contains the information to generate structures for the MFI, MOR, FAU, RHO, TON, DDR and MEL frameworks. However, it is implemented to work with all the zeolites. To add support for new frameworks:

1. Add the corresponding files to the `zeoran_data/atom_sites/` and `zeoran_data/unit_cell/` directories:
   ```
   zeoran_data/atom_sites/YOUR_ZEOLITE.txt
   zeoran_data/unit_cell/YOUR_ZEOLITE.txt
   ```
   
   The atom_sites file should contain the atomic positions with the format:
   ```
   atom_id atom_type x y z charge
   ```
   
   The unit_cell file should contain the basic parameters of the unit cell.

2. Specify the new zeolite name in the first line of the `generate.input` file:
   ```
   YOUR_ZEOLITE
   random
   Output
   ...
   ```

3. Rebuild the project to copy the new data files to the build directory:
   ```bash
   ./install_with_cmake.sh
   ``` 
   Your new zeolite framework will be automatically recognized by the software once you rebuild.

4. Run the executable:
   ```bash
   ./zeoran
   ```

## Testing Framework

A comprehensive test suite has been added to ensure reproducibility and facilitate development:

### Key Features

- **Fixed Random Seeds**: Tests use controlled random seeds to ensure reproducible results
- **Benchmark Inputs**: Predefined input files covering different zeolites and algorithms
- **Reference Benchmarks**: Baseline output files for verifying code changes
- **Comparison Tools**: Scripts to validate algorithm behavior consistency

### Basic Test Usage

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


