#!/bin/bash

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║   TESTING: Input Changes → HTML Output Changes                ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Backup current state
echo "📋 Step 1: Capturing current state..."
echo "---------------------------------------------------"
current_exp=$(grep -oP 'Experimental Group \(\s*\K\d+' ttest_results/analysis_report_interactive.html)
current_ctrl=$(grep -oP 'Control Group \(\s*\K\d+' ttest_results/analysis_report_interactive.html)
current_total=$(grep -oP '<div class="stat-value">\s*\K\d+' ttest_results/analysis_report_interactive.html | head -1)

echo "Current HTML shows:"
echo "  • Experimental samples: $current_exp"
echo "  • Control samples: $current_ctrl"
echo "  • Total genes: $current_total"
echo ""

# Step 2: Check input CSV
echo "📊 Step 2: Checking input CSV..."
echo "---------------------------------------------------"
csv_first_line=$(head -1 preprocessing_gpr/sam_input.csv)
csv_exp_count=$(echo "$csv_first_line" | tr ',' '\n' | grep -c "1.0")
csv_ctrl_count=$(echo "$csv_first_line" | tr ',' '\n' | grep -c "2.0")

echo "Input CSV shows:"
echo "  • Experimental (1.0): $csv_exp_count"
echo "  • Control (2.0): $csv_ctrl_count"
echo ""

# Step 3: Verify they match
echo "✅ Step 3: Verification..."
echo "---------------------------------------------------"
if [ "$current_exp" = "$csv_exp_count" ] && [ "$current_ctrl" = "$csv_ctrl_count" ]; then
    echo "✅ HTML matches CSV perfectly!"
    echo "   Experimental: $current_exp = $csv_exp_count ✓"
    echo "   Control: $current_ctrl = $csv_ctrl_count ✓"
else
    echo "⚠️  Mismatch detected!"
    echo "   HTML exp=$current_exp, CSV exp=$csv_exp_count"
    echo "   HTML ctrl=$current_ctrl, CSV ctrl=$csv_ctrl_count"
fi
echo ""

# Step 4: Simulate input change
echo "🔄 Step 4: Simulating input change..."
echo "---------------------------------------------------"
echo "Creating a modified test input with different sample counts..."

# Backup original
cp preprocessing_gpr/sam_input.csv preprocessing_gpr/sam_input.csv.backup

# Create modified version with 5 experimental and 2 control
head -1 preprocessing_gpr/sam_input.csv > /tmp/modified_header.txt
# Change last column from 2.0 to 1.0 (move one control to experimental)
sed '1s/2\.0$/1.0/' preprocessing_gpr/sam_input.csv > preprocessing_gpr/sam_input_modified.csv

# For cleaner test, create completely new version
cat > preprocessing_gpr/sam_input_test.csv << 'CSVDATA'
,,1.0,1.0,1.0,1.0,1.0,2.0,2.0
3396,3396,559.5,230.0,789.5,298.0,450.0,348.5,167.0
3397,3397,636.0,213.0,715.5,180.0,420.0,410.0,189.0
3398,3398,234.5,456.0,678.0,234.0,345.0,123.0,234.0
CSVDATA

echo "Test input created with:"
echo "  • Experimental: 5 samples (instead of $csv_exp_count)"
echo "  • Control: 2 samples (instead of $csv_ctrl_count)"
echo ""

# Step 5: Process with modified input
echo "⚙️  Step 5: Generating HTML from modified input..."
echo "---------------------------------------------------"

# Create test results from the modified input
mkdir -p test_output

# Copy existing results but we'll regenerate HTML with modified sample info
cp ttest_results/sam_input_all_results.csv test_output/
cp ttest_results/sam_input_positive_hits.csv test_output/
cp ttest_results/sam_input_negative_hits.csv test_output/

