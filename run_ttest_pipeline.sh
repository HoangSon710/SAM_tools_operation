#!/bin/bash

# SAM Proteomics T-test Pipeline Runner
# This script runs the T-test proteomics analysis pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}SAM Proteomics T-test Pipeline${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

# Check if correct number of arguments provided
if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Missing arguments${NC}"
    echo ""
    echo "Usage: ./run_ttest_pipeline.sh <input_folder> <output_folder> [log2fc_cutoff] [d_value_cutoff]"
    echo ""
    echo "Arguments:"
    echo "  input_folder    - Folder containing Excel files"
    echo "  output_folder   - Folder for output files"
    echo "  log2fc_cutoff   - Log2 fold change cutoff (default: 1.0)"
    echo "  d_value_cutoff  - D-value cutoff (default: 2.0)"
    echo ""
    echo "Example:"
    echo "  ./run_ttest_pipeline.sh ./data ./output 1.0 2.0"
    echo ""
    exit 1
fi

INPUT_FOLDER="$1"
OUTPUT_FOLDER="$2"
LOG2FC_CUTOFF="${3:-1.0}"
D_VALUE_CUTOFF="${4:-2.0}"

# Check if input folder exists
if [ ! -d "$INPUT_FOLDER" ]; then
    echo -e "${RED}Error: Input folder does not exist: $INPUT_FOLDER${NC}"
    exit 1
fi

# Check if R is installed
if ! command -v Rscript &> /dev/null; then
    echo -e "${RED}Error: R is not installed or not in PATH${NC}"
    echo "Please install R from https://www.r-project.org/"
    exit 1
fi

echo -e "${BLUE}Input folder:${NC} $INPUT_FOLDER"
echo -e "${BLUE}Output folder:${NC} $OUTPUT_FOLDER"
echo -e "${BLUE}Log2 FC cutoff:${NC} ±$LOG2FC_CUTOFF"
echo -e "${BLUE}D-value cutoff:${NC} ±$D_VALUE_CUTOFF"
echo ""

# Check for required R packages
echo "Checking R dependencies..."
Rscript -e "
required_packages <- c('openxlsx', 'impute')
missing_packages <- required_packages[!sapply(required_packages, requireNamespace, quietly = TRUE)]
if (length(missing_packages) > 0) {
  cat('Missing packages:', paste(missing_packages, collapse=', '), '\n')
  cat('Installing missing packages...\n')
  if ('impute' %in% missing_packages) {
    if (!requireNamespace('BiocManager', quietly = TRUE))
      install.packages('BiocManager', repos='https://cloud.r-project.org')
    BiocManager::install('impute', update=FALSE, ask=FALSE)
    missing_packages <- missing_packages[missing_packages != 'impute']
  }
  if (length(missing_packages) > 0) {
    install.packages(missing_packages, repos='https://cloud.r-project.org', quiet=TRUE)
  }
  cat('Packages installed successfully!\n')
} else {
  cat('All required packages are installed.\n')
}
"

echo ""
echo "Running T-test analysis pipeline..."
echo ""

# Run the R pipeline
Rscript sam_pipeline_ttest.R "$INPUT_FOLDER" "$OUTPUT_FOLDER" "$LOG2FC_CUTOFF" "$D_VALUE_CUTOFF"

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Pipeline execution completed!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Results are available in: $OUTPUT_FOLDER"
echo ""

# Try to open HTML report if on Linux with a browser
HTML_FILE="$OUTPUT_FOLDER/analysis_report_interactive.html"
if [ -f "$HTML_FILE" ]; then
    echo -e "${YELLOW}Interactive HTML report:${NC} $HTML_FILE"
    echo ""
    
    # Show summary of CSV files
    echo -e "${YELLOW}CSV files generated:${NC}"
    ls -lh "$OUTPUT_FOLDER"/*.csv 2>/dev/null || echo "No CSV files found"
    echo ""
    
    # Try to open in browser
    if command -v xdg-open &> /dev/null; then
        read -p "Open HTML report in browser? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            xdg-open "$HTML_FILE" 2>/dev/null || echo "Could not open browser automatically. Please open the HTML file manually."
        fi
    fi
fi
