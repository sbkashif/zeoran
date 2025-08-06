# Zeoran: Algorithm and Implementation Documentation

This document provides a detailed explanation of the zeoran software's algorithms and implementation for generating zeolite frameworks with different aluminum distributions. The software was originally developed by Pablo Romero Marimon at Eindhoven University of Technology and has been enhanced with additional features including a testing framework for reproducible results (see [Recent Updates: Testing Framework](#recent-updates-testing-framework) section).

## Overview

Zeoran is designed to modify the Si/Al ratio in zeolites by replacing Si atoms with Al atoms according to various distribution patterns. The software supports four different algorithms to introduce aluminum atoms into the structure:

1. **Chains**: Al atoms are introduced forming chains of consecutive Al-O-Al bonds.
2. **Clusters**: Al atoms are introduced in a small spatial region.
3. **MERW (Maximal Entropy Random Walk)**: Al atoms are introduced "as spread as possibly" in the structure to maximize entropy.
4. **Random**: Al atoms are introduced using a uniform distribution.

## Data Structure and Initialization

### Key Data Structures:

1. **Atom structure**:
   ```cpp
   // Defined in global.h (inferred)
   struct atom {
       string at;    // Atom label
       string id;    // Atom type
       double x, y, z;  // Fractional coordinates
       double q;    // Charge
   };
   ```

2. **Adjacency Matrices**:
   - `M_all`: Connectivity between all atoms based on distance criteria
   - `M_T`: Specialized adjacency matrix for T-sites (Si atoms that can be replaced with Al)

3. **Neighbor Lists**:
   - `neigbrs`: Vector of vectors storing neighbor relationships for T-sites

### Input Reading

The program reads a standard input file (`generate.input`) with the following structure:
```
Zeolite_name (MFI/MOR/FAU/RHO/MEL/DDR/TON/new)
Algorithm_name (chains/clusters/merw/random)
Output_directory_name
Number_of_structures
[Algorithm-specific parameters]
```

Additional parameters depend on the algorithm:
- **chains**: Number of chains, followed by number of substitutions in each chain
- **clusters**: Number of substitutions
- **merw**: Number of substitutions, equilibration steps, and number of visits
- **random**: Number of substitutions

### Zeolite Structure Reading

The program reads two main data files for each zeolite:
1. Unit cell information (`unit_cell/[zeolite_name].txt`)
2. Atom positions (`atom_sites/[zeolite_name].txt`)

## Core Algorithms

### Common Foundation: T-Site Connectivity

All algorithms share a foundation of determining T-site connectivity in zeolites:

1. **Distance-based connectivity**: Two atoms are considered connected if their distance is less than 2.56 Å
   ```cpp
   int connectivity(atom a1, atom a2) {
       // Calculate distance considering periodic boundary conditions
       // ...
       if(d < 2.56) {
           return 1;
       } else {
           return 0;
       }
   }
   ```

2. **T-site adjacency matrix construction**:
   ```cpp
   // Two T-atoms (Si) are neighbors if they share a common atom (O)
   for(i=0; i<Tatoms-1; i++) {
       for(j=i+1; j<Tatoms; j++) {
           for(k=0; k<Natoms && ctl==1; k++) {
               if(M_all[k][Tids[i]]==1 && M_all[k][Tids[j]]==1) {
                   M_T[i][j]=1;
                   M_T[j][i]=1;
                   ctl=0;
               }
           }
       }
   }
   ```

### 1. Chains Algorithm

The chains algorithm creates consecutive chains of Al atoms by following these steps:

1. Initialize a pool of T-sites for potential substitution
2. For each requested chain:
   - Select a random root T-site for the chain
   - Remove this T-site and its neighbors from the pool
   - Iteratively extend the chain by finding neighbors
   - Ensure proper connectivity by modifying the adjacency matrix

```cpp
vector<int> generate_chains (int **M_T, vector<vector<int> > neigbrs, vector<int> chains) {
    vector<int> Als(0), Tpos(Tatoms);
    
    // Initialize all T-sites as candidates
    for(int i=0; i<Tatoms; i++) {
        Tpos[i]=i;
    }
    
    for(unsigned int i=0; i<chains.size(); i++) {
        // Select random root T-site
        index=rand()%Tpos.size();
        Als.push_back(Tpos[index]);
        
        // Remove from potential sites
        int save=Tpos[index];
        Tpos.erase(Tpos.begin()+index);
        
        // Remove neighbors from potential sites
        // ...
        
        // Complete the chain
        last=save;
        for(int j=1; j<chains[i]; j++) {
            // Find a random neighbor
            index=find_neigb_random(last, M_T);
            
            // Add to chain and update adjacency matrix
            // ...
            
            // Add new Al
            Als.push_back(index);
            last=index;
        }
    }
    return Als;
}
```