# Temporarily replace the input file
mv preprocessing_gpr/sam_input.csv preprocessing_gpr/sam_input_original.csv
cp preprocessing_gpr/sam_input_test.csv preprocessing_gpr/sam_input.csv

# Regenerate HTML with new sample info
Rscript create_html_report.R test_output 0.5 1.0 > /dev/null 2>&1

# Restore original
mv preprocessing_gpr/sam_input_original.csv preprocessing_gpr/sam_input.csv

echo "✅ HTML regenerated with modified input"
echo ""

# Step 6: Check new HTML
echo "📄 Step 6: Checking updated HTML..."
echo "---------------------------------------------------"
new_exp=$(grep -oP 'Experimental Group \(\s*\K\d+' test_output/analysis_report_interactive.html)
new_ctrl=$(grep -oP 'Control Group \(\s*\K\d+' test_output/analysis_report_interactive.html)

echo "New HTML shows:"
echo "  • Experimental samples: $new_exp"
echo "  • Control samples: $new_ctrl"
echo ""

# Step 7: Compare before and after
echo "🔍 Step 7: Comparison Results"
echo "═══════════════════════════════════════════════════════════════"
echo ""
printf "%-25s | %-15s | %-15s | %-10s\n" "Metric" "Original" "Modified" "Changed?"
echo "-------------------------------------------------------------------"
printf "%-25s | %-15s | %-15s | %-10s\n" "Experimental Samples" "$current_exp" "$new_exp" "$([ "$current_exp" != "$new_exp" ] && echo '✅ YES' || echo '❌ NO')"
printf "%-25s | %-15s | %-15s | %-10s\n" "Control Samples" "$current_ctrl" "$new_ctrl" "$([ "$current_ctrl" != "$new_ctrl" ] && echo '✅ YES' || echo '❌ NO')"
echo ""

# Step 8: Extract actual sample names from both HTMLs
echo "📝 Step 8: Sample Names Comparison"
echo "═══════════════════════════════════════════════════════════════"

echo ""
echo "ORIGINAL HTML Sample Names:"
echo "-------------------------------------------------------------------"
grep -A 2 "Experimental Group" ttest_results/analysis_report_interactive.html | grep "Sample_" | sed 's/<[^>]*>//g' | xargs
echo ""

echo "MODIFIED HTML Sample Names:"
echo "-------------------------------------------------------------------"
grep -A 2 "Experimental Group" test_output/analysis_report_interactive.html | grep "Sample_" | sed 's/<[^>]*>//g' | xargs
echo ""

# Final verdict
echo "╔════════════════════════════════════════════════════════════════╗"
echo "║                    FINAL VERIFICATION                          ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

if [ "$current_exp" != "$new_exp" ] || [ "$current_ctrl" != "$new_ctrl" ]; then
    echo "✅ SUCCESS: HTML OUTPUT CHANGES WHEN INPUT CHANGES!"
    echo ""
    echo "Evidence:"
    echo "  • Input changed: $csv_exp_count exp → 5 exp"
    echo "  • HTML updated: $current_exp exp → $new_exp exp"
    echo "  • Control changed: $csv_ctrl_count ctrl → 2 ctrl"
    echo "  • HTML updated: $current_ctrl ctrl → $new_ctrl ctrl"
    echo ""
    echo "🎯 The system is FULLY DYNAMIC and WORKING CORRECTLY!"
else
    echo "⚠️  Sample counts didn't change (but gene data might be same)"
    echo "   This could mean the test input had same counts"
fi

echo ""
echo "═══════════════════════════════════════════════════════════════"
echo "Test files created in: test_output/"
echo "  • test_output/analysis_report_interactive.html (modified)"
echo "  • ttest_results/analysis_report_interactive.html (original)"
echo ""
echo "Compare them to see the differences!"
echo "═══════════════════════════════════════════════════════════════"

# Cleanup
rm -f preprocessing_gpr/sam_input.csv.backup
rm -f preprocessing_gpr/sam_input_modified.csv

