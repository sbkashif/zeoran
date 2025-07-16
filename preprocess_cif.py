#!/usr/bin/env python3
"""
Zeoran CIF Preprocessor

This script automates the preprocessing of CIF files for use with Zeoran.
It extracts unit cell information and atom positions from CIF files and
generates the files needed by Zeoran.

Usage:
    python preprocess_cif.py <cif_file> <zeolite_name>

Example:
    python preprocess_cif.py zeoran_data/cif_files/Framework_0_initial_1_1_1_P1.cif LTA

Author: GitHub Copilot
Date: July 16, 2025
"""

import os
import sys
import numpy as np
from ase.io import read
import shutil

def ensure_directory(path):
    """Create directory if it doesn't exist"""
    os.makedirs(path, exist_ok=True)

def generate_unit_cell_file(atoms, zeolite_name, output_dir):
    """Generate unit_cell file from ASE Atoms object"""
    # Count T-atoms (Si)
    t_atoms_count = sum(1 for atom in atoms.get_chemical_symbols() if atom == 'Si')
    
    if t_atoms_count == 0:
        print("WARNING: No silicon (Si) atoms found in the CIF file!")
        print("This will cause problems as zeoran expects Si atoms to substitute with Al.")
        
    # Get cell parameters
    a, b, c, alpha, beta, gamma = atoms.cell.cellpar()
    
    # Validate cell parameters
    if a <= 0 or b <= 0 or c <= 0:
        raise ValueError(f"Invalid cell parameters: a={a}, b={b}, c={c}. All dimensions must be positive.")
    
    # Determine lattice setting
    # This is a simplified approach; could be extended for more complex cases
    setting = "cubic"
    if abs(a - b) > 1e-6 or abs(a - c) > 1e-6 or abs(b - c) > 1e-6:
        setting = "orthorhombic"
    if abs(alpha - 90) > 1e-6 or abs(beta - 90) > 1e-6 or abs(gamma - 90) > 1e-6:
        setting = "triclinic"  # Most general case
    
    # Create unit_cell directory if it doesn't exist
    unit_cell_dir = os.path.join(output_dir, "unit_cell")
    ensure_directory(unit_cell_dir)
    
    # Write to unit_cell file
    unit_cell_file = os.path.join(unit_cell_dir, f"{zeolite_name}.txt")
    with open(unit_cell_file, 'w') as f:
        f.write(f"Number of atoms:\t{len(atoms)}\n")
        f.write(f"Number of T-atoms:\t{t_atoms_count}\n")
        f.write(f"a:\t\t\t{a:.4f}\n")
        f.write(f"b:\t\t\t{b:.4f}\n")
        f.write(f"c:\t\t\t{c:.4f}\n")
        f.write(f"alpha:\t\t{alpha}\n")
        f.write(f"beta:\t\t{beta}\n")
        f.write(f"gamma:\t\t{gamma}\n")
        f.write(f"setting:\t\t{setting}\n")
    
    print(f"Generated unit cell file: {unit_cell_file}")
    print(f"  Total atoms: {len(atoms)}")
    print(f"  T-atoms (Si): {t_atoms_count}")
    print(f"  Cell parameters: a={a:.4f}, b={b:.4f}, c={c:.4f}, α={alpha}°, β={beta}°, γ={gamma}°")
    print(f"  Lattice setting: {setting}")
    
    return unit_cell_file

def generate_atom_sites_file(atoms, zeolite_name, output_dir):
    """Generate atom_sites file from ASE Atoms object"""
    # Create atom_sites directory if it doesn't exist
    atom_sites_dir = os.path.join(output_dir, "atom_sites")
    ensure_directory(atom_sites_dir)
    
    # Get fractional coordinates and symbols
    positions = atoms.get_scaled_positions()
    symbols = atoms.get_chemical_symbols()
    
    # Validate positions - check for NaN or out-of-bounds values
    for i, pos in enumerate(positions):
        for j, coord in enumerate(pos):
            if np.isnan(coord) or coord < -0.1 or coord > 1.1:  # Allow slight deviation from [0,1]
                print(f"WARNING: Potentially invalid fractional coordinate at atom {i}: {pos}")
                # Fix the coordinate to be within [0,1]
                positions[i][j] = positions[i][j] % 1.0
    
    # Count atom types
    atom_counts = {}
    for symbol in symbols:
        if symbol in atom_counts:
            atom_counts[symbol] += 1
        else:
            atom_counts[symbol] = 1
    
    # Try to get charges from the CIF file
    # If not available, assign default charges based on atom type
    charges = []
    
    # Extract charges if they exist in the CIF file
    if 'initial_charges' in atoms.arrays:
        charges = atoms.get_initial_charges()
    else:
        # Assign default charges based on element
        for symbol in symbols:
            if symbol == 'Si':
                charges.append(1.5)  # Default charge for Si in zeolites
            elif symbol == 'O':
                charges.append(-0.75)  # Default charge for O in zeolites
            else:
                charges.append(0.0)  # Default for other elements
    
    # Write to atom_sites file
    atom_sites_file = os.path.join(atom_sites_dir, f"{zeolite_name}.txt")
    with open(atom_sites_file, 'w') as f:
        # Exact format matching the original FAU.txt file:
        # Si       Si     0.946080000000     0.125300000000     0.035890000000     2.05       
        for i in range(len(atoms)):
            # Format: element(8 chars) element(6 chars) x(17 chars) y(17 chars) z(17 chars) charge(10 chars)
            f.write(f"{symbols[i]:<8} {symbols[i]:<6} {positions[i][0]:.12f} {positions[i][1]:.12f} {positions[i][2]:.12f} {charges[i]:<10.6f}\n")
    
    print(f"Generated atom sites file: {atom_sites_file}")
    print(f"  Total atoms: {len(atoms)}")
    print(f"  Atom types: {atom_counts}")
    print(f"  Charge assignment: {'From CIF file' if 'initial_charges' in atoms.arrays else 'Using default values'}")
    
    # Validate the ratio of Si:O which should be approximately 1:2 in zeolites
    if 'Si' in atom_counts and 'O' in atom_counts:
        si_count = atom_counts['Si']
        o_count = atom_counts['O']
        ratio = o_count / si_count if si_count > 0 else 0
        print(f"  Si:O ratio = 1:{ratio:.2f} (typically around 1:2 in zeolites)")
        if ratio < 1.5 or ratio > 2.5:
            print(f"  WARNING: Unusual Si:O ratio. This may indicate a problem with the input structure.")
    
    return atom_sites_file

