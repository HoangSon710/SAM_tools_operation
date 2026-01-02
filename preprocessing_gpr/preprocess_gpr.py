#!/usr/bin/env python3
"""
GPR File Preprocessing for SAM Analysis

This script preprocesses GenePix Results (.gpr) files to create input suitable for SAM tools.
It handles multiple files from experimental and control groups, averages replicates,
and generates an Excel file in the format required by SAM.

Usage:
    python preprocess_gpr.py
    
Or with custom paths:
    python preprocess_gpr.py --experimental /path/to/experimental --control /path/to/control --output /path/to/output
"""

import pandas as pd
import numpy as np
import os
import argparse
from pathlib import Path


def read_gpr_file(filepath, signal_column='F650 Median - B650'):
    """
    Read a GPR file and extract relevant data.
    
    Args:
        filepath: Path to the GPR file
        signal_column: Name of the signal column to extract (default: 'F650 Median - B650')
                      Can also be 'F550 Median - B550' or 'F60 Median - B60'
    
    Returns:
        DataFrame with 'Row' and signal column
    """
    print(f"Reading {os.path.basename(filepath)}...")
    
    # Skip first 31 rows (header information)
    # Try different encodings to handle various file formats
    encodings = ['utf-8', 'latin-1', 'iso-8859-1', 'cp1252']
    df = None
    
    for encoding in encodings:
        try:
            df = pd.read_csv(filepath, sep='\t', skiprows=31, encoding=encoding)
            break
        except (UnicodeDecodeError, Exception) as e:
            if encoding == encodings[-1]:
                raise ValueError(f"Could not read file with any supported encoding: {e}")
            continue
    
    # Check which signal column exists in the file
    available_columns = df.columns.tolist()
    
    # Try to find the appropriate signal column
    signal_col = None
    for col_name in ['F650 Median - B650', 'F550 Median - B550', 'F60 Median - B60']:
        if col_name in available_columns:
            signal_col = col_name
            break
    
    if signal_col is None:
        raise ValueError(f"No valid signal column found in {filepath}. Available columns: {available_columns}")
    
    # Check if 'Row' column exists (might be 'ID' or other column)
    row_col = None
    for col_name in ['ID', 'Row', 'Name']:
        if col_name in available_columns:
            row_col = col_name
            break
    
    if row_col is None:
        raise ValueError(f"No valid row identifier column found in {filepath}")
    
    # Select only the row identifier and signal columns
    df_selected = df[[row_col, signal_col]].copy()
    df_selected.columns = ['Row', 'Signal']
    
    print(f"  Found {len(df_selected)} rows using column '{signal_col}'")
    
    return df_selected


def remove_control_rows(df):
    """
    Remove control/calibration rows that should not be included in analysis.
    
    Args:
        df: DataFrame with 'Row' column
    
    Returns:
        Filtered DataFrame
    """
    rows_to_remove = [
        "Cy3 3x and Cy5 2400x mixture",
        "Blank",
        "Poly-L-lysine",
        "BSA",
        "Lectin",
        "ProteinA",
        "empty",
        "blank",
        "a-His 1x",
        "streptavidin",
        "buffer",
        "0.96uM proteinG",
        "Cy3-Ab andCy5 mixtures x250",
        "6.6uM Poly-L-Lysine x50",
        "0.0182uM biotin",
        "105.48uml nagA",
        "13.19uml nagA",
        "1687.72uml nagA",
        "211uml nagA",
        "26.37uml nagA",
        "421.93uml nagA",
        "52.74uml nagA",
        "6.59uml nagA",
        "843.86uml nagA"
    ]
    
    initial_count = len(df)
    df_filtered = df[~df['Row'].isin(rows_to_remove)].copy()
    removed_count = initial_count - len(df_filtered)
    
    print(f"  Removed {removed_count} control rows")
    print(f"  Remaining: {len(df_filtered)} data rows")
    
    return df_filtered


def average_replicates(df):
    """
    Average signal values for rows with the same identifier.
    
    Args:
        df: DataFrame with 'Row' and 'Signal' columns
    
    Returns:
        DataFrame with averaged values per unique Row
    """
    print("  Averaging replicates...")
    
    # Convert Signal to numeric, handling any non-numeric values
    df['Signal'] = pd.to_numeric(df['Signal'], errors='coerce')
    
    # Group by Row and calculate mean
    df_avg = df.groupby('Row')['Signal'].mean().reset_index()
    
    print(f"  Averaged to {len(df_avg)} unique proteins/features")
    
    return df_avg


def process_gpr_files(file_paths):
    """
    Process multiple GPR files and combine them.
    
    Args:
        file_paths: List of paths to GPR files
    
    Returns:
        List of DataFrames, one per file with averaged replicates within each file
    """
    all_data = []
    
    for filepath in file_paths:
        # Read file
        df = read_gpr_file(filepath)
        
        # Remove control rows
        df = remove_control_rows(df)
        
        # Average replicates within this file
        df = average_replicates(df)
        
        # Rename Signal column to the filename
        filename = Path(filepath).stem
        df = df.rename(columns={'Signal': filename})
        
        all_data.append(df)
    
    return all_data


