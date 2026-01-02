# SAM Proteomics Pipeline

This pipeline automates the processing of proteomics data using the SAM (Significance Analysis of Microarrays) method and generates an HTML report with the results.

## Features

- **Automated Input Processing**: Processes all Excel files (.xlsx, .xls) in the input folder
- **Missing Value Imputation**: Automatically handles missing data using k-nearest neighbors imputation
- **SAM Analysis**: Performs statistical analysis to identify differentially expressed proteins
- **HTML Report Generation**: Creates a comprehensive, interactive HTML report with:
  - Summary statistics
  - Detailed results for each dataset
  - Delta tables showing significance thresholds
  - False Discovery Rate (FDR) estimates

## Prerequisites

### Required Software
- R (version 4.0 or higher)
- RStudio (optional, but recommended)

### Required R Packages
The pipeline will automatically install missing packages, but you can install them manually:

```r
install.packages(c("shiny", "openxlsx", "samr", "GSA"))

# Install Bioconductor packages
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")

BiocManager::install("impute")
```

## Input Data Format

Your Excel files should be formatted as follows:

| Gene ID | Gene Name | Sample1 | Sample2 | Sample3 | ... |
|---------|-----------|---------|---------|---------|-----|
| ID1     | Name1     | value   | value   | value   | ... |
| ID2     | Name2     | value   | value   | value   | ... |

- **First row**: Sample labels and class labels (e.g., 0 for control, 1 for treatment)
- **First column**: Gene/Protein IDs
- **Second column**: Gene/Protein names
- **Remaining columns**: Expression values for each sample

### Example Input Files

See the `SAM_proteomics/Data examples/` folder for example datasets:
- `Two Class.xlsx`: Example of two-class comparison
- `Paired Sequencing.xlsx`: Example of paired data

## Usage

### Quick Start (Bash Script)

```bash
# Make the script executable
chmod +x run_pipeline.sh

# Run the pipeline
./run_pipeline.sh <input_folder> <output_folder>

# Example:
./run_pipeline.sh ./data ./output
```

### Alternative: Direct R Script

```bash
Rscript sam_pipeline.R <input_folder> <output_folder>
```

### Example Usage

```bash
# Process data from the SAM_proteomics examples
./run_pipeline.sh "SAM_proteomics/Data examples" ./results

# Process your own data
./run_pipeline.sh ./my_data ./my_results
```

## Output

The pipeline generates the following files in the output folder:

1. **sam_analysis_report.html**: Interactive HTML report with:
   - Overview of processed datasets
   - Summary statistics (total genes, samples, imputed values)
   - Detailed results for each input file
   - Delta tables showing significance thresholds
   - FDR estimates

2. **sam_results.RData**: R data file containing all analysis results for further processing

## Pipeline Workflow

```
Input Folder
    ↓
[1] Load Excel files
    ↓
[2] Extract gene info & expression data
    ↓
[3] Impute missing values (if needed)
    ↓
[4] Detect response type (Two-class/Quantitative)
    ↓
[5] Run SAM analysis
    ↓
[6] Generate HTML report
    ↓
Output Folder
```

## Advanced Options

To modify the pipeline behavior, edit `sam_pipeline.R`:

- **Number of permutations**: Change `nperms = 100` to a higher value for more robust results
- **k-NN imputation**: Change `k = 10` to adjust the number of neighbors for imputation
- **Delta threshold**: Modify the SAM parameters for different stringency

## Troubleshooting

### Common Issues

1. **Missing packages**: The script will attempt to install them automatically
2. **Memory issues**: For large datasets, increase R memory limit:
   ```r
   # Add to beginning of sam_pipeline.R
   options(java.parameters = "-Xmx8g")
   ```
3. **Excel file format**: Ensure files are in .xlsx or .xls format

### Getting Help

- Check the SAM manual: `SAM_proteomics/sam-manual.pdf`
- Review example datasets: `SAM_proteomics/Data examples/`
- Check sample output: `SAM_proteomics/Sample Output/`

## Example Output

After running the pipeline, you'll see:

```
SAM Proteomics Pipeline
=======================
Input folder: ./data
Output folder: ./output

Found 2 Excel file(s) to process:
  - Two Class.xlsx
  - Paired Sequencing.xlsx

Processing: Two Class.xlsx
  - Imputing 5 missing values...
  - Detected response type: Two class unpaired
  - Running SAM analysis...
  - Analysis complete! (5000 genes, 20 samples)

Processing: Paired Sequencing.xlsx
  - Detected response type: Two class paired
  - Running SAM analysis...
  - Analysis complete! (3000 genes, 16 samples)

Generating HTML report...

✓ Pipeline complete!
  - HTML report: ./output/sam_analysis_report.html
  - R data: ./output/sam_results.RData
```

## Citation

If you use this pipeline, please cite the original SAM paper:

Tusher VG, Tibshirani R, Chu G. Significance analysis of microarrays applied to the ionizing radiation response. PNAS 2001 98(9):5116-21.

## License

This pipeline wraps the SAM_proteomics tool created by Michael Seo. Please see the original repository for license information.
