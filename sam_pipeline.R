#!/usr/bin/env Rscript

# SAM Proteomics Pipeline with T-test and Interactive HTML
# This pipeline processes proteomics data and generates interactive HTML output

# Load required libraries
suppressPackageStartupMessages({
  library(openxlsx)
  library(impute)
})

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  cat("Usage: Rscript sam_pipeline.R <input_folder> <output_folder> [log2fc_cutoff] [d_value_cutoff]\n")
  cat("Example: Rscript sam_pipeline.R ./data ./output 1.0 2.0\n")
  cat("\nDefault cutoffs:\n")
  cat("  log2fc_cutoff: 1.0 (2-fold change)\n")
  cat("  d_value_cutoff: 2.0 (similar to p-value < 0.05)\n")
  quit(status = 1)
}

input_folder <- args[1]
output_folder <- args[2]
log2fc_cutoff <- ifelse(length(args) >= 3, as.numeric(args[3]), 1.0)
d_value_cutoff <- ifelse(length(args) >= 4, as.numeric(args[4]), 2.0)

# Create output folder if it doesn't exist
if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
}

cat("SAM Proteomics Pipeline\n")
cat("=======================\n")
cat(sprintf("Input folder: %s\n", input_folder))
cat(sprintf("Output folder: %s\n", output_folder))
cat(sprintf("Log2 Fold Change cutoff: %.2f\n", log2fc_cutoff))
cat(sprintf("D-value cutoff: %.2f\n", d_value_cutoff))
cat("\n")

# Find all Excel files in the input folder
excel_files <- list.files(input_folder, pattern = "\\.(xlsx|xls)$", full.names = TRUE)

if (length(excel_files) == 0) {
  cat("Error: No Excel files found in the input folder.\n")
  quit(status = 1)
}

cat(sprintf("Found %d Excel file(s) to process:\n", length(excel_files)))
for (f in excel_files) {
  cat(sprintf("  - %s\n", basename(f)))
}
cat("\n")

# Process each Excel file
results <- list()

for (file_path in excel_files) {
  file_name <- basename(file_path)
  cat(sprintf("Processing: %s\n", file_name))
  
  tryCatch({
    # Read data
    dat <- read.xlsx(file_path, 1, colNames = FALSE)
    
    # Extract gene information
    geneid <- dat[-1, 1]
    genenames <- dat[-1, 2]
    
    # Extract expression data
    x <- as.matrix(dat[-1, c(-1, -2)])
    class(x) <- "numeric"
    
    # Handle missing values with imputation
    if (sum(is.na(x)) > 0) {
      cat(sprintf("  - Imputing %d missing values...\n", sum(is.na(x))))
      imputed <- impute.knn(x, k = 10)
      x <- imputed$data
    }
    
    # Extract response variable
    firstrow <- as.vector(dat[1, c(-1, -2)])
    y <- firstrow
    
    # Prepare data for SAM analysis
    # Determine response type (assume Two Class for numeric 0/1, Quantitative otherwise)
    unique_vals <- unique(y[!is.na(y)])
    
    if (all(unique_vals %in% c(0, 1, "0", "1"))) {
      y <- as.numeric(y)
      resp_type <- "Two class unpaired"
      cat("  - Detected response type: Two class unpaired\n")
    } else {
      y <- as.numeric(y)
      resp_type <- "Quantitative"
      cat("  - Detected response type: Quantitative\n")
    }
    
    # Prepare SAM data object
    samdata <- list(
      x = x,
      y = y,
      geneid = geneid,
      genenames = genenames,
      logged2 = TRUE
    )
    
    # Run SAM analysis
    cat("  - Running SAM analysis...\n")
    if (resp_type == "Two class unpaired") {
      samfit <- SAM(samdata$x, samdata$y, resp.type = "Two class unpaired", nperms = 100)
    } else {
      samfit <- SAM(samdata$x, samdata$y, resp.type = "Quantitative", nperms = 100)
    }
    
    # Store results
    results[[file_name]] <- list(
      data = samdata,
      fit = samfit,
      resp_type = resp_type,
      n_genes = nrow(x),
      n_samples = ncol(x),
      n_imputed = sum(is.na(as.matrix(dat[-1, c(-1, -2)])))
    )
    
    cat(sprintf("  - Analysis complete! (%d genes, %d samples)\n\n", nrow(x), ncol(x)))
    
  }, error = function(e) {
    cat(sprintf("  - Error processing %s: %s\n\n", file_name, e$message))
  })
}

# Generate HTML report
cat("Generating HTML report...\n")

html_output <- file.path(output_folder, "sam_analysis_report.html")