### 2. Clusters Algorithm

The clusters algorithm creates a spatial cluster of Al atoms:

1. Select a random T-site as the starting point
2. Iteratively add Al atoms that are neighbors of existing Al atoms
3. When a neighbor is already an Al, move to the next possible neighbor

```cpp
vector<int> clusters_substitutions (int **M_T, int Nsubst) {
    vector<int> Als(0);
    
    // Get neighbors
    neigbrs=get_neighbours(M_T);
    
    // Find first substitution
    index=rand()%Tatoms;
    Als.push_back(index);
    
    // Add remaining substitutions by finding neighbors of existing Al atoms
    int currentAl=0, currentNei=0, countNsubst=1;
    while(countNsubst < Nsubst) {
        if(in(neigbrs[Als[currentAl]][currentNei], Als) == false) {
            // Add Al atom
            Als.push_back(neigbrs[Als[currentAl]][currentNei]);
            countNsubst++;
            // Update neighbor index
            // ...
        } else {
            // Try next neighbor
            // ...
        }
    }
    return Als;
}
```

### 3. MERW (Maximal Entropy Random Walk) Algorithm

The MERW algorithm creates a distribution that maximizes entropy:

1. Initialize a pool of T-sites for potential substitution
2. Select a random first T-site
3. For remaining substitutions:
   - Calculate a transition probability matrix using eigenvectors
   - Perform a biased random walk to find the next substitution site
   - The bias favors sites that maximize entropy

```cpp
vector<int> merw_substitutions (int **M_T, int Nsubst) {
    // Optimization for large substitution numbers
    if(Nsubst > (Tatoms/2)) {
        Nsubst = Tatoms - Nsubst; 
        permute=1;  // Will invert selection at the end
    }
    
    // Initialize probability matrix and candidate sites
    // ...
    
    // First substitution is random
    index=rand()%Tpos.size();
    Als.push_back(Tpos[index]);
    delete_neigb(Tpos[index], M_T);
    // ...
    
    // Remaining substitutions via MERW
    for(int i=1; i<Nsubst; i++) {
        compute_S(M_T, S);  // Compute transition probability matrix
        
        // Select starting point for random walk
        do {
            ini_index=rand()%Tpos.size();
            ini=Tpos[ini_index];
            // ...
        } while conditions;
        
        // Perform MERW to find next substitution
        next=merw(S, neigbrs, ini);
        
        // Add new Al site
        Als.push_back(Tpos[l]);
        delete_neigb(Tpos[l], M_T);
        // ...
    }
    
    // If we used the optimization, invert the selection
    if(permute==1) {
        // Return non-selected sites instead
        // ...
    }
    
    return Als;
}
```

The MERW algorithm uses an eigendecomposition of the adjacency matrix to create a transition probability matrix:

```cpp
void compute_S(int **M_T, double **S) {
    // Use Eigen library to compute eigenvalues/eigenvectors
    Eigen::EigenSolver<Eigen::MatrixXf> eigensolver;
    Eigen::MatrixXf A = Eigen::MatrixXf(Tatoms,Tatoms);
    
    // Add small random noise to adjacency matrix
    for(int i=0; i<Tatoms; i++) {
        for(int j=0; j<Tatoms; j++) {
            double p=((double) rand() / (RAND_MAX));
            A(i,j)=M_T[i][j] + p*0.01;
        }
    }
    
    // Eigendecomposition
    eigensolver.compute(A, true);
    // ...
    
    // Find largest eigenvalue
    // ...
    
    // Compute transition probability matrix
    for(int i=0; i<Tatoms; i++) {
        for(int j=0; j<Tatoms; j++) {
            S[i][j]= (1.0*M_T[i][j]/(max_eval)) * (eigen_vectors(j,max_ind)/eigen_vectors(i,max_ind));
        }
    }
}
```

