# SAM Proteomics Analysis Pipeline

A comprehensive, production-ready pipeline for proteomics differential expression analysis using the **Significance Analysis of Microarrays (SAM)** algorithm. Process GenePix Results (GPR) files with automated preprocessing, statistical testing, and publication-quality visualizations.

[![R](https://img.shields.io/badge/R-4.3+-blue.svg)](https://www.r-project.org/)
[![Python](https://img.shields.io/badge/Python-3.11+-green.svg)](https://www.python.org/)
[![License](https://img.shields.io/badge/license-MIT-orange.svg)](LICENSE)

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

## ✨ Features

| Feature | Description |
|---------|-------------|
| **📁 GPR Processing** | Automatic encoding detection (UTF-8, Latin-1, ISO-8859-1), header parsing, quality control |
| **🧬 Data Preprocessing** | k-NN imputation for missing values, log2 transformation, normalization |
| **📈 SAM Analysis** | Permutation-based testing (default: 1000 permutations), FDR calculation, q-value estimation |
| **📊 Visualizations** | Volcano plot, SAM plot, fold-change distribution, top significant genes barplot |
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
open ttest_results/analysis_report_interactive.html  # macOS
xdg-open ttest_results/analysis_report_interactive.html  # Linux
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

<details>
<summary><b>Option D: Docker (Coming Soon)</b></summary>

Pre-built Docker image with all dependencies.

```bash
# Pull image
docker pull hoangson710/sam-proteomics:latest

# Run analysis
docker run -v $(pwd)/data:/data hoangson710/sam-proteomics
```

</details>

## 📁 Data Preparation

### Directory Structure

Organize your GPR files into experimental and control groups:

```
your_project/
├── experimental/
│   ├── sample_exp_1.gpr
│   ├── sample_exp_2.gpr
│   ├── sample_exp_3.gpr
│   └── sample_exp_4.gpr
└── control/
    ├── sample_ctrl_1.gpr
    ├── sample_ctrl_2.gpr
    └── sample_ctrl_3.gpr
```

### Create Data Folders

```bash
# Create directory structure
mkdir -p my_experiment/experimental my_experiment/control

# Copy your GPR files
cp /path/to/experimental/*.gpr my_experiment/experimental/
cp /path/to/control/*.gpr my_experiment/control/
```

### GPR File Requirements

- **Format:** GenePix Results (GPR) files
- **Encoding:** UTF-8, Latin-1, ISO-8859-1, or CP1252 (auto-detected)
- **Structure:** Standard GPR format with header rows
- **Columns:** Must contain signal intensity columns (e.g., "F635 Mean", "F532 Mean")

**Supported GPR column names:**
- `F635 Mean`, `F532 Mean` (default)
- `F635 Median`, `F532 Median`
- Custom columns (specify in config.yaml)

### Example Data

The repository includes example data for testing:

```
example_GPR/
├── experimental_group/  # 4 samples
└── control_group/       # 3 samples
```

Run with example data:
```bash
python run_pipeline.py  # Uses config.yaml which points to example_GPR/
```

## ⚙️ Configuration

Edit `config.yaml` to customize your analysis parameters:

```yaml
input:
  experimental_folder: "example_GPR/experimental_group"  # Your experimental samples
  control_folder: "example_GPR/control_group"            # Your control samples

output:
  results_folder: "ttest_results"  # Where to save results
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

<details>
<summary><b>Signal Column Names</b></summary>

Specify the exact column names in your GPR files:

```yaml
preprocessing:
  signal_column_exp: "F635 Mean"   # Cy5 channel (red)
  signal_column_ctrl: "F532 Mean"  # Cy3 channel (green)
```

**Common alternatives:**
- `F635 Median` / `F532 Median` (median instead of mean)
- `F635 Mean - B635` / `F532 Mean - B532` (background-subtracted)

**How to find:** Open a GPR file in a text editor and look at the column headers (usually around row 31-32).

</details>

### Configuration Examples

<details>
<summary><b>Stringent Analysis (High Confidence)</b></summary>

```yaml
analysis:
  log2fc_cutoff: 1.5      # 3-fold change
  d_value_cutoff: 3.0     # Very large effect size
  p_value_cutoff: 0.01    # 1% significance
```

**Result:** Fewer hits, very high confidence

</details>

<details>
<summary><b>Sensitive Analysis (Exploratory)</b></summary>

```yaml
analysis:
  log2fc_cutoff: 0.58     # 1.5-fold change
  d_value_cutoff: 1.0     # Medium effect size
  p_value_cutoff: 0.10    # 10% significance
```

**Result:** More hits, some may be false positives

</details>

<details>
<summary><b>Custom Data Location</b></summary>

```yaml
input:
  experimental_folder: "/data/project_2024/treatment_samples"
  control_folder: "/data/project_2024/control_samples"

output:
  results_folder: "results_2024_01_02"
  add_timestamp: true  # Creates results_2024_01_02_20240102_143022/
```

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

### Alternative Shell Scripts

```bash
# Run SAM pipeline (same as python run_pipeline.py)
./run_pipeline.sh

# Run T-test pipeline (legacy compatibility)
./run_ttest_pipeline.sh
```

### Expected Runtime

| Dataset Size | Preprocessing | SAM Analysis | Total Time |
|-------------|---------------|--------------|------------|
| Small (1000 genes, 3+3 samples) | 10-30 sec | 1-2 min | **~2 min** |
| Medium (5000 genes, 5+5 samples) | 30-60 sec | 3-5 min | **~5 min** |
| Large (10000 genes, 10+10 samples) | 1-2 min | 10-15 min | **~15 min** |

**Note:** SAM uses 1000 permutations by default, which can be time-consuming for large datasets.

### Monitoring Progress

The pipeline provides real-time progress updates:

```
[INFO] Starting SAM Proteomics Analysis Pipeline
[INFO] Loading configuration from: config.yaml
[INFO] Experimental folder: example_GPR/experimental_group
[INFO] Control folder: example_GPR/control_group
[INFO] Output folder: ttest_results

[INFO] Preprocessing experimental samples...
[PROGRESS] Processing 1/4: sample1.gpr
[PROGRESS] Processing 2/4: sample2.gpr
...

[INFO] Running SAM analysis...
[PROGRESS] Performing permutations (1000 iterations)...
[SUCCESS] SAM analysis complete

[INFO] Generating plots...
[SUCCESS] Volcano plot saved: ttest_results/volcano_plot.png
[SUCCESS] SAM plot saved: ttest_results/sam_plot.png
...

[SUCCESS] Pipeline completed successfully!
[SUCCESS] Results saved to: ttest_results/
```

## 📊 Understanding Results

### Output Directory Structure

After running the pipeline, your results folder contains:

```
ttest_results/
├── analysis_report_interactive.html    # 📄 Main interactive report
├── sam_input.csv                      # 📊 Preprocessed data matrix
├── sam_input_all_results.csv          # 📋 Complete analysis results
├── sam_input_positive_hits.csv        # ⬆️  Upregulated proteins
├── sam_input_negative_hits.csv        # ⬇️  Downregulated proteins
├── volcano_plot.png                   # 🌋 Volcano plot (54KB)
├── sam_plot.png                       # 📈 SAM score plot (41KB)
├── foldchange_distribution.png        # 📊 FC histogram (25KB)
├── top_genes_barplot.png              # 🏆 Top 20 genes (19KB)
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

**Volcano Plot:**
- X-axis: Log2 Fold Change
- Y-axis: -log10(P-value)
- Red points: Upregulated (Log2FC > cutoff)
- Blue points: Downregulated (Log2FC < -cutoff)
- Gray points: Not significant

**SAM Plot:**
- X-axis: Expected SAM score
- Y-axis: Observed SAM score
- Points above diagonal: Upregulated
- Points below diagonal: Downregulated
- Parallel lines: Significance threshold (Δ)

**Fold Change Distribution:**
- Histogram of all log2 fold changes
- Shows distribution shape (symmetry, outliers)
- Helps identify batch effects or bias

**Top Significant Genes:**
- Barplot of top 20 genes by |SAM score|
- Color-coded by direction (red = up, blue = down)
- Easy identification of strongest candidates

#### 3. Dynamic Filtering

Adjust thresholds in real-time without rerunning analysis:

```
Log2FC: [slider] 0.0 to 5.0
D-value: [slider] 0.0 to 10.0
P-value: [slider] 0.0 to 1.0
```

Tables update instantly to show genes meeting your criteria.

#### 4. Sortable & Searchable Tables

**All Results Table:**
- Sort by any column (click header)
- Search for specific genes (search box)
- Pagination (25/50/100 entries per page)

**Positive/Negative Hits Tables:**
- Pre-filtered by significance
- Export buttons (CSV, Excel, PDF)

### CSV File Columns

Each CSV file contains the following columns:

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
<summary><b>Fold Change vs Log2FC</b></summary>

**Fold Change (FC):**
- FC = 2.0 means 2x higher in experimental
- FC = 0.5 means 2x lower in experimental (50% of control)
- Always positive

**Log2 Fold Change:**
- Log2FC = 1.0 means 2x higher (2^1 = 2)
- Log2FC = -1.0 means 2x lower (2^-1 = 0.5)
- Can be negative (downregulation) or positive (upregulation)

**Conversion:** `FC = 2^(Log2FC)`

</details>

### Example Interpretation

**Gene: PROTEIN_123**
- SAM_score: 4.5
- Log2FC: 2.3
- Q_value: 1.2%
- P_value: 0.0001

**Conclusion:**
> This protein is **significantly upregulated** in the experimental group. It shows a **4.9-fold increase** (2^2.3) with very **high statistical confidence** (SAM score = 4.5, q-value = 1.2%). This is a **strong candidate** for biological validation.

### Quality Control Checks

Before trusting results, verify:

1. **Sample Size:** Minimum 3 replicates per group (prefer 4-5)
2. **Data Distribution:** Check fold-change histogram for symmetry
3. **SAM Plot:** Should show clear separation between significant and non-significant
4. **Q-values:** Should show gradual increase (not all 0% or all 100%)
5. **Volcano Plot:** Should have balanced upregulation and downregulation (unless biological effect is one-sided)

## � Citation

If you use this pipeline, please cite the SAM algorithm:

**Tusher VG, Tibshirani R, Chu G.** *Significance analysis of microarrays applied to the ionizing radiation response.* **PNAS** 2001 98(9):5116-21.

## �🔧 Troubleshooting

### Conda Not Found

```bash
# Install Miniconda
wget https://repo.anaconda.com/miniconda/Miniconda3-latest-Linux-x86_64.sh
bash Miniconda3-latest-Linux-x86_64.sh

# Or install Anaconda from https://www.anaconda.com/download
```

### Conda Environment Issues

```bash
# Remove and recreate environment
conda deactivate
conda env remove -n sam_proteomics
conda env create -f environment.yml

# List all conda environments
conda env list

# Activate environment
conda activate sam_proteomics
```

### Permission Denied

```bash
chmod +x setup.sh run_pipeline.py
```

### Python Not Found or Wrong Version

```bash
# Check Python version
python3 --version

# Ubuntu/Debian
sudo apt-get update
sudo apt-get install python3 python3-pip

# macOS
brew install python@3.11
```

### R Not Found

```bash
# Ubuntu/Debian
sudo apt-get install r-base

# macOS
brew install r
```

### R Package Installation Fails

If Bioconductor or CRAN installation fails:

```bash
R
> install.packages("BiocManager")
> BiocManager::install("impute")
> install.packages("samr")
> quit()
```

Note: The `samr` package is essential for the SAM algorithm.

### Python Package Installation Fails

```bash
# Install to user directory
pip install --user -r requirements.txt

# Or create virtual environment
python3 -m venv venv
source venv/bin/activate
pip install -r requirements.txt
```

### Encoding Errors with GPR Files

The pipeline automatically tries multiple encodings (UTF-8, Latin-1, ISO-8859-1, CP1252). If errors persist, check your GPR file format.

## 📖 Example Workflow

**With Conda (Recommended):**
```bash
# 1. Clone and setup
git clone https://github.com/HoangSon710/SAM_tools_operation.git
cd SAM_tools_operation
conda env create -f environment.yml
conda activate sam_proteomics
Rscript install_r_packages.R

# 2. Prepare your data
mkdir -p my_experiment/experimental my_experiment/control
cp /path/to/experimental/*.gpr my_experiment/experimental/
cp /path/to/control/*.gpr my_experiment/control/

# 3. Configure analysis
nano config.yaml  # Edit paths and cutoffs

# 4. Run pipeline
python run_pipeline.py

# 5. View results
open results/analysis_report_interactive.html
```

**Without Conda:**
```bash
# 1. Clone and setup
git clone https://github.com/HoangSon710/SAM_tools_operation.git
cd SAM_tools_operation
./setup.sh

# 2. Prepare your data
mkdir -p my_experiment/experimental my_experiment/control
cp /path/to/experimental/*.gpr my_experiment/experimental/
cp /path/to/control/*.gpr my_experiment/control/

# 3. Configure analysis
nano config.yaml  # Edit paths and cutoffs

# 4. Run pipeline
python run_pipeline.py

# 5. View results
open results/analysis_report_interactive.html
```

## 🤝 Support

- **Issues**: [GitHub Issues](https://github.com/HoangSon710/SAM_tools_operation/issues)
- **Example Data**: Included in `example_GPR/` folder
- **Configuration**: See `config.yaml` for all options

## � References

- **SAM R Package**: [samr - Significance Analysis of Microarrays](https://cran.r-project.org/web/packages/samr/index.html)
  - Tusher, V.G., Tibshirani, R. and Chu, G. (2001): Significance analysis of microarrays applied to the ionizing radiation response. PNAS 2001 98, 5116-5121.

## �📄 License

This project is provided for research and educational use.
