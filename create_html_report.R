#!/usr/bin/env Rscript

# Simple HTML Report Generator
library(openxlsx)

args <- commandArgs(trailingOnly = TRUE)
output_folder <- args[1]
log2fc_cutoff <- as.numeric(args[2])
d_value_cutoff <- as.numeric(args[3])

# Read the CSV files
all_results <- read.csv(file.path(output_folder, "sam_input_all_results.csv"))
pos_hits <- read.csv(file.path(output_folder, "sam_input_positive_hits.csv"))
neg_hits <- read.csv(file.path(output_folder, "sam_input_negative_hits.csv"))

# Create HTML
html_file <- file.path(output_folder, "analysis_report_interactive.html")

cat('<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>T-test Analysis Report</title>
  <link rel="stylesheet" href="https://cdn.datatables.net/1.13.6/css/jquery.dataTables.min.css">
  <script src="https://code.jquery.com/jquery-3.7.0.min.js"></script>
  <script src="https://cdn.datatables.net/1.13.6/js/jquery.dataTables.min.js"></script>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1400px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
    h1 { color: #2c3e50; border-bottom: 3px solid #3498db; padding-bottom: 10px; }
    h2 { color: #34495e; margin-top: 30px; }
    .stats { display: grid; grid-template-columns: repeat(auto-fit, minmax(200px, 1fr)); gap: 20px; margin: 20px 0; }
    .stat-card { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px; text-align: center; }
    .stat-value { font-size: 2.5em; font-weight: bold; }
    .stat-label { font-size: 0.9em; opacity: 0.9; }
    .positive { background: linear-gradient(135deg, #11998e 0%, #38ef7d 100%) !important; }
    .negative { background: linear-gradient(135deg, #eb3349 0%, #f45c43 100%) !important; }
    .download-btn { display: inline-block; margin: 10px 5px; padding: 12px 24px; background: #3498db; color: white; text-decoration: none; border-radius: 4px; font-weight: 600; }
    .download-btn:hover { background: #2980b9; }
    table.dataTable { width: 100% !important; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🔬 T-test Proteomics Analysis Report</h1>
    <p><strong>Generated:</strong> ', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '</p>
    <p><strong>Log2 FC Cutoff:</strong> ±', log2fc_cutoff, ' | <strong>D-value Cutoff:</strong> ±', d_value_cutoff, '</p>
    
    <div class="stats">
      <div class="stat-card">
        <div class="stat-value">', nrow(all_results), '</div>
        <div class="stat-label">Total Genes</div>
      </div>
      <div class="stat-card positive">
        <div class="stat-value">', nrow(pos_hits), '</div>
        <div class="stat-label">Positive Hits (↑)</div>
      </div>
      <div class="stat-card negative">
        <div class="stat-value">', nrow(neg_hits), '</div>
        <div class="stat-label">Negative Hits (↓)</div>
      </div>
      <div class="stat-card">
        <div class="stat-value">', nrow(pos_hits) + nrow(neg_hits), '</div>
        <div class="stat-label">Total Significant</div>
      </div>
    </div>
    
    <div style="margin: 30px 0;">
      <a href="sam_input_all_results.csv" class="download-btn" download>📥 Download All Results</a>
      <a href="sam_input_positive_hits.csv" class="download-btn" download>⬆️ Download Positive Hits</a>
      <a href="sam_input_negative_hits.csv" class="download-btn" download>⬇️ Download Negative Hits</a>
    </div>
    
    <h2>📊 Top Positive Hits (Top 100)</h2>
    <table id="positiveTable" class="display">
      <thead>
        <tr>
          <th>Gene ID</th>
          <th>Gene Name</th>
          <th>Mean Exp</th>
          <th>Mean Ctrl</th>
          <th>Log2 FC</th>
          <th>T-statistic</th>
          <th>P-value</th>
          <th>D-value</th>
        </tr>
      </thead>
      <tbody>
', file = html_file)

# Add top 100 positive hits
if (nrow(pos_hits) > 0) {
  top_pos <- head(pos_hits[order(-abs(pos_hits$Log2FC)), ], 100)
  for (i in 1:nrow(top_pos)) {
    row <- top_pos[i, ]
    cat(sprintf('        <tr>
          <td>%s</td>
          <td><strong>%s</strong></td>
          <td>%.2f</td>
          <td>%.2f</td>
          <td><strong>%.3f</strong></td>
          <td>%.3f</td>
          <td>%.2e</td>
          <td><strong>%.3f</strong></td>
        </tr>\n', row$GeneID, row$GeneName, row$Mean_Exp, row$Mean_Ctrl, row$Log2FC, 
        row$T_statistic, row$P_value, row$D_value), file = html_file, append = TRUE)
  }
}

cat('      </tbody>
    </table>
    
    <h2>📉 Top Negative Hits (Top 100)</h2>
    <table id="negativeTable" class="display">
      <thead>
        <tr>
          <th>Gene ID</th>
          <th>Gene Name</th>
          <th>Mean Exp</th>
          <th>Mean Ctrl</th>
          <th>Log2 FC</th>
          <th>T-statistic</th>
          <th>P-value</th>
          <th>D-value</th>
        </tr>
      </thead>
      <tbody>
', file = html_file, append = TRUE)

# Add top 100 negative hits
if (nrow(neg_hits) > 0) {
  top_neg <- head(neg_hits[order(neg_hits$Log2FC), ], 100)
  for (i in 1:nrow(top_neg)) {
    row <- top_neg[i, ]
    cat(sprintf('        <tr>
          <td>%s</td>
          <td><strong>%s</strong></td>
          <td>%.2f</td>
          <td>%.2f</td>
          <td><strong>%.3f</strong></td>
          <td>%.3f</td>
          <td>%.2e</td>
          <td><strong>%.3f</strong></td>
        </tr>\n', row$GeneID, row$GeneName, row$Mean_Exp, row$Mean_Ctrl, row$Log2FC, 
        row$T_statistic, row$P_value, row$D_value), file = html_file, append = TRUE)
  }
}

cat('      </tbody>
    </table>
    
    <script>
    $(document).ready(function() {
      $("#positiveTable").DataTable({
        pageLength: 25,
        order: [[4, "desc"]],
        columnDefs: [
          { targets: [2,3,4,5,6,7], className: "dt-right" }
        ]
      });
      $("#negativeTable").DataTable({
        pageLength: 25,
        order: [[4, "asc"]],
        columnDefs: [
          { targets: [2,3,4,5,6,7], className: "dt-right" }
        ]
      });
    });
    </script>
  </div>
</body>
</html>', file = html_file, append = TRUE)

cat("HTML report created successfully!\n")