def create_sam_input(experimental_dfs, control_dfs, output_path):
    """
    Create SAM tool input format from experimental and control data.
    
    Args:
        experimental_dfs: List of DataFrames with experimental group data (one per file)
        control_dfs: List of DataFrames with control group data (one per file)
        output_path: Path to save the output Excel file
    
    Format:
        First row: Sample labels with group indicators (1 for experimental, 2 for control)
        First column: Gene/Protein IDs
        Second column: Gene/Protein names (same as IDs in this case)
        Remaining columns: Expression values (one column per file)
    """
    print("\nCreating SAM input format...")
    
    n_exp_samples = len(experimental_dfs)
    n_ctrl_samples = len(control_dfs)
    
    # Merge all experimental files
    if experimental_dfs:
        merged_df = experimental_dfs[0]
        for df in experimental_dfs[1:]:
            merged_df = pd.merge(merged_df, df, on='Row', how='outer')
    else:
        merged_df = pd.DataFrame(columns=['Row'])
    
    # Merge all control files
    for df in control_dfs:
        merged_df = pd.merge(merged_df, df, on='Row', how='outer')
    
    # Fill NaN values with the median of each column (better than 0 for protein data)
    for col in merged_df.columns:
        if col != 'Row':
            median_val = merged_df[col].median()
            if pd.isna(median_val):
                median_val = 0
            merged_df[col] = merged_df[col].fillna(median_val)
    
    # Create header row with group labels: 1 for experimental, 2 for control
    header_row = ['', ''] + [1] * n_exp_samples + [2] * n_ctrl_samples
    
    # Create data rows
    data_rows = []
    for _, row in merged_df.iterrows():
        data_row = [
            row['Row'],  # Gene ID
            row['Row'],  # Gene Name (same as ID)
        ]
        # Add experimental values
        for df in experimental_dfs:
            col_name = [c for c in df.columns if c != 'Row'][0]
            data_row.append(row[col_name])
        # Add control values
        for df in control_dfs:
            col_name = [c for c in df.columns if c != 'Row'][0]
            data_row.append(row[col_name])
        
        data_rows.append(data_row)
    
    # Combine into final DataFrame
    sam_df = pd.DataFrame([header_row] + data_rows)
    
    # Save to Excel
    print(f"Saving to {output_path}...")
    sam_df.to_excel(output_path, index=False, header=False)
    
    print(f"✓ SAM input file created successfully!")
    print(f"  Total proteins/features: {len(data_rows)}")
    print(f"  Experimental samples (label=1): {n_exp_samples}")
    print(f"  Control samples (label=2): {n_ctrl_samples}")
    
    return sam_df


def main():
    """Main function to run the preprocessing pipeline."""
    parser = argparse.ArgumentParser(description='Preprocess GPR files for SAM analysis')
    parser.add_argument('--experimental', type=str, 
                       default='../example_GPR/experimental_group',
                       help='Path to experimental group folder')
    parser.add_argument('--control', type=str,
                       default='../example_GPR/control_group',
                       help='Path to control group folder')
    parser.add_argument('--output', type=str,
                       default='./sam_input.xlsx',
                       help='Output Excel file path')
    
    args = parser.parse_args()
    
    # Convert to absolute paths
    script_dir = Path(__file__).parent
    exp_dir = (script_dir / args.experimental).resolve()
    ctrl_dir = (script_dir / args.control).resolve()
    output_path = (script_dir / args.output).resolve()
    
    print("="*60)
    print("GPR Preprocessing for SAM Analysis")
    print("="*60)
    print(f"Experimental group folder: {exp_dir}")
    print(f"Control group folder: {ctrl_dir}")
    print(f"Output file: {output_path}")
    print()
    
    # Find all GPR files in experimental group
    exp_files = list(exp_dir.glob('*.gpr'))
    if not exp_files:
        print(f"Warning: No .gpr files found in {exp_dir}")
        print("Creating empty experimental dataset...")
        experimental_df = pd.DataFrame(columns=['Row', 'Signal'])
    else:
        print(f"Processing {len(exp_files)} experimental file(s):")
        for f in exp_files:
            print(f"  - {f.name}")
        print()
        experimental_df = process_gpr_files(exp_files)
    
    # Find all GPR files in control group
    ctrl_files = list(ctrl_dir.glob('*.gpr'))
    if not ctrl_files:
        raise ValueError(f"Error: No .gpr files found in {ctrl_dir}")
    
    print(f"\nProcessing {len(ctrl_files)} control file(s):")
    for f in ctrl_files:
        print(f"  - {f.name}")
    print()
    control_df = process_gpr_files(ctrl_files)
    
    # Create SAM input
    sam_df = create_sam_input(experimental_df, control_df, output_path)
    
    print()
    print("="*60)
    print("Preprocessing complete!")
    print("="*60)
    print(f"\nNext steps:")
    print(f"1. Review the output file: {output_path}")
    print(f"2. Run SAM analysis using the pipeline:")
    print(f"   ./run_pipeline.sh {output_path.parent} ./sam_results")
    print()


if __name__ == "__main__":
    main()
