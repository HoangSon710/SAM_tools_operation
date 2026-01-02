# SAM Proteomics Analysis Pipeline

Automated pipeline for proteomics differential expression analysis from GenePix Results (GPR) files using **SAM (Significance Analysis of Microarrays)** algorithm with interactive visualization and customizable parameters.

## ✨ Features

- 🔬 **GPR File Processing**: Automatic preprocessing with encoding detection and k-NN imputation
- 📊 **SAM Analysis**: Permutation-based statistical testing with FDR control
- 🎨 **Interactive Visualizations**: Volcano plot, MA plot, and SAM score distribution
- 🔍 **Dynamic Filtering**: Real-time filtering by fold change and q-values
- 📈 **HTML Reports**: Interactive tables with sorting, searching, and export
- ⚙️ **Configurable**: Easy setup via YAML configuration file

## 📋 Prerequisites

- **Operating System**: Linux or macOS
- **Python**: 3.8 or higher
- **R**: 4.0 or higher
- **Git**: For cloning the repository

## 🚀 Installation & Setup

### Option A: Conda Environment (Recommended)

Using conda provides isolated environment management:

**Quick setup with environment.yml:**
```bash
# Clone repository
git clone https://github.com/HoangSon710/SAM_tools_operation.git
cd SAM_tools_operation

# Create conda environment from file
conda env create -f environment.yml
conda activate sam_proteomics

# Install R packages
Rscript install_r_packages.R

# Make scripts executable
chmod +x run_pipeline.py setup.sh
```

**Or manual conda setup:**
```bash
# Clone repository
git clone https://github.com/HoangSon710/SAM_tools_operation.git
cd SAM_tools_operation

# Create conda environment
conda create -n sam_proteomics python=3.11 r-base=4.3 -y
conda activate sam_proteomics

# Install Python packages
pip install -r requirements.txt

# Install R packages
Rscript install_r_packages.R

# Make scripts executable
chmod +x run_pipeline.py setup.sh
```

**Activate environment before each use:**
```bash
conda activate sam_proteomics
python run_pipeline.py
```

### Option B: Automated Setup Script

The setup script will install all required dependencies:

```bash
# Clone repository
git clone https://github.com/HoangSon710/SAM_tools_operation.git
cd SAM_tools_operation

# Run setup
chmod +x setup.sh
./setup.sh
```

**What the setup script does:**
- ✅ Checks for Python 3.8+ and R 4.0+
- ✅ Installs Python packages: `pandas`, `numpy`, `PyYAML`
- ✅ Installs R packages: `samr`, `impute` (Bioconductor)
- ✅ Makes all scripts executable
- ✅ Verifies installation

### Option C: Manual Setup

If automated setup fails, install dependencies manually:

**Install Python packages:**
```bash
pip install -r requirements.txt
```

**Install R packages:**
```bash
Rscript install_r_packages.R
```

**Make scripts executable:**
```bash
chmod +x run_pipeline.py setup.sh
```

## 📁 Data Preparation

### Organize Your GPR Files

Create two folders for your experimental and control samples:

```bash
mkdir -p my_data/experimental
mkdir -p my_data/control
```

Place your GPR files:
```
my_data/
├── experimental/
│   ├── sample1.gpr
│   ├── sample2.gpr
│   └── sample3.gpr
└── control/
    ├── control1.gpr
    ├── control2.gpr
    └── control3.gpr
```

## ⚙️ Configuration

Edit `config.yaml` to customize your analysis:

```yaml
input:
  experimental_folder: "my_data/experimental"  # Path to experimental GPR files
  control_folder: "my_data/control"            # Path to control GPR files

output:
  results_folder: "results"                     # Output directory
  add_timestamp: true                           # Add timestamp to results

analysis:
  log2fc_cutoff: 1.0      # 2-fold change (2^1.0 = 2)
  d_value_cutoff: 2.0     # Effect size threshold
  p_value_cutoff: 0.05    # Statistical significance

preprocessing:
  skip_rows: 31                    # Header rows in GPR files
  signal_column_exp: "F635 Mean"   # Experimental signal column
  signal_column_ctrl: "F532 Mean"  # Control signal column
```

**Common cutoff values:**
- **Log2FC = 1.0**: 2-fold change (standard)
- **Log2FC = 1.5**: 3-fold change (more stringent)
- **Log2FC = 0.58**: 1.5-fold change (less stringent)
- **D-value ≥ 2.0**: Large effect size
- **D-value ≥ 1.0**: Medium effect size

## 🏃 Running the Pipeline

### Basic Usage

```bash
python run_pipeline.py
```

This will:
1. Preprocess GPR files from both experimental and control folders
2. Perform T-test analysis
3. Generate interactive HTML report
4. Create CSV files with results

### Advanced Options

```bash
# Skip preprocessing (if already done)
python run_pipeline.py --skip-preprocessing

# Skip analysis (preprocessing only)
python run_pipeline.py --skip-analysis

# Use custom configuration file
python run_pipeline.py --config my_config.yaml
```

### Test with Example Data

The repository includes example data (4 experimental + 3 control samples):

```bash
python run_pipeline.py
# Results will be in: results/ or ttest_results/
```

## 📊 Understanding the Results

### Output Files

After running the pipeline, you'll find:

```
results/
├── analysis_report_interactive.html    # Main interactive report
├── sam_input.csv                      # Preprocessed data
├── sam_input_all_results.csv           # All genes with statistics
├── sam_input_positive_hits.csv         # Upregulated genes
└── sam_input_negative_hits.csv         # Downregulated genes
```

### Interactive HTML Report

Open `analysis_report_interactive.html` in your browser to:

1. **View Summary Statistics**: Total genes, positive/negative hits
2. **Filter Results**: Adjust Log2FC, D-value, and P-value thresholds dynamically
3. **Explore Visualizations**:
   - **Volcano Plot**: Log2FC vs -log10(P-value)
   - **MA Plot**: Mean expression vs Log2FC
   - **D-value Distribution**: Effect size histogram
4. **Browse Tables**: Sortable, searchable data tables
5. **Download Data**: Export filtered results as CSV

### CSV Columns

Each CSV file contains:
- `GeneID`: Gene identifier
- `GeneName`: Gene name
- `Mean_Exp`: Mean expression (experimental group)
- `Mean_Ctrl`: Mean expression (control group)
- `FoldChange`: Fold change (not log-transformed)
- `Log2FC`: Log2 fold change
- `SAM_score`: SAM test statistic
- `Q_value`: False Discovery Rate (q-value, %)
- `Significance`: Classification (Positive/Negative/Not Significant)

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