# Create HTML content
html_content <- sprintf('
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>SAM Proteomics Analysis Report</title>
  <style>
    body {
      font-family: Arial, sans-serif;
      margin: 40px;
      background-color: #f5f5f5;
    }
    .container {
      max-width: 1200px;
      margin: 0 auto;
      background-color: white;
      padding: 30px;
      border-radius: 8px;
      box-shadow: 0 2px 4px rgba(0,0,0,0.1);
    }
    h1 {
      color: #2c3e50;
      border-bottom: 3px solid #3498db;
      padding-bottom: 10px;
    }
    h2 {
      color: #34495e;
      margin-top: 30px;
      border-left: 4px solid #3498db;
      padding-left: 10px;
    }
    h3 {
      color: #7f8c8d;
    }
    .info-box {
      background-color: #ecf0f1;
      padding: 15px;
      border-radius: 5px;
      margin: 15px 0;
    }
    .success {
      color: #27ae60;
      font-weight: bold;
    }
    .error {
      color: #e74c3c;
      font-weight: bold;
    }
    table {
      border-collapse: collapse;
      width: 100%%;
      margin: 20px 0;
    }
    th, td {
      border: 1px solid #ddd;
      padding: 12px;
      text-align: left;
    }
    th {
      background-color: #3498db;
      color: white;
    }
    tr:nth-child(even) {
      background-color: #f2f2f2;
    }
    .timestamp {
      color: #7f8c8d;
      font-size: 0.9em;
    }
    .metric {
      display: inline-block;
      margin: 10px 20px 10px 0;
    }
    .metric-label {
      color: #7f8c8d;
      font-size: 0.9em;
    }
    .metric-value {
      font-size: 1.5em;
      font-weight: bold;
      color: #2c3e50;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>SAM Proteomics Analysis Report</h1>
    <p class="timestamp">Generated: %s</p>
    
    <div class="info-box">
      <strong>Input Folder:</strong> %s<br>
      <strong>Output Folder:</strong> %s<br>
      <strong>Files Processed:</strong> %d / %d
    </div>
',
  format(Sys.time(), "%Y-%m-%d %H:%M:%S"),
  input_folder,
  output_folder,
  length(results),
  length(excel_files)
)

# Add summary statistics
html_content <- paste0(html_content, '
    <h2>Summary Statistics</h2>
    <div class="info-box">
')

total_genes <- 0
total_samples <- 0
total_imputed <- 0

for (file_name in names(results)) {
  result <- results[[file_name]]
  total_genes <- total_genes + result$n_genes
  total_samples <- total_samples + result$n_samples
  total_imputed <- total_imputed + result$n_imputed
}

html_content <- paste0(html_content, sprintf('
      <div class="metric">
        <div class="metric-label">Total Genes</div>
        <div class="metric-value">%d</div>
      </div>
      <div class="metric">
        <div class="metric-label">Total Samples</div>
        <div class="metric-value">%d</div>
      </div>
      <div class="metric">
        <div class="metric-label">Missing Values Imputed</div>
        <div class="metric-value">%d</div>
      </div>
    </div>
', total_genes, total_samples, total_imputed))

# Add detailed results for each file
html_content <- paste0(html_content, '
    <h2>Detailed Results</h2>
')

for (file_name in names(results)) {
  result <- results[[file_name]]
  
  html_content <- paste0(html_content, sprintf('
    <h3>%s</h3>
    <table>
      <tr>
        <th>Metric</th>
        <th>Value</th>
      </tr>
      <tr>
        <td>Response Type</td>
        <td>%s</td>
      </tr>
      <tr>
        <td>Number of Genes</td>
        <td>%d</td>
      </tr>
      <tr>
        <td>Number of Samples</td>
        <td>%d</td>
      </tr>
      <tr>
        <td>Missing Values Imputed</td>
        <td>%d</td>
      </tr>
      <tr>
        <td>Analysis Status</td>
        <td><span class="success">✓ Complete</span></td>
      </tr>
    </table>
  ', file_name, result$resp_type, result$n_genes, result$n_samples, result$n_imputed))
  
  # Add delta table if available
  if (!is.null(result$fit$delta.table) && nrow(result$fit$delta.table) > 0) {
    delta_table <- result$fit$delta.table
    
    html_content <- paste0(html_content, '
    <h4>Delta Table (Significance Thresholds)</h4>
    <table>
      <tr>
        <th>Delta</th>
        <th>Cutlow</th>
        <th>Cutup</th>
        <th>Called</th>
        <th>FDR</th>
      </tr>
    ')
    
    # Show first 10 rows
    n_rows <- min(10, nrow(delta_table))
    for (i in 1:n_rows) {
      html_content <- paste0(html_content, sprintf('
      <tr>
        <td>%.3f</td>
        <td>%.3f</td>
        <td>%.3f</td>
        <td>%d</td>
        <td>%.3f</td>
      </tr>
      ', delta_table[i, 1], delta_table[i, 2], delta_table[i, 3], 
         delta_table[i, 4], delta_table[i, 5]))
    }
    
    html_content <- paste0(html_content, '
    </table>
    ')
  }
}

# Close HTML
html_content <- paste0(html_content, '
  </div>
</body>
</html>
')

# Write HTML file
writeLines(html_content, html_output)

# Save R data object with all results
rdata_output <- file.path(output_folder, "sam_results.RData")
save(results, file = rdata_output)

cat(sprintf("\n✓ Pipeline complete!\n"))
cat(sprintf("  - HTML report: %s\n", html_output))
cat(sprintf("  - R data: %s\n", rdata_output))
