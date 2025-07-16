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
