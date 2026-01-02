# SAM Proteomics Analysis Pipeline

Automated pipeline for analyzing proteomics data from GenePix Results (GPR) files using T-test statistical analysis.

## 🚀 Quick Start

```bash
# 1. Clone and setup
git clone https://github.com/HoangSon710/SAM_tools_operation.git
cd SAM_tools_operation
./setup.sh

# 2. Configure analysis (edit config.yaml)
# Set your input folders and cutoffs

# 3. Run pipeline
python run_pipeline.py
```

## 📊 Output

- Interactive HTML report with sortable tables
- CSV files: all results, positive hits, negative hits
- T-test statistics with effect sizes

## � Using Your Data

1. Organize GPR files into `experimental/` and `control/` folders
2. Edit `config.yaml` to set folder paths and cutoffs
3. Run `python run_pipeline.py`
4. Open `results/analysis_report_interactive.html`

## ⚙️ Configuration

Edit `config.yaml` to adjust:
- Input/output folders
- Log2FC cutoff (default: 1.0)
- D-value cutoff (default: 2.0)

## 📦 Requirements

- Python 3.8+ and R 4.0+
- Installed automatically via `setup.sh`

## 🔧 Troubleshooting

**Permission denied**: `chmod +x setup.sh run_pipeline.py`  
**R not found**: `sudo apt-get install r-base` (Ubuntu) or `brew install r` (Mac)
