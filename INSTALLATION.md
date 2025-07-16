# Detailed Installation Instructions

This document provides detailed installation instructions and configuration options for the Zeoran package.

## Build System Overview

Zeoran supports two installation systems - CMake and traditional Make:

1. **CMake (Recommended)**: 
   - Modern, cross-platform build system
   - Better dependency management and configuration handling
   - Cleaner build output organization
   - Preferred for new installations and cross-platform compatibility
   - Uses `CMakeLists.txt` as its configuration file

2. **Traditional Make**:
   - Simpler approach for basic systems
   - May be more familiar to users of older Unix systems
   - Might be required in environments where CMake isn't available
   - Uses `Makefile` as its configuration file

**Best Practices:**
- For most users and new installations, use the CMake approach
- For high-performance computing (HPC) environments, both methods support static linking
- When creating reproducible workflows, document which build system was used
- Only use one build system at a time (don't mix CMake and Make)

## Basic Build and Run

### Using CMake (Recommended)

```bash
# Build with CMake
mkdir build && cd build
cmake ..
make

# Run the program
# First copy the input file to the current directory
cp ../generate.input .
# Then run the program
./bin/zeoran
```

### Using Traditional Make

```bash
# Build the project
make

# Run the program directly from build directory
./build/bin/zeoran
```

## CIF File Preprocessing

Zeoran now includes an automated preprocessing script that extracts unit cell information and atom positions directly from CIF files, eliminating the need for manual preparation of these files.

### Using the Preprocessing Script

```bash
# Preprocess a CIF file for use with Zeoran
python preprocess_cif.py path/to/your/file.cif ZEOLITE_NAME

# Example
python preprocess_cif.py zeoran_data/cif_files/Framework_0_initial_1_1_1_P1.cif LTA
```

This will:
1. Extract unit cell information from the CIF file
2. Generate the necessary `unit_cell/ZEOLITE_NAME.txt` file
3. Generate the required `atom_sites/ZEOLITE_NAME.txt` file
4. Copy the CIF file to the zeoran_data directory

After preprocessing, you can use the zeolite name in your `generate.input` file as usual.

### Demo Workflow

For convenience, a demo workflow script is provided that demonstrates the complete process:

```bash
# Run the demo workflow with a CIF file
./demo_workflow.sh path/to/your/file.cif ZEOLITE_NAME

# Example
./demo_workflow.sh zeoran_data/cif_files/Framework_0_initial_1_1_1_P1.cif LTA
```

This interactive script will:
1. Preprocess the CIF file
2. Guide you through choosing an installation method (CMake or traditional Make)
3. Help you set up a generate.input file with your chosen algorithm
4. Run zeoran with the processed data

This is the recommended approach for new users to quickly get started with zeoran.

### Troubleshooting CIF Preprocessing

If you encounter issues when running zeoran with preprocessed CIF files, consider the following:

1. **CIF File Quality**: Not all CIF files are suitable for zeoran. The file should:
   - Contain silicon (Si) atoms and oxygen (O) atoms
   - Have a proper Si:O ratio (typically around 1:2 for zeolites)
   - Use fractional coordinates within [0,1]
   - Have well-defined unit cell parameters

2. **Floating Point Exceptions**: These often occur when:
   - The connectivity matrix cannot be properly constructed
   - The structure doesn't follow expected zeolite topology
   - Distance calculations encounter numerical issues

3. **Validation**: The preprocessing script includes validation steps to help identify potential issues:
   ```bash
   python preprocess_cif.py your_file.cif ZEOLITE_NAME
   ```
   Look for warnings in the output that might indicate problems with the structure.

4. **Manual Verification**: You can examine the generated files to ensure they match expected formats:
   ```bash
   cat zeoran_data/unit_cell/ZEOLITE_NAME.txt
   head zeoran_data/atom_sites/ZEOLITE_NAME.txt
   ```

5. **Debug Mode**: The demo script includes debug options when crashes occur to help identify the source of problems.

This will:
1. Create a `build` directory in the repository
2. Build the executable in the correct location
3. Copy required data files to the appropriate directory

The program will automatically use the correct data directory.

## Detailed Build Instructions

### Using CMake

CMake provides a modern, cross-platform build system with clearer dependency management.

1. Create and navigate to a build directory:
   ```bash
   mkdir build && cd build
   ```

2. Configure the project:
   ```bash
   cmake .. 
   ```
   
3. Build the executable:
   ```bash
   make
   ```

4. Optionally install the software:
   ```bash
   make install
   ```

   The default installation path is determined by your system (typically `/usr/local` on Unix systems).
   To install to a custom location, use:
   ```bash
   cmake .. -DCMAKE_INSTALL_PREFIX=/your/custom/path
   make install
   ```

### Using Traditional Make

The project also supports building with a traditional Makefile.

1. Build the project:
   ```bash
   make
   ```

2. Optionally install (requires appropriate permissions):
   ```bash
   make install
   ```

   To install to a custom location:
   ```bash
   make install PREFIX=/your/custom/path
   ```

3. For help with additional Makefile options:
   ```bash
   make help
   ```

## Building on HPC/Cluster Environments

For high-performance computing environments where portability is important:

**Using CMake:**
```bash
# Load necessary modules if using a module system
module load gcc/11.2.0 eigen/3.4.0

mkdir build && cd build
cmake .. -DSTATIC=ON -DEIGEN_PATH=$EIGEN_ROOT/include
make
```

**Using traditional Make:**
```bash
# Load necessary modules if using a module system
module load gcc/11.2.0 eigen/3.4.0

make STATIC=1 EIGEN_PATH=$EIGEN_ROOT/include
make install PREFIX=$HOME/.local
```

**Which to choose?**
- **CMake**: Recommended for most users, especially on modern systems or when working across different platforms
- **Traditional Make**: Suitable for simpler Unix environments or when CMake isn't available
- Both methods will produce the same executable with identical functionality

## Installation Scripts

Two automation scripts are provided for easy installation:

1. **CMake-based installation** (recommended):
   ```bash
   bash install_with_cmake.sh
   ```
   This script uses CMake for the build process and installs to the `build` directory by default.
   It sets `EIGEN_PATH` to `/projects/academic/kaihangs/salmanbi/software/eigen-3.4.0`.

2. **Traditional Make installation**:
   ```bash
   bash install_traditional_make.sh
   ```
   This script uses the traditional Makefile, sets `STATIC=1` for HPC compatibility,
   and allows customizing `PREFIX` and `EIGEN_PATH` environment variables.

## Advanced Configuration

### CMake Build Options

CMake offers several configuration options that can be set during the configuration step:

| Option | Description | Default |
|--------|-------------|---------|
| `-DCMAKE_INSTALL_PREFIX=/path` | Installation directory | System default (typically `/usr/local`) |
| `-DEIGEN_PATH=/path/to/eigen` | Path to Eigen headers | `${CMAKE_INSTALL_PREFIX}/include/eigen3` |
| `-DSTATIC=ON/OFF` | Enable static linking of C++ standard library | OFF |

Example with all options:
```bash
cmake .. -DCMAKE_INSTALL_PREFIX=$HOME/.local \
         -DEIGEN_PATH=/opt/eigen3 \
         -DSTATIC=ON
```

### Traditional Make Options

The Makefile supports the following variables:

| Variable | Description | Default |
|----------|-------------|---------|
| `PREFIX=/path` | Installation directory | `/usr/local` |
| `EIGEN_PATH=/path` | Path to Eigen headers | `/usr/local/include/eigen3` |
| `STATIC=1` | Enable static linking of C++ standard library | Not set |
| `CXX=compiler` | Specify C++ compiler | `g++` |

Example with all options:
```bash
make EIGEN_PATH=/opt/eigen3 STATIC=1 CXX=clang++
make install PREFIX=$HOME/.local
```

## Customizing the Build

### Build Directory

```bash
# Custom build directory
make BUILD_DIR=my_build
```

This will place all build artifacts in `my_build/` instead of `build/`.

### Compiler Selection

```bash
# Use Clang instead of GCC
make CXX=clang++

# Or specify a specific GCC version
make CXX=g++-11
```

### Compiler Flags

```bash
# Optimize for performance
make CXXFLAGS="-O3 -march=native"

# Debug build
make CXXFLAGS="-O0 -g -DDEBUG"
```

### Linking Options

```bash
# Add custom linking flags
make LDFLAGS="-L/path/to/lib -lsomelib"
```

## Installation Options

For most users, especially on clusters without admin privileges, installation is not necessary. You can run directly from the build directory. However, if you want to install:

### User Home Installation

```bash
# Build and install to $HOME/.local
make
make install PREFIX=$HOME/.local
```

Add to your PATH (add to your .bashrc or .profile for persistence):
```bash
export PATH=$PATH:$HOME/.local/bin
```

### Custom Location Installation

```bash
# Install to custom location
make install PREFIX=/path/to/custom/location
```

Add to your PATH:
```bash
export PATH=$PATH:/path/to/custom/location/bin
```

### System-wide Installation

Requires admin privileges:
```bash
sudo make install
```

## Environment Variables

### ZEORAN_DATA_DIR

The program automatically looks for zeolite data files in several locations:

1. First, it checks the `ZEORAN_DATA_DIR` environment variable:
   ```bash
   export ZEORAN_DATA_DIR=/path/to/custom/data
   ```

2. Then it checks for a compiled-in default path (set at build time)

3. Finally, it falls back to:
   - `./zeoran_data` (local directory)
   - `/usr/local/share/zeoran` (standard installation location)

This flexibility makes it easy to use the software with different data sets.

## Cleaning Up

To clean the build directory:

```bash
make clean
```

## Uninstalling

If you've installed the program:

```bash
# Default uninstall
make uninstall

# Custom location uninstall
make uninstall PREFIX=/path/to/custom/location
```
