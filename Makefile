# zeoran Makefile
# -----------------------------
#
# USAGE:
#  - Standard build:         make [options] && make install [PREFIX=/path]
#
# COMMON OPTIONS:
#  - EIGEN_PATH=/path        Path to Eigen headers
#  - STATIC=1                Static linking for C++ standard library
#  - PREFIX=/path            Custom installation path (default: /usr/local)
#
# For detailed usage, run: make help
# -----------------------------

# Configuration variables
BUILD_DIR = build
BIN_DIR = $(BUILD_DIR)/bin
DATA_DIR = $(BUILD_DIR)/data

# Installation paths (customizable via PREFIX)
PREFIX ?= /usr/local
EIGEN_PATH ?= /usr/local/include/eigen3
INSTALL_BIN_DIR = $(PREFIX)/bin
INSTALL_DATA_DIR = $(PREFIX)/share/zeoran

# Compiler settings
CXX ?= g++
CXXFLAGS = -O2 -Wall -std=c++11

# Handle static linking for HPC environments (make STATIC=1)
ifdef STATIC
    LDFLAGS += -static-libstdc++
endif

# Handle custom Eigen path (make EIGEN_PATH=/path/to/eigen)
CXXINCLUDES = -I$(EIGEN_PATH)

# Default build target
all: setup $(BIN_DIR)/zeoran
	@echo "Build complete! Run with: $(BIN_DIR)/zeoran"
	@echo "To install, run: make install [PREFIX=/custom/path]"

# Create necessary directories
setup:
	@mkdir -p $(BUILD_DIR)
	@mkdir -p $(BIN_DIR)
	@mkdir -p $(DATA_DIR)/atom_sites
	@mkdir -p $(DATA_DIR)/unit_cell
	@cp -r zeoran_data/atom_sites/* $(DATA_DIR)/atom_sites/ 2>/dev/null || true
	@cp -r zeoran_data/unit_cell/* $(DATA_DIR)/unit_cell/ 2>/dev/null || true

# Compile the main program
$(BIN_DIR)/zeoran: zeoran.cpp global.h headers.h libraries.h
	@mkdir -p $(BIN_DIR)
	$(CXX) $(CXXFLAGS) $< -o $@ $(CXXINCLUDES) $(LDFLAGS) -DZEORAN_DATA_DIR=\"$(INSTALL_DATA_DIR)\"

# System-wide installation (optional)
install:
	@mkdir -p $(INSTALL_BIN_DIR)
	@mkdir -p $(INSTALL_DATA_DIR)/atom_sites
	@mkdir -p $(INSTALL_DATA_DIR)/unit_cell
	@if [ "$(realpath $(BIN_DIR)/zeoran)" != "$(realpath $(INSTALL_BIN_DIR)/zeoran)" ]; then \
		cp $(BIN_DIR)/zeoran $(INSTALL_BIN_DIR)/; \
	fi
	@cp -r zeoran_data/atom_sites/* $(INSTALL_DATA_DIR)/atom_sites/
	@cp -r zeoran_data/unit_cell/* $(INSTALL_DATA_DIR)/unit_cell/
	@echo "Installed zeoran to $(INSTALL_BIN_DIR)"
	@echo "Refer to the executable from $(INSTALL_BIN_DIR)/zeoran"

# Uninstall the system-wide installation
uninstall:
	@rm -f $(INSTALL_BIN_DIR)/zeoran
	@rm -rf $(INSTALL_DATA_DIR)
	@echo "Uninstalled zeoran from $(INSTALL_BIN_DIR)"

# Clean the build directory
clean:
	@rm -rf $(BUILD_DIR)
	@echo "Cleaned build directory"
	
# Build configuration examples can be found in 'make help'

# Display help information
help:
	@echo "zeoran - ZEOlite RANdom generation"
	@echo ""
	@echo "Basic Usage:"
	@echo "  make                    - Build the software"
	@echo "  make install            - Install to system location (default: /usr/local)"
	@echo ""
	@echo "Command-line Options:"
	@echo "  PREFIX=/path           - Installation location (e.g., PREFIX=$(HOME)/.local)"
	@echo "  EIGEN_PATH=/path       - Path to Eigen headers"
	@echo "  STATIC=1               - Use static linking for C++ standard library (for HPC)"
	@echo "  CXX=compiler           - Specify alternative C++ compiler"
	@echo ""
	@echo "Other Targets:"
	@echo "  make uninstall         - Remove installation"
	@echo "  make clean             - Remove build files"
	@echo "  make help              - Display this help message"
	@echo ""
	@echo "Examples:"
	@echo "  # For system-wide installation (requires admin):"
	@echo "  make && sudo make install"
	@echo ""
	@echo "  # For user-local installation:"
	@echo "  make && make install PREFIX=\$$HOME/.local"
	@echo ""
	@echo "  # For HPC environments:"
	@echo "  make EIGEN_PATH=/path/to/eigen STATIC=1 && make install PREFIX=\$$HOME/.local"
	@echo ""
	@echo "  # Loading required modules before building (example):"
	@echo "  module load gcc/11.2.0 eigen/3.4.0 && \\"
	@echo "  make EIGEN_PATH=\$$EIGEN_ROOT/include STATIC=1 && \\"
	@echo "  make install PREFIX=\$$HOME/.local"
	@echo ""

.PHONY: all setup clean install uninstall help
