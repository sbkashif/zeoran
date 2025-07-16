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
./bin/zeoran < ../generate.input
```

### Using Traditional Make

```bash
# Build the project
make

# Run the program directly from build directory
./zeoran
```

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

If you're building on a cluster or HPC environment, you might encounter issues with system headers or finding dependencies like Eigen. We provide specialized build targets for these environments:

### Diagnosing Build Issues

```bash
# Check your build environment
make diagnose
```

This will show information about your compiler, available Eigen installations, and system headers that might be causing issues.

### Using Cluster Build Target

```bash
# Build with specialized cluster settings
make cluster
```

This target automatically tries different compilers commonly available on cluster systems (mpicxx, icpc, g++) to find one that works.

### Using Module System

If your cluster uses the module system for managing software (like Eigen):

```bash
# Load the Eigen module (adjust module name as needed)
module load eigen

# Build with module support
make module_build
```

The build system will automatically detect the Eigen installation from the loaded module.

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

### User Home Installation (Default)

```bash
# Build and install to $HOME/.local
make
make install
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
sudo make install PREFIX=/usr/local
```

## Environment Variables

### ZEORAN_DATA_DIR

Override the default data directory location:
```bash
export ZEORAN_DATA_DIR=/path/to/custom/data
```

This can be useful if you want to keep your data files separate from the build directory or if you're running multiple instances with different data sets.

## Cleaning Up

To clean the build directory:

```bash
make clean
```

## Uninstalling

If you've installed the program:

```bash
# Default uninstall from home directory
make uninstall

# Custom location uninstall
make uninstall PREFIX=/path/to/custom/location
```
