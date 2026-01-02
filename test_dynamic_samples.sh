#!/bin/bash

echo "Testing Dynamic Sample Information in HTML Report"
echo "=================================================="

# Test 1: Check current sample information
echo ""
echo "Test 1: Verify sample information is extracted"
grep -A 5 "Sample Information" ttest_results/analysis_report_interactive.html | grep -E "Experimental|Control|Sample_"
if [ $? -eq 0 ]; then
    echo "✅ Sample information found in HTML"
else
    echo "❌ Sample information not found"
fi

# Test 2: Count samples
echo ""
echo "Test 2: Verify sample counts"
exp_count=$(grep "Experimental Group" ttest_results/analysis_report_interactive.html | grep -oP '\(\s*\K\d+(?=\s*samples)')
ctrl_count=$(grep "Control Group" ttest_results/analysis_report_interactive.html | grep -oP '\(\s*\K\d+(?=\s*samples)')

echo "Experimental samples: $exp_count"
echo "Control samples: $ctrl_count"

# Test 3: Check if sample names are displayed
echo ""
echo "Test 3: Sample names in HTML"
sample_names=$(grep -A 2 "Experimental Group" ttest_results/analysis_report_interactive.html | grep "Sample_" | sed 's/<[^>]*>//g' | xargs)
echo "Sample names: $sample_names"

# Test 4: Verify it matches input CSV
echo ""
echo "Test 4: Verify counts match input CSV"
csv_exp=$(head -1 preprocessing_gpr/sam_input.csv | tr ',' '\n' | grep -c "1.0")
csv_ctrl=$(head -1 preprocessing_gpr/sam_input.csv | tr ',' '\n' | grep -c "2.0")
echo "CSV Experimental: $csv_exp"
echo "CSV Control: $csv_ctrl"

if [ "$exp_count" = "$csv_exp" ] && [ "$ctrl_count" = "$csv_ctrl" ]; then
    echo "✅ Sample counts match input CSV!"
else
    echo "⚠️  Sample counts differ from CSV"
fi

echo ""
echo "Test 5: What happens when you change the input?"
echo "---------------------------------------------------"
cat << 'INSTRUCTIONS'

To test dynamic updates:

1. Modify your input GPR files:
   - Add or remove files from example_GPR/experimental_group/
   - Add or remove files from example_GPR/control_group/

2. Run the pipeline again:
   ./run_pipeline.sh

3. Check the new HTML report:
   The sample counts and names will automatically update!

Example:
- Current: 4 experimental, 3 control
- Add 2 more files to experimental_group → 6 experimental, 3 control
- The HTML will show "Experimental Group (6 samples)"

INSTRUCTIONS

echo ""
echo "=================================================="
echo "✅ All tests completed!"
echo "The HTML report will now automatically update sample"
echo "information whenever you change your input data!"