The actual MERW process:
```cpp
int merw(double **S, vector<vector<int> > neigbrs, int ini) {
    // Equilibration phase
    i=ini;
    for(int k=0; k<Neqsteps; k++) {
        j=merw_step(S, neigbrs, i);
        i=j;
    }
    
    // Sampling phase - site with most visits is selected
    while(done == false) {
        j=merw_step(S, neigbrs, i);
        i=j;
        visits[i]++;
        if(visits[i] >= Nvisits) {
            done=true;
            next=i;
        }
    }
    
    return next;
}
```

### 4. Random Algorithm

The random algorithm is the simplest, introducing Al atoms at random positions:

```cpp
vector<int> generate_random (int Nsubst) {
    vector<int> Tpos(Tatoms), Als(Nsubst);
    
    // Initialize all T-sites as candidates
    for(int i=0; i<Tatoms; i++) {
        Tpos[i]=i;
    }
    
    // Randomly select sites for substitution
    for(int k=0; k<Nsubst; k++) {
        index=rand()%Tpos.size();
        Als[k]=Tpos[index];
        Tpos.erase(Tpos.begin()+index);
    }
    
    return Als;
}
```

## Output Generation

The program outputs the modified zeolite structures as CIF files:

```cpp
void print_structure (atom *list, vector<int> Als, int struc, string name_zeo, string name_alg, string out_name) {
    // Create output file
    fname = out_name + "/" + name_zeo + "_" + name_alg + "_" + to_string(struc) + ".cif";
    
    // Write CIF header
    // ...
    
    // Write atom positions with Si → Al substitutions
    int Tat=-1;
    for(int i=0; i<Natoms; i++) {
        if(strcmp(list[i].id,"Si") ==0 ) {
            Tat++;
            ctl=1;
            for(unsigned int j=0; j<Als.size() && ctl==1; j++) {
                if(Tat == Als[j]) {
                    // Write Al atom
                    fout << "Al" << alcount << "        Al     " << list[i].x << setw(10) << list[i].y << setw(10) << list[i].z << setw(10) << list[i].q << endl;  
                    ctl=0;
                    alcount++;
                }
            }
            // Write Si atom if not substituted
            if(ctl == 1) {
                fout << list[i].at << setw(10) << list[i].id << setw(10) << list[i].x << setw(10) << list[i].y << setw(10) << list[i].z << setw(10) << list[i].q << endl;
            }
        } else {
            // Write non-T atoms (O atoms)
            fout << list[i].at << setw(10) << list[i].id << setw(10) << list[i].x << setw(10) << list[i].y << setw(10) << list[i].z << setw(10) << list[i].q << endl;
        }
    }
}
```

## Technical Implementation Details

### Memory Management

The program uses a mix of C-style dynamic memory allocation and C++ STL containers:

1. C-style arrays with manual allocation/deallocation:
   ```cpp
   M_all=(int**)calloc(Natoms, sizeof(int*));
   for(i=0; i<Natoms; i++) {
       M_all[i]=(int*)calloc(Natoms, sizeof(int));
   }
   // Later freed with:
   for(i=0; i<Natoms; i++){
       free(M_all[i]);
   }
   free(M_all);
   ```

2. STL vectors for neighbor lists and Al site tracking:
   ```cpp
   vector<vector<int> > neigbrs(Tatoms, vector<int>(0));
   vector<int> Als(0);
   ```

### Data File Handling

The program reads atomic positions and unit cell data from separate files:

```cpp
atom* read_atom_sites (string fname) {
    list=(atom*)malloc(Natoms*sizeof(atom));
    fin.open(fname.c_str());
    
    for(i=0; i<Natoms; i++) {
        fin >> list[i].at >> list[i].id >> list[i].x >> list[i].y >> list[i].z >>list[i].q;
    }
    
    return list;
}

void read_unit_cell (string fname) {
    fin.open(fname.c_str());
    
    fin >> aux >> aux >> aux >> Natoms;
    fin >> aux >> aux >> aux >> Tatoms;
    fin >> aux >> a >> aux >> b >> aux >> c;
    fin >> aux >> alpha >> aux >> beta >> aux >> gama;
    fin >> aux >> setting;
}
```

### Periodic Boundary Conditions

The program handles periodic boundary conditions when calculating distances:

```cpp
// Check boundaries in x dimension
if(a1.x <= a2.x) {
    dpbc=fabs(a1.x + 1 - a2.x);
} else {
    dpbc=fabs(a2.x + 1 - a1.x);
}
if(dpbc < dx) {
    dx=dpbc;
}

// Similarly for y and z dimensions
// ...
```

### External Libraries

