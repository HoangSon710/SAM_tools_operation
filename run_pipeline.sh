#!/bin/bash

# SAM Proteomics Pipeline Runner
# This script runs the SAM proteomics analysis pipeline

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}SAM Proteomics Pipeline${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""

# Check if correct number of arguments provided
if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Missing arguments${NC}"
    echo ""
    echo "Usage: ./run_pipeline.sh <input_folder> <output_folder>"
    echo ""
    echo "Example:"
    echo "  ./run_pipeline.sh ./data ./output"
    echo ""
    exit 1
fi

INPUT_FOLDER="$1"
OUTPUT_FOLDER="$2"

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

echo -e "${YELLOW}Input folder:${NC} $INPUT_FOLDER"
echo -e "${YELLOW}Output folder:${NC} $OUTPUT_FOLDER"
echo ""

# Check for required R packages
echo "Checking R dependencies..."
Rscript -e "
required_packages <- c('shiny', 'openxlsx', 'samr', 'GSA', 'impute')
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
echo "Running SAM analysis pipeline..."
echo ""

# Run the R pipeline
Rscript sam_pipeline.R "$INPUT_FOLDER" "$OUTPUT_FOLDER"

echo ""
echo -e "${GREEN}============================================${NC}"
echo -e "${GREEN}Pipeline execution completed!${NC}"
echo -e "${GREEN}============================================${NC}"
echo ""
echo "Results are available in: $OUTPUT_FOLDER"
echo ""

# Try to open HTML report if on Linux with a browser
HTML_FILE="$OUTPUT_FOLDER/sam_analysis_report.html"
if [ -f "$HTML_FILE" ]; then
    echo "HTML report: $HTML_FILE"
    
    # Try to open in browser
    if command -v xdg-open &> /dev/null; then
        echo ""
        read -p "Open HTML report in browser? (y/n) " -n 1 -r
        echo ""
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            xdg-open "$HTML_FILE" 2>/dev/null || echo "Could not open browser automatically. Please open the HTML file manually."
        fi
    fi
fi
