#!/bin/bash

# Setup Script for SAM Proteomics Analysis Pipeline
# This script installs all dependencies and prepares the environment

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}SAM Proteomics Pipeline Setup${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""

# Check Python
echo -e "${BLUE}Checking Python...${NC}"
if ! command -v python3 &> /dev/null; then
    echo -e "${YELLOW}Python 3 not found. Please install Python 3.8 or higher${NC}"
    exit 1
fi
python3 --version
echo ""

# Check R
echo -e "${BLUE}Checking R...${NC}"
if ! command -v Rscript &> /dev/null; then
    echo -e "${YELLOW}R not found. Installing R...${NC}"
    
    # Detect OS and install R
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if command -v apt-get &> /dev/null; then
            sudo apt-get update
            sudo apt-get install -y r-base
        elif command -v yum &> /dev/null; then
            sudo yum install -y R
        else
            echo "Please install R manually from https://www.r-project.org/"
            exit 1
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        if command -v brew &> /dev/null; then
            brew install r
        else
            echo "Please install R manually from https://www.r-project.org/"
            exit 1
        fi
    else
        echo "Please install R manually from https://www.r-project.org/"
        exit 1
    fi
fi
Rscript --version
echo ""

# Install Python packages
echo -e "${BLUE}Installing Python packages...${NC}"
pip install -r requirements.txt
echo ""

# Install R packages
echo -e "${BLUE}Installing R packages...${NC}"
chmod +x install_r_packages.R
Rscript install_r_packages.R
echo ""

# Make scripts executable
echo -e "${BLUE}Setting up executable permissions...${NC}"
chmod +x run_pipeline.py
chmod +x run_ttest_pipeline.sh
chmod +x preprocessing_gpr/preprocess_gpr.py
echo ""

# Create necessary directories
echo -e "${BLUE}Creating directories...${NC}"
mkdir -p results
mkdir -p preprocessing_gpr
echo ""

echo -e "${GREEN}================================================${NC}"
echo -e "${GREEN}✓ Setup Complete!${NC}"
echo -e "${GREEN}================================================${NC}"
echo ""
echo "Next steps:"
echo "1. Edit config.yaml to set your input/output folders and parameters"
echo "2. Place your GPR files in the experimental and control folders"
echo "3. Run the pipeline:"
echo "   python run_pipeline.py"
echo ""
