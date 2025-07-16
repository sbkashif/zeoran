#!/usr/bin/env python3
"""
Structure Comparison Tool for Zeoran

This script compares atom site files to verify that their atomic structures match,
regardless of the order in which atoms are listed. It's useful for validating that
preprocessing from different CIF formats produces consistent structures.

Usage:
    python compare_structures.py file1.txt file2.txt

Options:
    --bin-size FLOAT    Size of coordinate bins for comparison (default: 0.01)
    --verbose           Show detailed comparison information
"""

import sys
import argparse
from collections import defaultdict

def read_atom_sites(file_path):
    """Read atom coordinates from a zeoran atom_sites file"""
    coordinates = []
    with open(file_path, 'r') as f:
        for line in f:
            parts = line.strip().split()
            if len(parts) >= 5:
                # Extract atom type and coordinates
                atom_type = parts[0]
                try:
                    x, y, z = float(parts[2]), float(parts[3]), float(parts[4])
                    coordinates.append((atom_type, (x, y, z)))
                except (ValueError, IndexError):
                    print(f"Skipping malformed line: {line.strip()}")
    return coordinates

def build_coordinate_histogram(coordinates, bin_size=0.01):
    """Group coordinates into bins to compare distributions"""
    histogram = defaultdict(int)
    for atom_type, (x, y, z) in coordinates:
        # Round coordinates to create bins
        binned_coords = (round(x/bin_size)*bin_size, 
                        round(y/bin_size)*bin_size, 
                        round(z/bin_size)*bin_size)
        # Store as atom_type + coordinates
        key = (atom_type, binned_coords)
        histogram[key] += 1
    return histogram

def compare_structures(file1, file2, bin_size=0.01, verbose=False):
    """Compare two structure files and return similarity metrics"""
    print(f"Reading {file1}...")
    coords1 = read_atom_sites(file1)
    print(f"Reading {file2}...")
    coords2 = read_atom_sites(file2)
    
    # Count atom types
    atom_types1 = defaultdict(int)
    atom_types2 = defaultdict(int)
    
    for atom_type, _ in coords1:
        atom_types1[atom_type] += 1
    
    for atom_type, _ in coords2:
        atom_types2[atom_type] += 1
    
    print(f"File 1: {file1}")
    print(f"Total atoms: {len(coords1)}")
    for atom_type, count in sorted(atom_types1.items()):
        print(f"  {atom_type}: {count}")
    
    print(f"\nFile 2: {file2}")
    print(f"Total atoms: {len(coords2)}")
    for atom_type, count in sorted(atom_types2.items()):
        print(f"  {atom_type}: {count}")
    
    # Check if atom counts match
    if atom_types1 != atom_types2:
        print("\nWARNING: Atom type counts do not match between files!")
    
    # Build coordinate histograms
    print("\nBuilding coordinate histograms (bin size: {})...".format(bin_size))
    hist1 = build_coordinate_histogram(coords1, bin_size)
    hist2 = build_coordinate_histogram(coords2, bin_size)
    
    # Compare distributions
    print("Comparing distributions...")
    all_keys = set(hist1.keys()) | set(hist2.keys())
    differences = []
    
    for key in all_keys:
        if hist1.get(key, 0) != hist2.get(key, 0):
            differences.append((key, hist1.get(key, 0), hist2.get(key, 0)))
    
    # Analyze differences by atom type
    diff_by_type = defaultdict(int)
    for (atom_type, _), count1, count2 in differences:
        diff_by_type[atom_type] += abs(count1 - count2)
    
    if differences:
        print("\nDifferences found in coordinate distributions:")
        print("Atom Type | Coordinate Differences")
        print("-" * 40)
        for atom_type, diff_count in sorted(diff_by_type.items()):
            print(f"{atom_type:8} | {diff_count}")
        
        # Sample of specific differences
        if verbose and len(differences) > 0:
            print("\nSample differences (up to 5):")
            for i, ((atom_type, coords), count1, count2) in enumerate(differences[:5]):
                print(f"{atom_type} at {coords}: {count1} vs {count2}")
    else:
        print("\nThe coordinate distributions are identical!")
    
    # Overall similarity
    common_positions = 0
    for key in all_keys:
        common_positions += min(hist1.get(key, 0), hist2.get(key, 0))
    
    similarity = common_positions / len(coords1) * 100 if coords1 else 0
    print(f"\nOverall structural similarity: {similarity:.2f}%")

    return similarity == 100.0

def main():
    parser = argparse.ArgumentParser(description='Compare zeoran structure files')
    parser.add_argument('file1', help='First structure file')
    parser.add_argument('file2', help='Second structure file')
    parser.add_argument('--bin-size', type=float, default=0.01, 
                        help='Size of coordinate bins for comparison (default: 0.01)')
    parser.add_argument('--verbose', action='store_true',
                        help='Show detailed comparison information')
    
    args = parser.parse_args()
    
    success = compare_structures(args.file1, args.file2, args.bin_size, args.verbose)
    sys.exit(0 if success else 1)

if __name__ == "__main__":
    main()