The program uses the Eigen library for eigenvalue decomposition in the MERW algorithm:

```cpp
Eigen::EigenSolver<Eigen::MatrixXf> eigensolver;
Eigen::MatrixXf A = Eigen::MatrixXf(Tatoms,Tatoms);
// ...
eigensolver.compute(A, /* computeEigenvectors = */ true);
Eigen::VectorXf eigen_values = eigensolver.eigenvalues().real();
Eigen::MatrixXf eigen_vectors = eigensolver.eigenvectors().real();
```

## Limitations of the Current Implementation

1. **Fixed Distance Criterion**: The program uses a hard-coded distance cutoff (2.56 Å) for connectivity
2. **Memory Management**: Uses a mix of C-style and C++ memory management
3. **Input Format**: Limited flexibility in input file format
4. **Data Path Handling**: Some hardcoding of data paths
5. **Algorithm Parameters**: Some parameters are hardcoded rather than user-configurable

These aspects could be targets for generalization in an improved version of the software. Some progress has already been made with the addition of the testing framework to address reproducibility concerns and provide a foundation for future algorithmic improvements.

## Recent Updates: Testing Framework

To ensure reproducibility and maintain code quality during development, a comprehensive testing framework has been added to the codebase.

### Fixed Random Seed Support

One of the major challenges with testing stochastic algorithms is ensuring reproducible results. The updated code now supports fixed random seeds via the `RANDOM_SEED` environment variable:

```cpp
// Use environment variable for seed if available, otherwise use current time
const char* seed_env = getenv("RANDOM_SEED");
if (seed_env != nullptr) {
    unsigned int seed = atoi(seed_env);
    cout << "Using fixed random seed: " << seed << endl;
    srand(seed);
} else {
    cout << "Using current time as random seed" << endl;
    srand(time(NULL));
}
```

This enhancement allows for deterministic testing of all four algorithms (chains, clusters, MERW, random) with reproducible outputs.

### Test Infrastructure

A comprehensive test suite has been implemented with the following components:

1. **Benchmark Inputs**: Standardized input files for different zeolites and algorithms
2. **Reference Outputs**: Baseline output files for comparison after code modifications
3. **Comparison Tools**: Scripts to validate that algorithm behavior remains consistent

The testing framework enables:

- Automated validation of algorithm behavior across different parameter sets
- Regression testing when making code changes
- Verification of results with fixed random seeds
- Comparison between different algorithm implementations

For detailed information on using the test framework, refer to the `tests/README.md` file, which includes:

- Instructions for running tests with fixed seeds
- Methods to create and maintain reference benchmarks
- Comparison procedures for validating algorithm behavior
- Troubleshooting guidance for common testing issues

This testing infrastructure forms the foundation for future development and ensures that any modifications to the core algorithms can be thoroughly validated.

## Recent Updates: Format-Agnostic Preprocessing System

A major enhancement has been added to support format-agnostic input processing and flexible configuration management, significantly expanding the software's usability beyond the original zeoran data format.

### CIF File Preprocessing

The software now includes a comprehensive CIF file preprocessor (`preprocess_cif.py`) that automatically converts CIF files into the zeoran data format:

```bash
python preprocess_cif.py input_file.cif ZEOLITE_NAME [config_file.yaml]
```

**Key Features:**
- **Automatic Format Conversion**: Converts CIF crystallographic data to zeoran's atom_sites and unit_cell formats
- **Self-Contained Operation**: CIF files work standalone without requiring additional configuration
- **Optional Configuration Override**: YAML config files can supplement or override CIF data
- **Charge Priority System**: Implements a clear hierarchy: config file > CIF file > zeros
- **ASE Library Integration**: Uses the Atomic Simulation Environment for robust CIF parsing
- **Intelligent T-atom Detection**: Automatically identifies Si atoms as substitution candidates

**Charge Handling:**
The preprocessor implements a sophisticated charge management system:
1. **Config File Charges** (highest priority): If provided via YAML config, these override all other sources
2. **CIF File Charges** (medium priority): If present in the original CIF file, these are preserved
3. **Zero Charges** (fallback): If no charge information is available, zeros are used without failure

### GRO File Preprocessing

Support for GROMACS GRO file format has been added (`preprocess_gro.py`) with mandatory YAML configuration:

```bash
python preprocess_gro.py input_file.gro config_file.yaml ZEOLITE_NAME
```

