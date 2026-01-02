#!/usr/bin/env python3
"""
SAM Proteomics Analysis Pipeline - Main Runner
This script orchestrates the complete analysis pipeline from GPR files to results.

Usage:
    python run_pipeline.py [--config config.yaml]
    
Author: SAM Tools Operation
Date: 2026-01-02
"""

import os
import sys
import yaml
import subprocess
import argparse
from pathlib import Path
from datetime import datetime


def load_config(config_file):
    """Load configuration from YAML file."""
    with open(config_file, 'r') as f:
        config = yaml.safe_load(f)
    return config


def check_dependencies():
    """Check if required dependencies are installed."""
    print("Checking dependencies...")
    
    # Check Python packages
    required_python = ['pandas', 'numpy', 'yaml']
    missing_python = []
    
    for package in required_python:
        try:
            __import__(package)
        except ImportError:
            missing_python.append(package)
    
    if missing_python:
        print(f"❌ Missing Python packages: {', '.join(missing_python)}")
        print(f"   Install with: pip install {' '.join(missing_python)}")
        return False
    
    # Check R
    try:
        result = subprocess.run(['Rscript', '--version'], 
                              capture_output=True, text=True)
        if result.returncode != 0:
            print("❌ R is not installed or not in PATH")
            return False
    except FileNotFoundError:
        print("❌ R is not installed or not in PATH")
        return False
    
    print("✓ All dependencies satisfied")
    return True


def run_preprocessing(config):
    """Run GPR preprocessing step."""
    print("\n" + "="*60)
    print("STEP 1: GPR Preprocessing")
    print("="*60)
    
    exp_folder = config['input']['experimental_folder']
    ctrl_folder = config['input']['control_folder']
    output_folder = config['input']['preprocessed_folder']
    
    # Run preprocessing script
    cmd = [
        'python', 'preprocessing_gpr/preprocess_gpr.py',
        '--experimental', exp_folder,
        '--control', ctrl_folder,
        '--output', os.path.join(output_folder, 'sam_input.csv')
    ]
    
    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd)
    
    if result.returncode != 0:
        print("❌ Preprocessing failed")
        return False
    
    print("✓ Preprocessing completed successfully")
    return True


def run_analysis(config):
    """Run statistical analysis step."""
    print("\n" + "="*60)
    print("STEP 2: Statistical Analysis")
    print("="*60)
    
    input_folder = config['input']['preprocessed_folder']
    output_folder = config['output']['results_folder']
    
    # Create timestamped folder if requested
    if config['output'].get('timestamp_folders', False):
        timestamp = datetime.now().strftime('%Y%m%d_%H%M%S')
        output_folder = os.path.join(output_folder, timestamp)
    
    log2fc = config['analysis'].get('log2fc_cutoff', config['analysis'].get('delta', 0.5))
    d_value = config['analysis'].get('d_value_cutoff', config['analysis'].get('min_foldchange', 1.5))
    
    # Run R analysis script
    cmd = [
        'Rscript', 'sam_pipeline_ttest.R',
        input_folder, output_folder,
        str(log2fc), str(d_value)
    ]
    
    print(f"Running: {' '.join(cmd)}")
    result = subprocess.run(cmd)
    
    # Even if there's an error, try to generate HTML from CSV
    if result.returncode != 0:
        print("⚠ Analysis had some issues, attempting to generate HTML report...")
    
    # Generate HTML report
    if config['output_format'].get('generate_html', True):
        csv_files = list(Path(output_folder).glob('*_all_results.csv'))
        if csv_files:
            print("Generating interactive HTML report...")
            html_cmd = [
                'Rscript', 'create_html_report.R',
                output_folder, str(log2fc), str(d_value)
            ]
            subprocess.run(html_cmd)
    
    print(f"✓ Analysis completed. Results saved to: {output_folder}")
    return True


def print_summary(config):
    """Print summary of results."""
    print("\n" + "="*60)
    print("PIPELINE COMPLETED")
    print("="*60)
    
    output_folder = config['output']['results_folder']
    
    print(f"\n📁 Results Location: {output_folder}")
    print("\n📄 Generated Files:")
    
    # List files
    if os.path.exists(output_folder):
        for file in sorted(os.listdir(output_folder)):
            file_path = os.path.join(output_folder, file)
            if os.path.isfile(file_path):
                size = os.path.getsize(file_path)
                size_str = f"{size/1024:.1f} KB" if size < 1024*1024 else f"{size/(1024*1024):.1f} MB"
                print(f"   • {file} ({size_str})")
    
    html_file = os.path.join(output_folder, 'analysis_report_interactive.html')
    if os.path.exists(html_file):
        print(f"\n🌐 Open HTML Report:")
        print(f"   file://{os.path.abspath(html_file)}")
    
    print("\n✓ Pipeline finished successfully!")


def main():
    """Main pipeline execution."""
    parser = argparse.ArgumentParser(
        description='SAM Proteomics Analysis Pipeline',
        formatter_class=argparse.RawDescriptionHelpFormatter,
        epilog="""
Examples:
  # Run with default config
  python run_pipeline.py
  
  # Run with custom config
  python run_pipeline.py --config my_config.yaml
  
  # Skip preprocessing (if already done)
  python run_pipeline.py --skip-preprocessing
        """
    )
    
    parser.add_argument('--config', default='config.yaml',
                       help='Path to configuration file (default: config.yaml)')
    parser.add_argument('--skip-preprocessing', action='store_true',
                       help='Skip GPR preprocessing step')
    parser.add_argument('--skip-analysis', action='store_true',
                       help='Skip statistical analysis step')
    
    args = parser.parse_args()
    
    # Print header
    print("="*60)
    print("SAM PROTEOMICS ANALYSIS PIPELINE")
    print("="*60)
    print(f"Configuration: {args.config}")
    print(f"Started: {datetime.now().strftime('%Y-%m-%d %H:%M:%S')}")
    print("="*60)
    
    # Load configuration
    if not os.path.exists(args.config):
        print(f"❌ Configuration file not found: {args.config}")
        sys.exit(1)
    
    config = load_config(args.config)
    
    # Check dependencies
    if not check_dependencies():
        sys.exit(1)
    
    # Run pipeline steps
    try:
        if not args.skip_preprocessing:
            if not run_preprocessing(config):
                sys.exit(1)
        
        if not args.skip_analysis:
            if not run_analysis(config):
                sys.exit(1)
        
        print_summary(config)
        
    except KeyboardInterrupt:
        print("\n\n⚠ Pipeline interrupted by user")
        sys.exit(1)
    except Exception as e:
        print(f"\n❌ Pipeline failed with error: {str(e)}")
        import traceback
        traceback.print_exc()
        sys.exit(1)


if __name__ == "__main__":
    main()