def copy_cif_file(cif_path, zeolite_name, output_dir):
    """Log the CIF file path without copying it to zeoran_data/cif_files"""
    # This function now just logs information without copying the file
    print(f"Using CIF file: {cif_path}")
    print(f"Note: CIF file was not copied to keep cif_files directory for inputs only.")

def validate_structure(atoms, unit_cell_file, atom_sites_file):
    """Perform validation checks on the generated structure files"""
    print("\nValidating structure...")
    
    # Check if this is really a zeolite structure
    symbols = atoms.get_chemical_symbols()
    si_count = symbols.count('Si')
    o_count = symbols.count('O')
    al_count = symbols.count('Al')
    
    warnings = []
    
    # 1. Check for presence of Si atoms
    if si_count == 0:
        warnings.append("No silicon (Si) atoms found. Zeoran requires Si atoms to substitute with Al.")
    
    # 2. Check for presence of O atoms
    if o_count == 0:
        warnings.append("No oxygen (O) atoms found. This doesn't appear to be a zeolite structure.")
    
    # 3. Check Si:O ratio
    if si_count > 0 and o_count > 0:
        ratio = o_count / si_count
        if ratio < 1.5 or ratio > 2.5:
            warnings.append(f"Unusual Si:O ratio (1:{ratio:.2f}). Expected around 1:2 for zeolites.")
    
    # 4. Check for pre-existing Al atoms
    if al_count > 0:
        warnings.append(f"Structure already contains {al_count} aluminum atoms. Zeoran may behave unexpectedly.")
    
    # 5. Check file sizes
    if os.path.getsize(unit_cell_file) < 50:
        warnings.append(f"Unit cell file is unusually small ({os.path.getsize(unit_cell_file)} bytes).")
    
    if os.path.getsize(atom_sites_file) < 50:
        warnings.append(f"Atom sites file is unusually small ({os.path.getsize(atom_sites_file)} bytes).")
    
    # Print warnings if any
    if warnings:
        print("\nWARNING: Potential issues detected with the processed structure:")
        for i, warning in enumerate(warnings, 1):
            print(f"  {i}. {warning}")
        print("\nThese issues might cause zeoran to crash or produce unexpected results.")
    else:
        print("  No issues detected. Structure appears valid for zeoran processing.")
    
    return len(warnings) == 0

def main():
    """Main function to process CIF files"""
    if len(sys.argv) < 3:
        print("Usage: python preprocess_cif.py <cif_file> <zeolite_name>")
        sys.exit(1)
    
    cif_file = sys.argv[1]
    zeolite_name = sys.argv[2]
    
    # Default output directory is zeoran_data in the current directory
    output_dir = os.path.join(os.getcwd(), "zeoran_data")
    
    # Check if ZEORAN_DATA_DIR environment variable is set
    if 'ZEORAN_DATA_DIR' in os.environ:
        output_dir = os.environ['ZEORAN_DATA_DIR']
    
    print(f"Reading CIF file: {cif_file}")
    try:
        atoms = read(cif_file)
    except Exception as e:
        print(f"Error reading CIF file: {e}")
        sys.exit(1)
    
    print(f"Processing zeolite: {zeolite_name}")
    print(f"Output directory: {output_dir}")
    
    # Generate required files
    unit_cell_file = generate_unit_cell_file(atoms, zeolite_name, output_dir)
    atom_sites_file = generate_atom_sites_file(atoms, zeolite_name, output_dir)
    copy_cif_file(cif_file, zeolite_name, output_dir)  # Now just logs info, doesn't copy
    
    # Validate the generated files
    validate_structure(atoms, unit_cell_file, atom_sites_file)
    
    print("\nPreprocessing complete!")
    print(f"\nNext steps:")
    print(f"1. Install zeoran using one of the installation scripts:")
    print(f"   - For CMake: ./install_with_cmake.sh")
    print(f"   - For traditional Make: ./install_traditional_make.sh")
    print(f"2. Run zeoran with '{zeolite_name}' as the zeolite name in generate.input")

if __name__ == "__main__":
    main()