**Key Features:**
- **GROMACS Compatibility**: Supports standard GRO coordinate format
- **Mandatory Configuration**: Requires YAML config for cell parameters and charges
- **Flexible Charge Assignment**: Optional charges with graceful fallback to zeros
- **Periodic Boundary Support**: Handles box vectors and periodic boundary conditions

### Configuration System

A flexible YAML-based configuration system supports both preprocessing workflows:

```yaml
# Example configuration file
cell_parameters:
  a: 24.555
  b: 24.555  
  c: 24.555
  alpha: 90.0
  beta: 90.0
  gamma: 90.0

charges:
  Si: 1.500000
  O: -0.750000
  Al: 1.500000  # Used when Si is substituted with Al

# Optional: Override atomic positions or add metadata
metadata:
  description: "Custom zeolite configuration"
  source: "Experimental data"
```

### Enhanced User Interface

The main zeoran executable now displays helpful usage information:

```
=================================================
ZEORAN - ZEOlite RANdom generation
Version: 2.0 (July 2025)
=================================================
Note: You can now use the preprocess_cif.py script to
automatically process CIF files for use with zeoran:
  python preprocess_cif.py your_file.cif ZEOLITE_NAME
=================================================
```

### Workflow Integration

The preprocessing system integrates seamlessly with the existing zeoran workflow:

1. **Preprocessing Phase**: Convert external formats (CIF/GRO) to zeoran format
   ```bash
   python preprocess_cif.py structure.cif MY_ZEOLITE
   ```

2. **Generation Phase**: Use standard zeoran workflow with preprocessed data
   ```bash
   # Create generate.input with MY_ZEOLITE as zeolite name
   ./zeoran  # or build/bin/zeoran
   ```

3. **Output Phase**: Standard CIF output files with proper charge assignments

### Technical Implementation

**No Core Modification Approach:**
The preprocessing system was designed to work with the existing zeoran codebase without requiring modifications to the core algorithms. The `read_unit_cell()` and `read_atom_sites()` functions remain unchanged, ensuring full backward compatibility.

**Extended Format Support:**
While an extended zeoran format was developed to support richer metadata, the final implementation uses the preprocessor-only approach to maintain simplicity and avoid the need for core code changes.

**Robust Error Handling:**
The preprocessing scripts include comprehensive error handling for:
- Invalid file formats
- Missing configuration parameters  
- Inconsistent charge assignments
- File I/O errors
- ASE library integration issues

### Benefits of the New System

1. **Format Flexibility**: Support for multiple input formats without changing core algorithms
2. **No Reinstallation Required**: Adding new zeolites doesn't require recompiling zeoran
3. **Configuration Transparency**: Clear separation between input data and processing parameters
4. **Backward Compatibility**: Existing zeoran data files continue to work unchanged
5. **Extensibility**: Easy to add support for additional file formats
6. **Charge Management**: Sophisticated handling of charge information with clear priorities
7. **Self-Contained Operation**: CIF files can be processed without requiring external configuration

This enhancement significantly improves the software's accessibility and utility for researchers working with diverse crystallographic data sources while maintaining the robust algorithm performance that makes zeoran valuable for zeolite research.

## Recent Updates: Flexible Data Directory Management

The data directory system has been refined to provide maximum flexibility while maintaining simplicity in the core zeoran source code. The approach separates concerns between simple source code logic and flexible deployment via environment variables and workflow scripts.

### Simple Source Code Approach

The zeoran executable uses a straightforward priority system for locating data files:

```cpp
// Priority order for finding data files:
// 1. Local directories: ./atom_sites/ and ./unit_cell/
// 2. Environment variable: ZEORAN_DATA_DIR
// 3. Build directory: ./build/share/zeoran/
// 4. System install: /usr/local/share/zeoran/

string local_atom_sites = "./atom_sites/" + name_zeo + ".txt";
if (access(local_atom_sites.c_str(), F_OK) == 0) {
    file_zeo = local_atom_sites;
    cout << "Using local atom_sites file: " << file_zeo << endl;
} else {
    // Fall back to install location via environment variable or build directory
    char* env_data_dir = getenv("ZEORAN_DATA_DIR");
    if (env_data_dir != nullptr) {
        install_data_dir = string(env_data_dir);
    }
    // ... additional fallback logic
}
```

### Flexible Deployment Strategies

**1. Local Directory Approach (Highest Priority):**
```bash
mkdir atom_sites unit_cell
# Copy zeolite files to local directories
./zeoran  # Uses local directories directly
```

