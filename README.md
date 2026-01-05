# SAM Proteomics Analysis Pipeline

A comprehensive, production-ready pipeline for proteomics differential expression analysis using the **Significance Analysis of Microarrays (SAM)** algorithm. Process GenePix Results (GPR) files with automated preprocessing, statistical testing, and publication-quality visualizations.

[![R](https://img.shields.io/badge/R-4.3+-blue.svg)](https://www.r-project.org/)
[![Python](https://img.shields.io/badge/Python-3.11+-green.svg)](https://www.python.org/)
[![License](https://img.shields.io/badge/license-Research-orange.svg)](LICENSE)

## 🎯 Overview

This pipeline implements the robust SAM algorithm for identifying differentially expressed proteins in microarray proteomics data. It handles the complete workflow from raw GPR files to publication-ready reports with interactive visualizations.

**Key Capabilities:**
- ✅ Fully automated preprocessing with intelligent data cleaning
- ✅ Permutation-based SAM statistical testing with FDR control  
- ✅ Multiple imputation methods for missing values (k-NN)
- ✅ Four types of publication-quality plots (volcano, SAM, fold-change distribution, top genes)
- ✅ Interactive HTML reports with real-time filtering
- ✅ Robust installation with automatic dependency management
- ✅ Configurable via simple YAML file

## 📊 What is SAM?

**Significance Analysis of Microarrays (SAM)** is a statistical technique for finding significant genes in microarray experiments. Unlike traditional t-tests, SAM:

- Uses permutation testing to estimate false discovery rates (FDR)
- Handles small sample sizes more robustly
- Accounts for multiple testing correction
- Provides q-values for each gene to control FDR

**Citation:** Tusher VG, Tibshirani R, Chu G. *Significance analysis of microarrays applied to the ionizing radiation response.* PNAS 2001 98(9):5116-21.

### SAM Web Interface (Optional)

The original SAM tool also provides a web-based GUI via Shiny. To use it:

```r
# Install required packages
install.packages(c("matrixStats", "GSA", "shiny", "openxlsx", "Rcpp"))
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("impute")
install.packages("samr")

# Launch web interface
library(shiny)
library(impute)
runGitHub("SAM", "MikeJSeo")
```

**Note:** Use Firefox or Chrome as your default browser (IE will not work).

This pipeline provides a **command-line alternative** to the web interface with automated batch processing and publication-ready outputs.

## 📂 Project Structure

```
SAM_tools_operation/
├── config.yaml                 # Main configuration file
├── run_pipeline.py            # Pipeline entry point
├── setup.sh                   # Automated installation script
├── environment.yml            # Conda environment specification
├── requirements.txt           # Python dependencies
│
├── scripts/                   # Analysis and utility scripts
│   ├── sam_pipeline_ttest.R          # Main SAM analysis R script
│   ├── create_html_report.R          # HTML report generator
│   ├── install_r_packages.R          # R package installer
│   ├── install_samr_alternative.sh   # Alternative samr installation
│   └── preprocessing/                # GPR preprocessing module
│       ├── preprocess_gpr.py         # GPR file processor
│       └── sam_input.csv             # Preprocessed data (generated)
│
├── data/                      # Data directory
│   └── examples/                     # Example datasets
│       └── gpr_files/                # Example GPR files
│           ├── experimental_group/   # Experimental samples
│           └── control_group/        # Control samples
│
├── reference/                 # Reference materials
│   └── SAM_original/                 # Original SAM Shiny app
│       ├── server.R, ui.R            # Web interface code
│       ├── sam-manual.pdf            # SAM documentation
│       └── Data examples/            # Additional examples
│
└── results/                   # Analysis output (generated)
    ├── analysis_report_interactive.html
    ├── sam_input_all_results.csv
    ├── sam_input_positive_hits.csv
    ├── sam_input_negative_hits.csv
    └── *.png (plots)
```

## ✨ Features

| Feature | Description |
|---------|-------------|
| **📁 GPR Processing** | Automatic encoding detection (UTF-8, Latin-1, ISO-8859-1), header parsing, quality control |
| **🧬 Data Preprocessing** | k-NN imputation for missing values, log2 transformation, normalization |
| **📈 SAM Analysis** | Permutation-based testing (default: 1000 permutations), FDR calculation, q-value estimation |
| **📊 Visualizations** | **Heatmap**, volcano plot, MA plot, D-value distribution - all interactive with Plotly |
| **🎚️ Real-time Filtering** | **Slider-based filters** that auto-update tables and plots instantly |
| **🔍 Interactive Reports** | Sortable tables, dynamic filtering, CSV export, responsive design |
| **⚙️ Configuration** | YAML-based settings, customizable cutoffs, flexible column mapping |
| **🐍 Multiple Environments** | Conda, virtualenv, or system-wide installation |

## 📋 System Requirements

| Requirement | Minimum | Recommended |
|-------------|---------|-------------|
| **OS** | Linux, macOS, WSL2 | Ubuntu 20.04+, macOS 12+ |
| **Python** | 3.8+ | 3.11+ |
| **R** | 4.0+ | 4.3+ |
| **RAM** | 4 GB | 8 GB+ |
| **Storage** | 500 MB | 1 GB+ |

## 🚀 Quick Start

### One-Command Setup (Recommended)

```bash
git clone https://github.com/HoangSon710/SAM_tools_operation.git
cd SAM_tools_operation
./setup.sh
```

The intelligent setup script will:
1. Detect your system (conda, apt, yum, or brew)
2. Install Python and R dependencies
3. Install build tools if needed (gcc, gfortran)
4. Verify all packages are working
5. Provide installation report

### Run with Example Data

```bash
# Uses included example data (4 experimental + 3 control samples)
python run_pipeline.py
```

### View Results

```bash
# Open the interactive HTML report
open results/analysis_report_interactive.html  # macOS
xdg-open results/analysis_report_interactive.html  # Linux
```

## 📦 Installation Options

<details>
<summary><b>Option A: Automated Setup Script (Easiest)</b></summary>

The setup script intelligently detects your environment and uses the best installation method.

```bash
git clone https://github.com/HoangSon710/SAM_tools_operation.git
cd SAM_tools_operation
chmod +x setup.sh
./setup.sh
```

**What it does:**
- ✅ Detects package managers (conda/apt/yum/brew)
- ✅ Installs r-samr via conda if available (fastest method)
- ✅ Falls back to CRAN installation with multiple mirrors
- ✅ Installs build dependencies (gcc, gfortran) automatically
- ✅ Verifies R packages load correctly
- ✅ Color-coded output for easy troubleshooting

**Time:** 2-5 minutes depending on your system

</details>

<details>
<summary><b>Option B: Conda Environment (Recommended for Research)</b></summary>

Conda provides complete environment isolation and dependency management.

**Quick Setup:**
```bash
git clone https://github.com/HoangSon710/SAM_tools_operation.git
cd SAM_tools_operation
conda env create -f environment.yml
conda activate sam_proteomics
```

**Manual Setup:**
```bash
# Create environment with all dependencies
conda create -n sam_proteomics \
  python=3.11 r-base=4.3 r-samr bioconductor-impute \
  -c conda-forge -c bioconda -y

# Activate environment
conda activate sam_proteomics

# Install Python packages
pip install -r requirements.txt

# Verify installation
Rscript -e 'library(samr); library(impute); cat("✓ All packages ready!\n")'
```

**Always activate before use:**
```bash
conda activate sam_proteomics
python run_pipeline.py
```

**Time:** 5-10 minutes for initial setup

</details>

<details>
<summary><b>Option C: Manual Installation</b></summary>

For users who prefer manual control or have restricted environments.

**Install Python Dependencies:**
```bash
pip install pandas numpy PyYAML
# Or use requirements.txt
pip install -r requirements.txt
```

**Install R Packages:**
```bash
# Automated installation with fallback methods
Rscript install_r_packages.R
```

**Manual R Package Installation:**
```R
# Start R console
R

# Install samr (tries multiple methods)
install.packages("samr")

# If that fails, try BiocManager
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("samr")
BiocManager::install("impute")

# Verify
library(samr)
library(impute)
```

**Alternative samr Installation Script:**
```bash
# Tries 5 different installation methods
chmod +x install_samr_alternative.sh
./install_samr_alternative.sh
```

**Time:** 10-15 minutes

</details>

## 📁 Data Preparation

### Input Data Formats

This pipeline supports **two input formats**:

#### 1. GPR Files (GenePix Results)
Raw proteomics data from GenePix microarray scanner

#### 2. Preprocessed CSV Files
Already processed data in SAM-compatible format

---

### Step 1: GPR File Input (Recommended)

#### Directory Structure

Organize your GPR files into experimental and control groups:

```
data/
└── examples/
    └── gpr_files/
        ├── experimental_group/
        │   ├── sample_exp_1.gpr
        │   ├── sample_exp_2.gpr
        │   ├── sample_exp_3.gpr
        │   └── sample_exp_4.gpr
        └── control_group/
            ├── sample_ctrl_1.gpr
            ├── sample_ctrl_2.gpr
            └── sample_ctrl_3.gpr
```

#### GPR File Format Requirements

**Header Structure:**
- **First 31 rows:** Header information (automatically skipped by pipeline)
- **Row 32:** Column headers with signal intensity names
- **Remaining rows:** Data with protein IDs and signal values

**Required Columns (auto-detected):**
- **ID** or **Row**: Protein/gene identifier
- **Signal columns:** One of the following patterns:
  - `F650 Median - B650` (most common)
  - `F550 Median - B550` (most common)
  - `F635 Mean`, `F532 Mean`
  - `F635 Median`, `F532 Median`

**File Properties:**
- **Encoding:** UTF-8, Latin-1, ISO-8859-1, or CP1252 (auto-detected)
- **Format:** Tab-delimited or comma-delimited
- **Extension:** `.gpr`

**Automatic Preprocessing Features:**
- ✅ Skips first 31 header rows automatically
- ✅ Detects and uses appropriate signal columns
- ✅ Removes control/calibration spots (blanks, BSA, lectins, etc.)
- ✅ Averages technical replicates for each protein
- ✅ Handles missing values with k-NN imputation
- ✅ Combines multiple files from each group

**Control Spots Automatically Removed:**
- Cy3/Cy5 mixtures
- Blank spots
- Poly-L-lysine
- BSA (Bovine Serum Albumin)
- Lectin
- Protein A/G
- Streptavidin
- Buffer controls
- Various calibration controls

#### Create Data Folders

```bash
# Create directory structure
mkdir -p data/my_experiment/experimental data/my_experiment/control

# Copy your GPR files
cp /path/to/experimental/*.gpr data/my_experiment/experimental/
cp /path/to/control/*.gpr data/my_experiment/control/
```

#### Update Configuration

Edit `config.yaml` to point to your GPR folders:

```yaml
input:
  experimental_folder: "data/my_experiment/experimental"
  control_folder: "data/my_experiment/control"

preprocessing:
  skip_rows: 31                    # GPR header rows to skip
  signal_column_exp: "F650 Median - B650"  # Adjust based on your files
  signal_column_ctrl: "F650 Median - B650"
```

---

### Step 2: CSV File Input (Pre-processed Data)

If you have already preprocessed data or want to provide data directly in SAM format:

#### CSV Format Requirements

**Structure:**
```
| Column 1 | Column 2 | Sample1 | Sample2 | Sample3 | Sample4 |
|----------|----------|---------|---------|---------|---------|
| (blank)  | (blank)  | 1       | 1       | 2       | 2       |
| ID1      | Name1    | 1234.5  | 1189.2  | 890.2   | 912.4   |
| ID2      | Name2    | 2345.6  | 2398.1  | 1678.3  | 1702.9  |
```

**Column Requirements:**
- **Row 1:** Group labels (1 = experimental, 2 = control)
- **Column 1:** Protein/Gene IDs
- **Column 2:** Protein/Gene names (can match Column 1)
- **Column 3+:** Expression values (numerical, one column per sample)

**Guidelines:**
- Values should be already **log-transformed** or ready for log2 transformation
- Missing values will be imputed using k-NN algorithm
- Minimum 3 samples per group recommended (4-5 preferred)

**Example CSV:**
```csv
,,1,1,1,2,2,2
ProteinA,ProteinA,1234.5,1189.2,1256.8,890.2,912.4,875.1
ProteinB,ProteinB,2345.6,2398.1,2312.4,1678.3,1702.9,1689.5
ProteinC,ProteinC,567.8,589.3,575.2,1234.5,1198.7,1245.3
```

#### Using CSV Input

```bash
# Place your CSV file in the preprocessing directory
cp my_data.csv scripts/preprocessing/sam_input.csv

# Run with preprocessing skipped (uses existing CSV)
python run_pipeline.py --skip-preprocessing
```

---

### Example Data Included

The repository includes example GPR data for testing:

```
data/examples/gpr_files/
├── experimental_group/  # 4 samples
└── control_group/       # 3 samples
```

Run with example data:
```bash
python run_pipeline.py  # Uses config.yaml which points to data/examples/gpr_files/
```

## ⚙️ Configuration

Edit `config.yaml` to customize your analysis parameters:

```yaml
input:
  experimental_folder: "data/examples/gpr_files/experimental_group"  # Your experimental samples
  control_folder: "data/examples/gpr_files/control_group"            # Your control samples

output:
  results_folder: "results"  # Where to save results
  add_timestamp: false             # Add timestamp to folder name (true/false)

analysis:
  log2fc_cutoff: 1.0      # Fold-change threshold (2-fold = 1.0 in log2)
  d_value_cutoff: 2.0     # SAM score threshold (effect size)
  p_value_cutoff: 0.05    # Statistical significance level

preprocessing:
  skip_rows: 31                    # Number of header rows in GPR files
  signal_column_exp: "F635 Mean"   # Experimental signal column name
  signal_column_ctrl: "F532 Mean"  # Control signal column name
```

### Understanding Parameters

<details>
<summary><b>Log2FC Cutoff (Fold Change)</b></summary>

Controls which fold-change differences are considered significant.

| Log2FC | Actual Fold Change | Interpretation |
|--------|-------------------|----------------|
| 0.58   | 1.5-fold          | Subtle changes (sensitive) |
| 1.0    | 2-fold            | **Standard cutoff** |
| 1.5    | 3-fold            | Moderate changes |
| 2.0    | 4-fold            | Large changes (stringent) |

**Formula:** `Fold Change = 2^(Log2FC)`

**Recommendation:** Start with 1.0 (2-fold) for most proteomics experiments.

</details>

<details>
<summary><b>D-Value Cutoff (SAM Score)</b></summary>

SAM score represents the effect size after accounting for variability.

| D-Value | Effect Size | Use Case |
|---------|-------------|----------|
| 1.0     | Medium      | Exploratory analysis |
| 2.0     | **Large**   | **Standard for SAM** |
| 3.0     | Very Large  | High-confidence hits only |

**Higher values = more stringent = fewer false positives**

**Recommendation:** Use 2.0 for balanced sensitivity and specificity.

</details>

<details>
<summary><b>P-Value Cutoff</b></summary>

Statistical significance threshold (before multiple testing correction).

| P-Value | Stringency | Use Case |
|---------|------------|----------|
| 0.05    | Standard   | **Most common** |
| 0.01    | Stringent  | High-confidence findings |
| 0.10    | Relaxed    | Exploratory analysis |

**Note:** SAM also provides q-values (FDR-adjusted) which are reported in results.

</details>

## 🏃 Running the Analysis

### Basic Usage

```bash
# Run complete pipeline
python run_pipeline.py
```

**Pipeline steps:**
1. ✅ Loads configuration from `config.yaml`
2. ✅ Preprocesses GPR files (encoding detection, parsing, imputation)
3. ✅ Performs SAM statistical analysis
4. ✅ Generates 4 visualization plots (PNG format)
5. ✅ Creates interactive HTML report
6. ✅ Exports CSV files (all results, positive hits, negative hits)

### Command-Line Options

```bash
# Use custom configuration file
python run_pipeline.py --config my_config.yaml

# Skip preprocessing (use existing preprocessed data)
python run_pipeline.py --skip-preprocessing

# Skip analysis (preprocessing only)
python run_pipeline.py --skip-analysis

# Combine options
python run_pipeline.py --config custom.yaml --skip-preprocessing
```

### Expected Runtime

| Dataset Size | Preprocessing | SAM Analysis | Total Time |
|-------------|---------------|--------------|------------|
| Small (1000 genes, 3+3 samples) | 10-30 sec | 1-2 min | **~2 min** |
| Medium (5000 genes, 5+5 samples) | 30-60 sec | 3-5 min | **~5 min** |
| Large (10000 genes, 10+10 samples) | 1-2 min | 10-15 min | **~15 min** |

**Note:** SAM uses 1000 permutations by default, which can be time-consuming for large datasets.

## 📊 Understanding Results

### Output Directory Structure

After running the pipeline, your results folder contains:

```
results/
├── analysis_report_interactive.html    # 📄 Main interactive report
├── sam_input.csv                      # 📊 Preprocessed data matrix
├── sam_input_all_results.csv          # 📋 Complete analysis results
├── sam_input_positive_hits.csv        # ⬆️  Upregulated proteins
├── sam_input_negative_hits.csv        # ⬇️  Downregulated proteins
├── volcano_plot.png                   # 🌋 Volcano plot
├── sam_plot.png                       # 📈 SAM score plot
├── foldchange_distribution.png        # 📊 FC histogram
├── top_genes_barplot.png              # 🏆 Top 20 genes
└── sam_results.RData                  # 💾 R workspace (for advanced users)
```

### Interactive HTML Report

Open `analysis_report_interactive.html` in any web browser for:

#### 1. Summary Statistics Dashboard
- Total genes analyzed
- Positive hits (upregulated)
- Negative hits (downregulated)
- Not significant genes

#### 2. Interactive Visualizations

**🔥 Heatmap (NEW!):**
- Top 50 most significant genes by D-value
- Color-coded expression levels (blue → yellow → red)
- Sample groups labeled (Experimental vs Control)
- Interactive hover shows gene, sample, and expression value
- **Auto-updates with filter changes**

**🌋 Volcano Plot:**
- X-axis: Log2 Fold Change
- Y-axis: -log10(P-value)
- Green points: Upregulated (significant)
- Red points: Downregulated (significant)
- Gray points: Not significant
- **Interactive hover with gene details**

**📈 MA Plot:**
- X-axis: Mean Expression (log2 scale)
- Y-axis: Log2 Fold Change
- Identifies expression-dependent bias
- Same color coding as volcano plot
- **Responsive to filters**

**📊 D-value Distribution:**
- Histogram of SAM D-values (effect sizes)
- Shows statistical significance distribution
- Updates dynamically with filtering

All plots are fully interactive using Plotly - zoom, pan, and hover for details!

#### 3. Real-Time Slider Filtering (NEW!)

**Auto-Update Feature** - No "Apply" button needed! Just drag and watch results update instantly.

**Three Interactive Sliders:**

1. **Min |Log2 FC|** (Range: 0.0 - 5.0)
   - Filters by minimum absolute fold change
   - Live value display next to slider
   - Example: Set to 1.0 for 2-fold change minimum
   
2. **Min |D-value|** (Range: 0.0 - 10.0)
   - Filters by minimum SAM effect size
   - Live value display next to slider
   - Example: Set to 2.0 for standard cutoff
   
3. **Max P-value** (Range: 0.0 - 1.0)
   - Filters by maximum statistical significance
   - Live value display next to slider
   - Example: Set to 0.05 for 5% significance

**Live Statistics:**
- Instant count of filtered genes
- Color-coded positive (▲) and negative (▼) hits
- No page reload required

**Benefits:**
- ✅ Explore different cutoffs without rerunning analysis
- ✅ See impact of filters immediately
- ✅ All plots and tables update together
- ✅ One-click reset to original view

#### 4. Sortable & Searchable Tables

**All Results Table:**
- Sort by any column (click header)
- Search for specific genes (search box)
- Pagination (25/50/100 entries per page)

**Positive/Negative Hits Tables:**
- Pre-filtered by significance
- Export buttons (CSV, Excel, PDF)

### CSV File Columns

| Column | Description | Example | Range |
|--------|-------------|---------|-------|
| `GeneID` | Gene identifier | `ENSG00000139618` | - |
| `GeneName` | Gene symbol | `BRCA2` | - |
| `Mean_Exp` | Mean expression (experimental) | `1234.56` | 0 - ∞ |
| `Mean_Ctrl` | Mean expression (control) | `567.89` | 0 - ∞ |
| `FoldChange` | Fold change (not log) | `2.17` | 0 - ∞ |
| `Log2FC` | Log2 fold change | `1.12` | -∞ to +∞ |
| `SAM_score` | SAM test statistic | `3.45` | -∞ to +∞ |
| `Q_value` | False discovery rate (%) | `2.3` | 0 - 100 |
| `P_value` | Nominal p-value | `0.0023` | 0 - 1 |
| `Significance` | Classification | `Positive` | Positive/Negative/Not Significant |

### Interpreting Results

<details>
<summary><b>SAM Score (D-value)</b></summary>

**Definition:** Test statistic that measures effect size relative to variability.

**Interpretation:**
- **Positive SAM score:** Gene is upregulated in experimental vs. control
- **Negative SAM score:** Gene is downregulated in experimental vs. control
- **Magnitude:** Larger absolute value = stronger signal

**Thresholds:**
- |D| > 2.0: Standard SAM cutoff
- |D| > 3.0: High confidence
- |D| > 5.0: Very high confidence

</details>

<details>
<summary><b>Q-value (FDR)</b></summary>

**Definition:** Estimated percentage of false discoveries among genes called significant.

**Interpretation:**
- **Q = 1%:** If you call 100 genes significant, expect ~1 false positive
- **Q = 5%:** If you call 100 genes significant, expect ~5 false positives
- **Q = 10%:** If you call 100 genes significant, expect ~10 false positives

**Recommendation:**
- Q < 5%: High confidence (recommended for validation)
- Q < 10%: Moderate confidence (acceptable for exploratory)
- Q < 20%: Low confidence (requires additional validation)

</details>

<details>
<summary><b>Example Interpretation</b></summary>

**Gene: PROTEIN_123**
- SAM_score: 4.5
- Log2FC: 2.3
- Q_value: 1.2%
- P_value: 0.0001

**Conclusion:**
> This protein is **significantly upregulated** in the experimental group. It shows a **4.9-fold increase** (2^2.3) with very **high statistical confidence** (SAM score = 4.5, q-value = 1.2%). This is a **strong candidate** for biological validation.

</details>

### Quality Control Checks

Before trusting results, verify:

1. **Sample Size:** Minimum 3 replicates per group (prefer 4-5)
2. **Data Distribution:** Check fold-change histogram for symmetry
3. **SAM Plot:** Should show clear separation between significant and non-significant
4. **Q-values:** Should show gradual increase (not all 0% or all 100%)
5. **Volcano Plot:** Should have balanced upregulation and downregulation (unless biological effect is one-sided)

## 🔧 Troubleshooting

<details>
<summary><b>Installation Issues</b></summary>

### R Package Installation Fails

**Error:** `package 'samr' is not available`

**Solution 1: Use conda (recommended)**
```bash
conda install -c bioconda r-samr
```

**Solution 2: Try alternative installation script**
```bash
chmod +x install_samr_alternative.sh
./install_samr_alternative.sh
```

**Solution 3: Install build dependencies first**
```bash
# Ubuntu/Debian
sudo apt-get update
sudo apt-get install build-essential gfortran r-base-dev

# macOS
xcode-select --install
brew install gcc gfortran

# Then retry
Rscript install_r_packages.R
```

### Python Package Installation Fails

```bash
# Upgrade pip first
pip install --upgrade pip

# Install to user directory
pip install --user -r requirements.txt
```

</details>

<details>
<summary><b>Runtime Errors</b></summary>

### Missing Column Errors

**Error:** `KeyError: 'F635 Mean'`

**Solution:** Check your GPR files for correct column names:
```bash
# View column headers in your GPR file
head -35 your_file.gpr | tail -5

# Update config.yaml with actual column names
```

### No Significant Genes Found

**Possible causes:**
1. Cutoffs too stringent
2. No biological difference
3. High variability
4. Wrong groups

**Solution:** Try more relaxed parameters:
```yaml
analysis:
  log2fc_cutoff: 0.58    # 1.5-fold instead of 2-fold
  d_value_cutoff: 1.0    # Lower threshold
```

</details>

<details>
<summary><b>Getting Help</b></summary>

### Where to Get Help

1. **GitHub Issues:** [Report bugs or ask questions](https://github.com/HoangSon710/SAM_tools_operation/issues)
2. **SAM Documentation:** [CRAN samr package](https://cran.r-project.org/web/packages/samr/index.html)

### Providing Useful Information

When reporting issues, include:
- Operating system and version
- Python version (`python --version`)
- R version (`R --version`)
- Error message (full traceback)
- Configuration file (config.yaml)

</details>

## 📖 Example Workflows

### Workflow 1: Quick Start with Example Data

```bash
# Clone and setup
git clone https://github.com/HoangSon710/SAM_tools_operation.git
cd SAM_tools_operation
./setup.sh

# Run with example data
python run_pipeline.py

# View results
xdg-open results/analysis_report_interactive.html
```

**Expected output:**
- 6 significant genes (4 positive, 2 negative)
- Runtime: ~2 minutes
- 4 PNG plots + HTML report

### Workflow 2: Custom Data with Conda

```bash
# 1. Setup environment
git clone https://github.com/HoangSon710/SAM_tools_operation.git
cd SAM_tools_operation
conda env create -f environment.yml
conda activate sam_proteomics

# 2. Prepare your data
mkdir -p data/my_experiment/experimental data/my_experiment/control
cp /path/to/experimental/*.gpr data/my_experiment/experimental/
cp /path/to/control/*.gpr data/my_experiment/control/

# 3. Configure analysis
nano config.yaml
# Update paths and cutoffs

# 4. Run pipeline
python run_pipeline.py

# 5. Review results
open results/analysis_report_interactive.html
```

## 📚 Advanced Usage

### Customizing SAM Parameters

Edit `sam_pipeline_ttest.R` for advanced control:

```R
# Line ~180: Adjust number of permutations
samr.obj <- samr(data = samr.data, resp.type = "Two class unpaired", nperms = 1000)
# Increase for more accurate FDR: nperms = 5000 or 10000

# Line ~190: Set delta manually
siggenes.table <- samr.compute.siggenes.table(samr.obj, del = 0.5, data = samr.data, delta.table)
# Lower delta = more genes, higher delta = fewer genes
```

### Preprocessing Only

```bash
# Run preprocessing without analysis
python run_pipeline.py --skip-analysis

# Result: Creates sam_input.csv only
# Use this preprocessed file in R or other tools
```

## 🎓 Citation

If you use this pipeline in your research, please cite:

**SAM Algorithm:**
> Tusher VG, Tibshirani R, Chu G. (2001) *Significance analysis of microarrays applied to the ionizing radiation response.* **PNAS** 98(9):5116-5121. DOI: [10.1073/pnas.091062498](https://doi.org/10.1073/pnas.091062498)

**BibTeX:**
```bibtex
@article{tusher2001sam,
  title={Significance analysis of microarrays applied to the ionizing radiation response},
  author={Tusher, Virginia Goss and Tibshirani, Robert and Chu, Gilbert},
  journal={Proceedings of the National Academy of Sciences},
  volume={98},
  number={9},
  pages={5116--5121},
  year={2001},
  publisher={National Acad Sciences},
  doi={10.1073/pnas.091062498}
}
```

## 🤝 Contributing

Contributions are welcome! To contribute:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

**Areas for contribution:**
- Additional imputation methods
- More visualization options
- Docker containerization
- Unit tests
- Documentation improvements

## 📧 Support & Contact

- **Issues:** [GitHub Issues](https://github.com/HoangSon710/SAM_tools_operation/issues)
- **Discussions:** [GitHub Discussions](https://github.com/HoangSon710/SAM_tools_operation/discussions)
- **Email:** Open an issue for fastest response

## 📄 License

This project is available for research and educational use. See included example data for testing.

**Dependencies:**
- `samr` R package: GPL-2 License
- `impute` Bioconductor package: GPL License
- Python packages: See requirements.txt for individual licenses

## 🙏 Acknowledgments

- SAM algorithm developers: Virginia Goss Tusher, Robert Tibshirani, and Gilbert Chu
- R `samr` package maintainers
- Bioconductor project for `impute` package
- All contributors to this pipeline

---

**Version:** 1.0.0  
**Last Updated:** January 2, 2026  
**Maintained by:** HoangSon710

For the latest updates, visit: [https://github.com/HoangSon710/SAM_tools_operation](https://github.com/HoangSon710/SAM_tools_operation)
