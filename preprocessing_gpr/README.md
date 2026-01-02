# GPR File Preprocessing for SAM Analysis

This folder contains scripts to preprocess GenePix Results (.gpr) files for SAM (Significance Analysis of Microarrays) analysis.

## Overview

The preprocessing script reads GPR files from experimental and control groups, cleans the data, averages technical replicates, and generates an Excel file formatted for SAM analysis.

## Features

- ✅ Automatically skips GPR file headers (first 31 rows)
- ✅ Detects and uses appropriate signal columns (F650, F550, or F60 Median - Background)
- ✅ Removes control/calibration spots (blanks, BSA, lectins, etc.)
- ✅ Averages technical replicates for each protein
- ✅ Combines multiple files from each group
- ✅ Generates SAM-compatible Excel format with group labels

## Requirements

```bash
pip install pandas numpy openpyxl
```

## Usage

### Quick Start

```bash
# Make sure your GPR files are organized:
# example_GPR/experimental_group/*.gpr
# example_GPR/control_group/*.gpr

cd preprocessing_gpr
python preprocess_gpr.py
```

This will create `sam_input.xlsx` in the current directory.

### Custom Paths

```bash
python preprocess_gpr.py \
    --experimental /path/to/experimental_group \
    --control /path/to/control_group \
    --output /path/to/output.xlsx
```

## Input File Structure

### GPR File Format

GPR files should follow the GenePix Results format:
- First 31 rows: Header information
- Row 32: Column headers
- Remaining rows: Data

Required columns (script will auto-detect):
- **ID** or **Row**: Protein/gene identifier
- **F650 Median - B650** (or F550/F60 equivalents): Signal intensity

### Folder Organization

```
example_GPR/
├── experimental_group/
│   ├── sample1.gpr
│   ├── sample2.gpr
│   └── sample3.gpr
└── control_group/
    ├── control1.gpr
    ├── control2.gpr
    └── control3.gpr
```

## Output Format

The script generates an Excel file in SAM-compatible format:

| Column 1 | Column 2 | Column 3 | Column 4 |
|----------|----------|----------|----------|
| (blank)  | (blank)  | 1        | 2        |
| ProteinA | ProteinA | 1234.5   | 890.2    |
| ProteinB | ProteinB | 2345.6   | 1678.3   |

Where:
- **Row 1**: Group labels (1 = experimental, 2 = control)
- **Column 1**: Protein/Gene IDs
- **Column 2**: Protein/Gene names
- **Column 3+**: Expression values

## Processing Steps

1. **Read GPR files**: Skip first 31 header rows
2. **Extract data**: Select Row/ID and signal columns
3. **Filter controls**: Remove calibration spots and blanks
4. **Average replicates**: Calculate mean for duplicate spots
5. **Combine groups**: Merge experimental and control data
6. **Format output**: Create SAM-compatible Excel file

## Removed Control Spots

The following calibration/control spots are automatically removed:
- Cy3/Cy5 mixtures
- Blank spots
- Poly-L-lysine
- BSA (Bovine Serum Albumin)
- Lectin
- Protein A/G
- Streptavidin
- Buffer controls
- Various nagA concentrations

## Example Output

```
Processing 3 control file(s):
  - IBD124.gpr
  - IBD126.gpr
  - IBD127.gpr

Reading IBD124.gpr...
  Found 13856 rows using column 'F650 Median - B650'
  Removed 156 control rows
  Remaining: 13700 data rows
  Averaging replicates...
  Averaged to 6850 unique proteins/features

...

✓ SAM input file created successfully!
  Total proteins/features: 6850
  Experimental samples: 1
  Control samples: 1
```

## Integration with SAM Pipeline

After preprocessing, use the SAM analysis pipeline:

```bash
# Run SAM analysis on preprocessed data
cd /workspaces/SAM_tools_operation
./run_pipeline.sh preprocessing_gpr ./sam_results
```

This will:
1. Process the `sam_input.xlsx` file
2. Perform SAM analysis
3. Generate an HTML report with results

## Troubleshooting

### No GPR files found
- Ensure `.gpr` extension (lowercase)
- Check folder paths are correct

### Column not found error
- Script auto-detects F650/F550/F60 columns
- Verify your GPR file has median-background columns

### Missing values
- Script fills missing values with 0
- Can modify `fillna()` strategy in the code

### Different signal columns
The script automatically detects these column patterns:
- `F650 Median - B650`
- `F550 Median - B550`  
- `F60 Median - B60`

## Advanced Customization

Edit `preprocess_gpr.py` to customize:

### Add more control rows to remove
```python
rows_to_remove = [
    # ... existing rows ...
    "YourCustomControl",
]
```

### Change replicate averaging method
```python
# Use median instead of mean
df_avg = df.groupby('Row')['Signal'].median().reset_index()
```

### Handle missing values differently
```python
# Use median imputation instead of 0
merged_df['Signal_exp'] = merged_df['Signal_exp'].fillna(merged_df['Signal_exp'].median())
```

## Next Steps

1. ✅ Preprocess GPR files → Excel
2. 📊 Run SAM analysis → Statistical results
3. 📄 Generate HTML report → Visualization

See [../README_pipeline.md](../README_pipeline.md) for SAM analysis documentation.
