#!/usr/bin/env python3
"""
Example usage of the GRO preprocessing module

This script demonstrates how to use preprocess_gro.py to convert
GRO files into the format required by zeoran.cpp
"""

import sys
import os

# Add the current directory to Python path to import our module
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

try:
    from preprocess_gro import process_gro_to_zeoran
    
    # Example usage
    def example_usage():
        """
        Example of how to process a GRO file for zeoran input
        """
        
        # Path to your GRO file
        gro_file = "zeoran_data/structure.gro"  # Replace with actual path
        
        # Path to configuration YAML file
        config_file = "example_gro_config.yaml"
        
        # Output prefix for generated files
        output_prefix = "LTA_from_gro"
        
        print("Processing GRO file for zeoran...")
        print(f"Input GRO file: {gro_file}")
        print(f"Configuration: {config_file}")
        print(f"Output prefix: {output_prefix}")
        
        try:
            # Process the GRO file
            process_gro_to_zeoran(gro_file, config_file, output_prefix)
            
            print("\nSuccess! Generated files:")
            print(f"- {output_prefix}.txt (atom sites)")
            print(f"- {output_prefix}_unit_cell.txt (unit cell parameters)")
            print(f"- {output_prefix}.input (zeoran input file)")
            
            print("\nTo run zeoran with this input:")
            print(f"./build/bin/zeoran < {output_prefix}.input")
            
        except FileNotFoundError as e:
            print(f"Error: File not found - {e}")
            print("Make sure your GRO file and YAML config file exist")
            
        except ValueError as e:
            print(f"Configuration error: {e}")
            print("Check that your config file contains all required sections:")
            print("- unit_cell: with a, b, c, alpha, beta, gamma, setting")
            print("- charges: with charges for ALL atom types in your GRO file")
            print("- masses: (optional) with masses for atom types")
            
        except Exception as e:
            print(f"Error processing GRO file: {e}")
    
    if __name__ == "__main__":
        example_usage()
        
except ImportError as e:
    print(f"Import error: {e}")
    print("This is expected if numpy and pyyaml are not installed")
    print("To install dependencies: pip install numpy pyyaml")
