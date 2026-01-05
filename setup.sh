#!/bin/bash

# Setup Script for SAM Proteomics Analysis Pipeline
# This script installs all dependencies and prepares the environment

set -e

GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}========================================================${NC}"
echo -e "${GREEN}  SAM Proteomics Pipeline - Automated Setup${NC}"
echo -e "${GREEN}========================================================${NC}"
echo ""

# Function to check if command exists
command_exists() {
    command -v "$1" &> /dev/null
}

# Function to check R package
check_r_package() {
    Rscript -e "if (!requireNamespace('$1', quietly = TRUE)) quit(status = 1)" &> /dev/null
}

# Detect package manager
detect_package_manager() {
    if command_exists conda; then
        echo "conda"
    elif command_exists apt-get; then
        echo "apt"
    elif command_exists yum; then
        echo "yum"
    elif command_exists brew; then
        echo "brew"
    else
        echo "none"
    fi
}

PKG_MGR=$(detect_package_manager)
echo -e "${BLUE}Detected package manager: ${PKG_MGR}${NC}"
echo ""

# Step 1: Check/Install Python
echo -e "${BLUE}[1/5] Checking Python...${NC}"
if ! command_exists python3; then
    echo -e "${YELLOW}Python 3 not found. Attempting to install...${NC}"
    case $PKG_MGR in
        conda)
            conda install python=3.11 -y
            ;;
        apt)
            sudo apt-get update && sudo apt-get install -y python3 python3-pip
            ;;
        yum)
            sudo yum install -y python3 python3-pip
            ;;
        brew)
            brew install python@3.11
            ;;
        *)
            echo -e "${RED}Cannot install Python. Please install Python 3.8+ manually.${NC}"
            exit 1
            ;;
    esac
fi
python3 --version
echo ""

# Step 2: Check/Install R
echo -e "${BLUE}[2/5] Checking R...${NC}"
if ! command_exists Rscript; then
    echo -e "${YELLOW}R not found. Attempting to install...${NC}"
    case $PKG_MGR in
        conda)
            conda install r-base=4.3 -c conda-forge -y
            ;;
        apt)
            sudo apt-get update
            sudo apt-get install -y r-base r-base-dev build-essential gfortran
            ;;
        yum)
            sudo yum install -y R R-devel gcc gcc-gfortran
            ;;
        brew)
            brew install r
            ;;
        *)
            echo -e "${RED}Cannot install R. Please install R 4.0+ manually.${NC}"
            exit 1
            ;;
    esac
fi
Rscript --version
echo ""

# Step 3: Install Python packages
echo -e "${BLUE}[3/5] Installing Python packages...${NC}"
if [ -f "requirements.txt" ]; then
    pip3 install -r requirements.txt
    echo -e "${GREEN}✓ Python packages installed${NC}"
else
    echo -e "${YELLOW}requirements.txt not found. Skipping Python packages.${NC}"
fi
echo ""

# Step 4: Install R packages (with multiple methods)
echo -e "${BLUE}[4/5] Installing R packages (samr, impute)...${NC}"

# Try conda first if available
if [ "$PKG_MGR" = "conda" ]; then
    echo "Attempting conda installation of r-samr..."
    if conda install r-samr bioconductor-impute -c conda-forge -c bioconda -y; then
        echo -e "${GREEN}✓ R packages installed via conda${NC}"
    else
        echo -e "${YELLOW}Conda installation failed, trying R script...${NC}"
        chmod +x install_r_packages.R
        Rscript install_r_packages.R
    fi
else
    # Install build dependencies for R packages
    echo "Installing build dependencies for R packages..."
    case $PKG_MGR in
        apt)
            sudo apt-get install -y build-essential gfortran libcurl4-openssl-dev libssl-dev libxml2-dev
            ;;
        yum)
            sudo yum install -y gcc gcc-gfortran libcurl-devel openssl-devel libxml2-devel
            ;;
    esac
    
    # Try standard R installation
    chmod +x scripts/install_r_packages.R
    if Rscript scripts/install_r_packages.R; then
        echo -e "${GREEN}✓ R packages installed${NC}"
    else
        echo -e "${YELLOW}Standard installation failed. Trying alternative methods...${NC}"
        chmod +x scripts/install_samr_alternative.sh
        ./scripts/install_samr_alternative.sh
    fi
fi

# Verify R packages
echo ""
echo "Verifying R packages..."
if check_r_package "samr" && check_r_package "impute"; then
    echo -e "${GREEN}✓ samr and impute packages verified${NC}"
else
    echo -e "${RED}✗ R packages verification failed${NC}"
    echo -e "${YELLOW}Please install manually:${NC}"
    echo "  Option 1 (conda): conda install r-samr bioconductor-impute -c conda-forge -c bioconda"
    echo "  Option 2 (R): Rscript install_r_packages.R"
    echo "  Option 3 (Alternative): ./install_samr_alternative.sh"
fi
echo ""

# Step 5: Setup environment
echo -e "${BLUE}[5/5] Setting up environment...${NC}"

# Make scripts executable
chmod +x run_pipeline.py 2>/dev/null || true
chmod +x scripts/preprocessing/preprocess_gpr.py 2>/dev/null || true
chmod +x scripts/sam_pipeline_ttest.R 2>/dev/null || true
chmod +x scripts/create_html_report.R 2>/dev/null || true
chmod +x scripts/install_r_packages.R 2>/dev/null || true
chmod +x scripts/install_samr_alternative.sh 2>/dev/null || true
echo -e "${GREEN}✓ Scripts made executable${NC}"

# Create necessary directories
mkdir -p results
mkdir -p scripts/preprocessing
mkdir -p data/examples/gpr_files/experimental_group
mkdir -p data/examples/gpr_files/control_group
echo -e "${GREEN}✓ Directories created${NC}"

echo ""
echo -e "${GREEN}========================================================${NC}"
echo -e "${GREEN}  ✓ Setup Complete!${NC}"
echo -e "${GREEN}========================================================${NC}"
echo ""
echo -e "${BLUE}Installation Summary:${NC}"
python3 --version
Rscript --version 2>&1 | head -1
echo ""

echo -e "${BLUE}Quick Start Guide:${NC}"
echo "1. Verify installation:"
echo "   Rscript -e 'library(samr); library(impute); cat(\"✓ Ready!\\n\")'"
echo ""
echo "2. Configure your analysis:"
echo "   nano config.yaml  # Edit input/output paths and parameters"
echo ""
echo "3. Prepare your data:"
echo "   - Place experimental GPR files in: data/examples/gpr_files/experimental_group/"
echo "   - Place control GPR files in: data/examples/gpr_files/control_group/"
echo ""
echo "4. Run the pipeline:"
echo "   python run_pipeline.py"
echo ""
echo "5. View results:"
echo "   Open: results/analysis_report_interactive.html"
echo ""
echo -e "${YELLOW}Troubleshooting:${NC}"
echo "  - If samr installation failed: ./scripts/install_samr_alternative.sh"
echo "  - View README.md for detailed instructions"
echo "  - Check config.yaml for parameter explanations"
echo ""
