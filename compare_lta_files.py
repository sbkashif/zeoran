import numpy as np
from collections import defaultdict

def read_atom_sites(file_path):
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

def analyze_files(file1, file2):
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
    for atom_type, count in atom_types1.items():
        print(f"  {atom_type}: {count}")
    
    print(f"\nFile 2: {file2}")
    print(f"Total atoms: {len(coords2)}")
    for atom_type, count in atom_types2.items():
        print(f"  {atom_type}: {count}")
    
    # Build coordinate histograms
    print("\nBuilding coordinate histograms...")
    hist1 = build_coordinate_histogram(coords1)
    hist2 = build_coordinate_histogram(coords2)
    
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
        for atom_type, diff_count in diff_by_type.items():
            print(f"{atom_type:8} | {diff_count}")
        
        # Sample of specific differences
        if len(differences) > 0:
            print("\nSample differences (first 5):")
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

    # Let's also find some direct coordinate matches
    direct_matches = 0
    coords1_set = {(atom_type, coords) for atom_type, coords in coords1}
    for atom_coords in coords2:
        if atom_coords in coords1_set:
            direct_matches += 1
    
    direct_similarity = direct_matches / len(coords1) * 100 if coords1 else 0
    print(f"Direct coordinate matches: {direct_matches}/{len(coords1)} ({direct_similarity:.2f}%)")

# Compare the files
analyze_files("zeoran_data/atom_sites/LTA.txt", "zeoran_data/atom_sites/LTA_SI.txt")