**2. Environment Variable Approach:**
```bash
export ZEORAN_DATA_DIR=/path/to/your/data
./zeoran  # Uses custom data directory
```

**3. Organized Repository Structure:**
```bash
# Demo workflow sets ZEORAN_DATA_DIR to repo's zeoran_data/
ZEORAN_DATA_DIR="$(pwd)/zeoran_data" ./zeoran
```

**4. Build Directory Fallback:**
```bash
# Automatic fallback when no local files or environment variable
./zeoran  # Uses ./build/share/zeoran/ or /usr/local/share/zeoran/
```

### Demo Workflow Integration

The `demo_workflow.sh` script exemplifies the flexible approach by setting the environment variable to maintain organized file structure:

```bash
# Get absolute path to the repo directory for zeoran_data
REPO_DIR=$(cd "$(dirname "$0")" && pwd)

# Set ZEORAN_DATA_DIR to point to repo's zeoran_data for organized structure
export ZEORAN_DATA_DIR="$REPO_DIR/zeoran_data"
echo "Setting ZEORAN_DATA_DIR to: $ZEORAN_DATA_DIR"

# Run zeoran with organized data directory
./build/bin/zeoran
```

### Benefits of the Flexible System

1. **Simple Source Code**: No complex path detection logic in zeoran.cpp
2. **Multiple Usage Patterns**: Supports different deployment scenarios
3. **Organized Development**: Repo maintains structured zeoran_data/ organization
4. **Flexible Deployment**: Environment variable allows any custom location
5. **Reliable Fallback**: Always has build directory as backup
6. **No Reinstallation**: Adding new zeolites doesn't require recompilation
7. **Clear Priority**: Predictable file location resolution

### Installation and Data File Management

The CMake build system automatically installs zeolite data files:

```cmake
install(DIRECTORY zeoran_data/atom_sites DESTINATION share/zeoran)
install(DIRECTORY zeoran_data/unit_cell DESTINATION share/zeoran)
```

**Installation Flow:**
1. **Build Time**: `zeoran_data/` → `build/share/zeoran/`
2. **Runtime Priority**: Local → Environment → Build → System
3. **Preprocessing**: CIF files → `zeoran_data/` structure
4. **Execution**: Environment variable points to organized structure

This architecture provides the flexibility users need while keeping the core algorithms simple and maintainable. The preprocessing system writes to organized directories, the build system installs data files appropriately, and the runtime system locates files through a clear priority hierarchy.

## Recent Updates: Multi-Format Output System

A comprehensive multi-format output system has been implemented, enabling the software to generate structures in both traditional crystallographic (CIF) and molecular dynamics (GROMACS) formats. This enhancement significantly expands the software's utility for different simulation workflows.

### GROMACS Format Support

The software now supports complete GROMACS-compatible output with proper format compliance:

**GRO File Format:**
- **Cartesian Coordinates**: Positions in nanometers with proper unit conversion from Ångström
- **Fixed-Width Columns**: Strict adherence to GROMACS format specification
- **Velocity Fields**: Zero velocities included for molecular dynamics initialization
- **Box Vectors**: Proper periodic boundary condition support

**ITP Topology Files:**
- **Atom Definitions**: Complete topology with atom types, charges, and masses
- **Residue Information**: Consistent shortened residue names (max 5 characters)
- **GROMACS Compatibility**: Standard format for molecular dynamics simulations

### Implementation Architecture

**Output Module Structure:**
The output functionality has been extracted into a dedicated module for better organization:

```cpp
// output.h - Function declarations
void print_structure(atom *list, vector<int> Als, int struc, string name_zeo, string name_alg, string out_name);
void print_gro_structure(atom *list, vector<int> Als, int struc, string name_zeo, string name_alg, string out_name);

// output.cpp - Implementation with proper GROMACS formatting
void print_gro_structure(atom *list, vector<int> Als, int struc, string name_zeo, string name_alg, string out_name) {
    // GRO format: %5d%-5s%5s%5d%8.3f%8.3f%8.3f%8.4f%8.4f%8.4f
    // ITP format: Complete topology with masses and charges
}
```

**Conditional Output System:**
The main zeoran executable uses a flexible output system based on the `output_formats` setting:

