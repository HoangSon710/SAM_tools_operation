# SAM Proteomics Analysis Pipeline

Complete automated pipeline for analyzing proteomics data from GenePix Results (GPR) files using T-test statistical analysis.

## 🚀 Quick Start (Local Computer Setup)

### 1. Clone Repository

```bash
git clone https://github.com/HoangSon710/SAM_tools_operation.git
cd SAM_tools_operation
```

### 2. Install Dependencies

```bash
# Automated setup (Linux/Mac)
chmod +x setup.sh
./setup.sh

# Or manual setup
pip install -r requirements.txt
Rscript install_r_packages.R
```

### 3. Configure Your Analysis

Edit `config.yaml` to set your input folders and parameters:

```yaml
input:
  experimental_folder: "your_data/experimental"
  control_folder: "your_data/control"

analysis:
  log2fc_cutoff: 1.0    # 2-fold change
  d_value_cutoff: 2.0   # Effect size
```

### 4. Run Pipeline

```bash
python run_pipeline.py
```

## 📊 What You Get

- **Interactive HTML Report**: Sortable, searchable tables
- **CSV Files**: All results, positive hits, negative hits
- **Statistical Analysis**: T-test with effect sizes
- **Visual Summary**: Metrics and classifications

## 📁 Project Structure

```
SAM_tools_operation/
├── config.yaml              # Configuration (EDIT THIS)
├── run_pipeline.py          # Main pipeline script
├── setup.sh                 # Setup installer
├── requirements.txt         # Python packages
├── install_r_packages.R     # R packages
├── preprocessing_gpr/       # GPR preprocessing
│   └── preprocess_gpr.py
├── sam_pipeline_ttest.R     # Statistical analysis
└── results/                 # Output folder
```

## 💻 Using on Your Data

1. **Organize your GPR files:**
   ```
   my_data/
   ├── experimental/
   │   ├── exp1.gpr
   │   ├── exp2.gpr
   │   └── exp3.gpr
   └── control/
       ├── ctrl1.gpr
       ├── ctrl2.gpr
       └── ctrl3.gpr
   ```

2. **Update config.yaml:**
   ```yaml
   input:
     experimental_folder: "my_data/experimental"
     control_folder: "my_data/control"
   ```

3. **Run:**
   ```bash
   python run_pipeline.py
   ```

4. **View results:**
   - Open `results/analysis_report_interactive.html` in browser
   - Download CSV files from `results/` folder

## 🔧 Configuration Options

See `config.yaml` for all options:

- **Input/Output**: Folder paths
- **Analysis**: Cutoff thresholds (Log2FC, D-value, P-value)
- **Preprocessing**: Signal columns, rows to remove
- **Output Format**: HTML, CSV, plots

## 📈 Adjusting Cutoffs

```bash
# More stringent (3-fold change)
./run_ttest_pipeline.sh preprocessing_gpr results 1.5 3.0

# Less stringent (1.5-fold change)
./run_ttest_pipeline.sh preprocessing_gpr results 0.58 1.5
```

## 📦 Requirements

- Python 3.8+
- R 4.0+
- Internet connection (for first-time package installation)

## 🐛 Troubleshooting

### R not found
```bash
# Ubuntu/Debian
sudo apt-get install r-base

# Mac (with Homebrew)
brew install r
```

### Permission denied
```bash
chmod +x setup.sh run_pipeline.py
```

### Python packages fail
```bash
pip install --user -r requirements.txt
```

## 📝 Example Results

Using included example data:
- **Total genes**: 4,606
- **Significant hits**: 354
- **Positive hits**: 354 (upregulated)
- **Negative hits**: 0 (downregulated)

Test with example data:
```bash
python run_pipeline.py  # Uses example_GPR folder
```

## 🎯 Output Files Explained

- `analysis_report_interactive.html` - Interactive visualization
- `*_all_results.csv` - Complete data for all genes
- `*_positive_hits.csv` - Upregulated proteins
- `*_negative_hits.csv` - Downregulated proteins

Each CSV contains:
- Gene ID/Name
- Mean values (Experimental, Control)
- Log2 Fold Change
- T-statistic, P-value, D-value
- Significance classification

## 🚀 Advanced Usage

### Preprocessing only:
```bash
python run_pipeline.py --skip-analysis
```

### Analysis only (if preprocessing done):
```bash
python run_pipeline.py --skip-preprocessing
```

### Custom config:
```bash
python run_pipeline.py --config my_analysis.yaml
```

## 📧 Support

- Create an issue on GitHub
- Check example data in `example_GPR/`
- Review config.yaml for all options

## 📄 License

Provided for research and educational use.

---

**Ready to analyze your proteomics data!** 🧬