```cpp
// All four algorithms (chains, clusters, merw, random) support conditional output
if (output_formats == "cif" || output_formats == "all") {
    print_structure(list, Als, struc, name_zeo, name_alg, out_name);
}
if (output_formats == "gro" || output_formats == "all") {
    print_gro_structure(list, Als, struc, name_zeo, name_alg, out_name);
}
```

### Format Selection Integration

**Preprocessor Control:**
The preprocessing system now supports output format selection via command-line arguments:

```bash
# Universal preprocessor with format selection
python preprocess -i input.cif -n NAME -o gro     # GRO output only
python preprocess -i input.cif -n NAME -o all    # All formats
python preprocess -i input.gro -n NAME -c config  # Auto-detects GRO input
```

**Intelligent Defaults:**
- CIF input files default to CIF output
- GRO input files default to GRO output  
- User can override via `--output-formats` parameter
- Settings stored in unit_cell files for runtime control

**Unit Cell File Extension:**
The unit_cell file format has been extended to include output format control:

```
Number of atoms:    576
Number of T-atoms:  192
a:                  24.5550
b:                  24.5550
c:                  24.5550
alpha:              90.0
beta:              90.0
gamma:              90.0
setting:            cubic
output_formats:     all    # New field for format control
```

### GROMACS Format Compliance

**Coordinate Conversion:**
Proper unit conversion from crystallographic to molecular dynamics conventions:

```cpp
// Convert from fractional to Cartesian coordinates, then to nanometers
double x_cart = fract_x * unit_cell_a;  // Ångström
double x_gro = x_cart / 10.0;           // Convert to nanometers

// Proper rounding and formatting for GROMACS
fprintf(fout, "%5d%-5s%5s%5d%8.3f%8.3f%8.3f%8.4f%8.4f%8.4f
",
        residue_number, residue_name, atom_name, atom_number,
        x_gro, y_gro, z_gro, 0.0, 0.0, 0.0);
```

**Residue Name Handling:**
Consistent shortened residue names to meet GROMACS 5-character limit:

```cpp
string shortened_name = name_zeo.substr(0, 5);  // Max 5 characters
// Used consistently in both GRO coordinates and ITP topology
```

**Mass Assignment:**
Proper atomic masses for different elements:

```cpp
double mass = (atom.type == "Si") ? 28.0860 : 
              (atom.type == "Al") ? 26.9820 : 
              (atom.type == "O")  ? 15.9990 : 1.0000;
```

### Benefits of Multi-Format Output

1. **Workflow Flexibility**: Support for both crystallographic and molecular dynamics workflows
2. **Format Preservation**: Maintains exact atom ordering between CIF and GRO outputs
3. **GROMACS Compatibility**: Fully compliant with GROMACS format specifications
4. **Topology Generation**: Automatic ITP file creation for molecular dynamics setup
5. **Coordinate Accuracy**: Proper unit conversion with precision preservation
6. **Residue Consistency**: Shortened names used consistently across formats
7. **Conditional Generation**: Efficient output based on user requirements

### Technical Implementation Details

**No Algorithm Modification:**
The multi-format system was implemented without modifying any of the core zeolite generation algorithms (chains, clusters, merw, random). This ensures:
- Full backward compatibility
- Preservation of algorithm correctness
- Clean separation of concerns
- Easy maintenance and testing

**Global Variable Management:**
Proper separation of declarations and definitions:

```cpp
// global.h - declarations
extern std::string output_formats;

// globals.cpp - definitions  
std::string output_formats = "cif";  // Default value
```

**Dynamic Metadata:**
Output files use current system information rather than hardcoded values:

```cpp
// Get current user and date
const char* username = getenv("USER");
time_t rawtime;
struct tm * timeinfo;
char date_buffer[80];
time(&rawtime);
timeinfo = localtime(&rawtime);
strftime(date_buffer, sizeof(date_buffer), "%Y-%m-%d", timeinfo);
```

This multi-format output system provides the foundation for integrating zeoran with diverse computational chemistry and materials science workflows while maintaining the software's core algorithmic strengths.

## Recent Updates: Modular Code Refactoring

To improve code maintainability and organization, the zeoran codebase has undergone significant modular refactoring. This work separates concerns and creates a cleaner architecture while maintaining full backward compatibility.

### Output Module Extraction

The output writing functionality has been extracted from the main `zeoran.cpp` file into a dedicated module:

**New Files Created:**
- `output.h` - Header file with output function declarations
- `output.cpp` - Implementation of output writing functionality  
- `globals.cpp` - Global variable definitions (separated from declarations)

**Key Changes:**
1. **Separation of Concerns**: Output formatting logic is now isolated from algorithm logic
2. **Dynamic Metadata**: Output files now use current user name and date instead of hardcoded values
3. **Proper Global Variable Management**: Variables are now declared in headers with `extern` and defined in a separate source file

### Dynamic Metadata Generation

The output module now generates dynamic metadata for CIF files:

```cpp
// Get current date
time_t rawtime;
struct tm * timeinfo;
char date_buffer[80];
time(&rawtime);
timeinfo = localtime(&rawtime);
strftime(date_buffer, sizeof(date_buffer), "%Y-%m-%d", timeinfo);

// Get current user name
const char* username = getenv("USER");
if (username == nullptr) {
    username = getenv("USERNAME"); // Windows fallback
}

// Write to CIF file
fout << "_audit_creation_date " << date_buffer << endl;
fout << "_audit_author_name '" << username << "'" << endl;
```

**Benefits:**
- **Accurate Metadata**: Files contain actual creation date and author information
- **No Hardcoded Values**: Eliminates outdated static information in output files
- **Cross-Platform Support**: Works on both Unix-like and Windows systems
- **Accurate Timestamps**: Files reflect when they were actually generated
- **User Tracking**: Clear attribution of who generated each structure
- **Cross-Platform Support**: Works on both Unix/Linux and Windows systems

### Global Variable Architecture

To resolve multiple definition issues during compilation, global variables have been restructured:

**Before (global.h):**
```cpp
int Natoms, Tatoms;  // Definitions in header - causes multiple definition errors
double a, b, c;
// ...
```

**After (global.h + globals.cpp):**
```cpp
// global.h - Declarations only
extern int Natoms, Tatoms;
extern double a, b, c;
// ...

// globals.cpp - Definitions
int Natoms, Tatoms;
double a, b, c;
// ...
```

This approach follows C++ best practices and eliminates linker errors when including headers in multiple source files.

### Build System Updates

Both CMake and Makefile configurations have been updated to include the new source files:

**CMakeLists.txt:**
```cmake
set(SOURCES
    zeoran.cpp
    output.cpp
    globals.cpp
    global.h
    headers.h
    libraries.h
    output.h
)
```

**Makefile:**
```make
$(BIN_DIR)/zeoran: zeoran.cpp output.cpp globals.cpp global.h headers.h libraries.h output.h
	$(CXX) $(CXXFLAGS) zeoran.cpp output.cpp globals.cpp -o $@ $(CXXINCLUDES) $(LDFLAGS)
```

### Testing Framework Updates

The testing framework has been enhanced to accommodate the new dynamic metadata:

**Updated Comparison Logic:**
```bash
# Filter out the audit date and author lines before comparison
grep -v "_audit_creation_date" "$ref_file" | grep -v "_audit_author_name" > "$temp_ref"
grep -v "_audit_creation_date" "$out_file" | grep -v "_audit_author_name" > "$temp_out"

if diff -q "$temp_ref" "$temp_out" > /dev/null; then
    echo "  PASS: $file_name matches reference (ignoring metadata)"
else
    echo "  FAIL: $file_name differs from reference"
    differences=$((differences + 1))
fi
```

This ensures that tests validate the scientific content while ignoring the expected metadata differences.

### Code Quality Improvements

The modular refactoring brings several quality improvements:

1. **Maintainability**: Output logic is now isolated and easier to modify
2. **Testability**: Individual modules can be tested independently
3. **Reusability**: Output functionality could be reused in other projects
4. **Readability**: Main algorithm file is shorter and more focused
5. **Standards Compliance**: Proper separation of declarations and definitions

### Migration Path

The refactoring maintains full backward compatibility:

- **Existing Workflows**: All existing usage patterns continue to work unchanged
- **Algorithm Integrity**: Core algorithms remain identical with verified test results
- **File Formats**: Output file structure is preserved except for metadata improvements
- **Build Process**: Standard build commands continue to work as before

### Future Development

The modular architecture provides a foundation for future enhancements:

- **Additional Output Formats**: Easy to add new output writers (e.g., XYZ, PDB)
- **Configurable Metadata**: Metadata could be made configurable via input files
- **Plugin Architecture**: Output modules could be developed as plugins
- **Performance Optimizations**: Individual modules can be optimized independently

This refactoring demonstrates best practices for scientific software development while maintaining the reliability and performance that researchers depend on for their zeolite generation workflows.
