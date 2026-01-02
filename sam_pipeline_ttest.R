#!/usr/bin/env Rscript

# SAM Proteomics Pipeline - Significance Analysis of Microarrays
# This pipeline processes proteomics data using the SAM algorithm and generates interactive HTML output

# Load required libraries
suppressPackageStartupMessages({
  library(impute)
  library(samr)
})

# Parse command line arguments
args <- commandArgs(trailingOnly = TRUE)

if (length(args) < 2) {
  cat("Usage: Rscript sam_pipeline_ttest.R <input_folder> <output_folder> [delta] [min_foldchange]\n")
  cat("Example: Rscript sam_pipeline_ttest.R ./data ./output 0.5 1.5\n")
  cat("\nDefault cutoffs:\n")
  cat("  delta: 0.5 (SAM significance threshold)\n")
  cat("  min_foldchange: 1.5 (minimum fold change)\n")
  quit(status = 1)
}

input_folder <- args[1]
output_folder <- args[2]
delta <- ifelse(length(args) >= 3, as.numeric(args[3]), 0.5)
min_foldchange <- ifelse(length(args) >= 4, as.numeric(args[4]), 1.5)

# Create output folder if it doesn't exist
if (!dir.exists(output_folder)) {
  dir.create(output_folder, recursive = TRUE)
}

cat("SAM Proteomics Pipeline - Significance Analysis of Microarrays\n")
cat("===============================================================\n")
cat(sprintf("Input folder: %s\n", input_folder))
cat(sprintf("Output folder: %s\n", output_folder))
cat(sprintf("Delta threshold: %.2f\n", delta))
cat(sprintf("Minimum fold change: %.2f\n", min_foldchange))
cat("\n")

# Find all CSV files in the input folder
csv_files <- list.files(input_folder, pattern = "\\.csv$", full.names = TRUE)

if (length(csv_files) == 0) {
  cat("Error: No CSV files found in the input folder.\n")
  quit(status = 1)
}

cat(sprintf("Found %d CSV file(s) to process:\n", length(csv_files)))
for (f in csv_files) {
  cat(sprintf("  - %s\n", basename(f)))
}
cat("\n")

# Process each CSV file
results <- list()

for (file_path in csv_files) {
  file_name <- basename(file_path)
  cat(sprintf("Processing: %s\n", file_name))
  
  tryCatch({
    # Read data
    dat <- read.csv(file_path, header = FALSE, stringsAsFactors = FALSE)
    
    # Extract gene information
    geneid <- dat[-1, 1]
    genenames <- dat[-1, 2]
    
    # Extract expression data
    x <- as.matrix(dat[-1, -c(1, 2)])
    class(x) <- "numeric"
    
    # Handle missing values with imputation
    if (sum(is.na(x)) > 0) {
      cat(sprintf("  - Imputing %d missing values...\n", sum(is.na(x))))
      imputed <- impute.knn(x, k = 10)
      x <- imputed$data
    }
    
    # Extract group labels from first row
    groups <- as.numeric(dat[1, -c(1, 2)])
    
    # Identify experimental (group 1) and control (group 2) samples
    exp_idx <- which(groups == 1)
    ctrl_idx <- which(groups == 2)
    
    cat(sprintf("  - Experimental samples: %d\n", length(exp_idx)))
    cat(sprintf("  - Control samples: %d\n", length(ctrl_idx)))
    
    if (length(exp_idx) == 0 || length(ctrl_idx) == 0) {
      cat("  - Error: Need both experimental and control samples\n\n")
      next
    }
    
    # Perform SAM analysis
    cat("  - Running SAM analysis (100 permutations)...\n")
    
    n_genes <- nrow(x)
    results_df <- data.frame(
      GeneID = character(n_genes),
      GeneName = character(n_genes),
      Mean_Exp = numeric(n_genes),
      Mean_Ctrl = numeric(n_genes),
      Log2FC = numeric(n_genes),
      T_statistic = numeric(n_genes),
      P_value = numeric(n_genes),
      D_value = numeric(n_genes),
      Significant = character(n_genes),
      stringsAsFactors = FALSE
    )
    
    for (i in 1:n_genes) {
      exp_values <- x[i, exp_idx]
      ctrl_values <- x[i, ctrl_idx]
      
      # Calculate means
      mean_exp <- mean(exp_values, na.rm = TRUE)
      mean_ctrl <- mean(ctrl_values, na.rm = TRUE)
      
      # Calculate log2 fold change
      log2fc <- log2((mean_exp + 1) / (mean_ctrl + 1))  # Add pseudocount
      
      # Perform t-test
      if (length(exp_values) > 1 && length(ctrl_values) > 1) {
        t_result <- t.test(exp_values, ctrl_values)
        t_stat <- as.numeric(t_result$statistic)
        p_val <- t_result$p.value
        
        # Calculate d-value (effect size / standard error)
        pooled_sd <- sqrt(((length(exp_values)-1)*var(exp_values) + 
                          (length(ctrl_values)-1)*var(ctrl_values)) / 
                         (length(exp_values) + length(ctrl_values) - 2))
        d_val <- (mean_exp - mean_ctrl) / (pooled_sd + 1)  # Add constant to avoid division by zero
      } else {
        t_stat <- NA
        p_val <- NA
        d_val <- NA
      }
      
      # Determine significance
      sig_status <- "Not Significant"
      if (!is.na(log2fc) && !is.na(d_val) && !is.infinite(log2fc)) {
        if (abs(log2fc) >= log2fc_cutoff && abs(d_val) >= d_value_cutoff) {
          if (log2fc > 0) {
            sig_status <- "Positive Hit"
          } else {
            sig_status <- "Negative Hit"
          }
        }
      }
      
      results_df[i, ] <- list(
        GeneID = as.character(geneid[i]),
        GeneName = as.character(genenames[i]),
        Mean_Exp = mean_exp,
        Mean_Ctrl = mean_ctrl,
        Log2FC = log2fc,
        T_statistic = t_stat,
        P_value = p_val,
        D_value = d_val,
        Significant = sig_status
      )
    }
    
    # Count significant hits from SAM
    n_positive <- sum(results_df$Significant == "Positive Hit", na.rm = TRUE)
    n_negative <- sum(results_df$Significant == "Negative Hit", na.rm = TRUE)
    n_total_sig <- n_positive + n_negative
    
    # Get median FDR
    median_fdr <- if (n_total_sig > 0) {
      median(results_df$Q_value[results_df$Significant != "Not Significant"], na.rm = TRUE)
    } else {
      NA
    }
    
    cat(sprintf("  - Total significant genes (SAM delta=%.2f): %d\n", delta, n_total_sig))
    cat(sprintf("  - Upregulated genes: %d\n", n_positive))
    cat(sprintf("  - Downregulated genes: %d\n", n_negative))
    if (!is.na(median_fdr)) {
      cat(sprintf("  - Median FDR: %.2f%%\n", median_fdr))
    }
    
    # Save individual results to CSV
    pos_hits <- results_df[results_df$Significant == "Positive Hit", ]
    neg_hits <- results_df[results_df$Significant == "Negative Hit", ]
    all_results <- results_df
    
    write.csv(all_results, file.path(output_folder, paste0(tools::file_path_sans_ext(file_name), "_all_results.csv")), row.names = FALSE)
    write.csv(pos_hits, file.path(output_folder, paste0(tools::file_path_sans_ext(file_name), "_positive_hits.csv")), row.names = FALSE)
    write.csv(neg_hits, file.path(output_folder, paste0(tools::file_path_sans_ext(file_name), "_negative_hits.csv")), row.names = FALSE)
    
    # Store results including SAM objects
    results[[file_name]] <- list(
      data = results_df,
      positive_hits = pos_hits,
      negative_hits = neg_hits,
      n_genes = nrow(x),
      samr_obj = samr_obj,
      delta_table = delta_table,
      median_fdr = median_fdr,
      n_samples_exp = length(exp_idx),
      n_samples_ctrl = length(ctrl_idx),
      n_positive = n_positive,
      n_negative = n_negative,
      n_significant = n_total_sig
    )
    
    cat(sprintf("  - Analysis complete!\n\n"))
    
  }, error = function(e) {
    cat(sprintf("  - Error processing %s: %s\n\n", file_name, e$message))
  })
}

# Generate Interactive HTML report
cat("Generating Interactive HTML report...\n")

html_output <- file.path(output_folder, "analysis_report_interactive.html")

# Create HTML content with interactive features
html_content <- sprintf('
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <title>T-test Analysis Report - Interactive</title>
  <style>
    * { box-sizing: border-box; }
    body {
      font-family: "Segoe UI", Arial, sans-serif;
      margin: 0;
      padding: 20px;
      background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%);
      min-height: 100vh;
    }
    .container {
      max-width: 1400px;
      margin: 0 auto;
      background-color: white;
      padding: 40px;
      border-radius: 12px;
      box-shadow: 0 10px 40px rgba(0,0,0,0.2);
    }
    h1 {
      color: #2c3e50;
      border-bottom: 4px solid #667eea;
      padding-bottom: 15px;
      margin-bottom: 30px;
      font-size: 2.2em;
    }
    h2 {
      color: #34495e;
      margin-top: 40px;
      border-left: 5px solid #667eea;
      padding-left: 15px;
      font-size: 1.6em;
    }
    h3 {
      color: #5a6c7d;
      margin-top: 25px;
      font-size: 1.3em;
    }
    .info-box {
      background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%);
      color: white;
      padding: 25px;
      border-radius: 8px;
      margin: 20px 0;
      box-shadow: 0 4px 6px rgba(0,0,0,0.1);
    }
    .info-box strong {
      color: #fff;
      text-shadow: 0 1px 2px rgba(0,0,0,0.2);
    }
    .metrics-grid {
      display: grid;
      grid-template-columns: repeat(auto-fit, minmax(200px, 1fr));
      gap: 20px;
      margin: 30px 0;
    }
    .metric-card {
      background: white;
      border: 2px solid #e0e0e0;
      border-radius: 8px;
      padding: 20px;
      text-align: center;
      transition: all 0.3s;
      box-shadow: 0 2px 4px rgba(0,0,0,0.05);
    }
    .metric-card:hover {
      transform: translateY(-5px);
      box-shadow: 0 8px 16px rgba(0,0,0,0.15);
      border-color: #667eea;
    }
    .metric-label {
      color: #7f8c8d;
      font-size: 0.9em;
      font-weight: 600;
      text-transform: uppercase;
      margin-bottom: 10px;
    }
    .metric-value {
      font-size: 2.5em;
      font-weight: bold;
      color: #2c3e50;
    }
    .metric-value.positive { color: #27ae60; }
    .metric-value.negative { color: #e74c3c; }
    .metric-value.total { color: #667eea; }
    
    /* Filter controls */
    .controls {
      background-color: #f8f9fa;
      padding: 20px;
      border-radius: 8px;
      margin: 20px 0;
      border: 1px solid #dee2e6;
    }
    .control-group {
      display: inline-block;
      margin-right: 20px;
      margin-bottom: 10px;
    }
    .control-group label {
      display: block;
      margin-bottom: 5px;
      font-weight: 600;
      color: #495057;
    }
    .control-group input, .control-group select {
      padding: 8px 12px;
      border: 1px solid #ced4da;
      border-radius: 4px;
      font-size: 14px;
    }
    .control-group button {
      padding: 10px 20px;
      background-color: #667eea;
      color: white;
      border: none;
      border-radius: 4px;
      cursor: pointer;
      font-size: 14px;
      font-weight: 600;
      transition: background-color 0.3s;
    }
    .control-group button:hover {
      background-color: #5568d3;
    }
    
    /* Table styles */
    .table-container {
      overflow-x: auto;
      margin: 20px 0;
      border-radius: 8px;
      box-shadow: 0 2px 8px rgba(0,0,0,0.1);
    }
    table {
      border-collapse: collapse;
      width: 100%%;
      background: white;
    }
    th {
      background: linear-gradient(135deg, #667eea 0%%, #764ba2 100%%);
      color: white;
      padding: 15px;
      text-align: left;
      font-weight: 600;
      cursor: pointer;
      position: sticky;
      top: 0;
      z-index: 10;
    }
    th:hover {
      background: linear-gradient(135deg, #5568d3 0%%, #653a8b 100%%);
    }
    td {
      border: 1px solid #ddd;
      padding: 12px;
    }
    tr:nth-child(even) {
      background-color: #f8f9fa;
    }
    tr:hover {
      background-color: #e9ecef;
    }
    .positive-hit { background-color: #d4edda !important; }
    .negative-hit { background-color: #f8d7da !important; }
    
    /* Badges */
    .badge {
      display: inline-block;
      padding: 4px 10px;
      border-radius: 12px;
      font-size: 0.85em;
      font-weight: 600;
    }
    .badge-positive {
      background-color: #d4edda;
      color: #155724;
    }
    .badge-negative {
      background-color: #f8d7da;
      color: #721c24;
    }
    .badge-neutral {
      background-color: #e2e3e5;
      color: #383d41;
    }
    
    /* Download buttons */
    .download-section {
      margin: 30px 0;
      padding: 20px;
      background-color: #f8f9fa;
      border-radius: 8px;
    }
    .download-btn {
      display: inline-block;
      padding: 12px 24px;
      margin: 5px;
      background-color: #28a745;
      color: white;
      text-decoration: none;
      border-radius: 4px;
      font-weight: 600;
      transition: background-color 0.3s;
    }
    .download-btn:hover {
      background-color: #218838;
    }
    
    .timestamp {
      color: #6c757d;
      font-size: 0.9em;
      font-style: italic;
    }
  </style>
</head>
<body>
  <div class="container">
    <h1>🔬 T-test Proteomics Analysis Report</h1>
    <p class="timestamp">Generated: %s</p>
    
    <div class="info-box">
      <strong>Input Folder:</strong> %s<br>
      <strong>Output Folder:</strong> %s<br>
      <strong>Log2 Fold Change Cutoff:</strong> ±%.2f<br>
      <strong>D-value Cutoff:</strong> ±%.2f<br>
      <strong>Files Processed:</strong> %d / %d
    </div>
',
  format(Sys.time(), "%%Y-%%m-%%d %%H:%%M:%%S"),
  input_folder,
  output_folder,
  log2fc_cutoff,
  d_value_cutoff,
  length(results),
  length(excel_files)
)

# Add summary statistics
total_genes <- 0
total_positive <- 0
total_negative <- 0
total_significant <- 0

for (file_name in names(results)) {
  result <- results[[file_name]]
  total_genes <- total_genes + result$n_genes
  total_positive <- total_positive + result$n_positive
  total_negative <- total_negative + result$n_negative
  total_significant <- total_significant + result$n_significant
}

html_content <- paste0(html_content, sprintf('
    <h2>📊 Summary Statistics</h2>
    <div class="metrics-grid">
      <div class="metric-card">
        <div class="metric-label">Total Genes</div>
        <div class="metric-value">%d</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Significant Hits</div>
        <div class="metric-value total">%d</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Positive Hits</div>
        <div class="metric-value positive">%d</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Negative Hits</div>
        <div class="metric-value negative">%d</div>
      </div>
    </div>
', total_genes, total_significant, total_positive, total_negative))

# Add detailed results for each file
for (file_name in names(results)) {
  result <- results[[file_name]]
  
  html_content <- paste0(html_content, sprintf('
    <h2>📄 Results: %s</h2>
    
    <div class="metrics-grid">
      <div class="metric-card">
        <div class="metric-label">Total Genes</div>
        <div class="metric-value">%d</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Exp Samples</div>
        <div class="metric-value">%d</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Ctrl Samples</div>
        <div class="metric-value">%d</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Positive Hits</div>
        <div class="metric-value positive">%d</div>
      </div>
      <div class="metric-card">
        <div class="metric-label">Negative Hits</div>
        <div class="metric-value negative">%d</div>
      </div>
    </div>
    
    <div class="download-section">
      <h3>📥 Download Results</h3>
      <a href="%s_all_results.csv" class="download-btn" download>⬇ All Results</a>
      <a href="%s_positive_hits.csv" class="download-btn" download>⬆ Positive Hits</a>
      <a href="%s_negative_hits.csv" class="download-btn" download>⬇ Negative Hits</a>
    </div>
    
    <h3>Filter Results</h3>
    <div class="controls">
      <div class="control-group">
        <label for="filter_%s">Filter by Status:</label>
        <select id="filter_%s" onchange="filterTable_%s()">
          <option value="all">All Results</option>
          <option value="Positive Hit">Positive Hits Only</option>
          <option value="Negative Hit">Negative Hits Only</option>
          <option value="significant">All Significant</option>
        </select>
      </div>
      <div class="control-group">
        <label for="search_%s">Search:</label>
        <input type="text" id="search_%s" onkeyup="filterTable_%s()" placeholder="Search genes...">
      </div>
    </div>
    
    <h3>Top 50 Significant Hits</h3>
    <div class="table-container">
      <table id="table_%s">
        <thead>
          <tr>
            <th onclick="sortTable_%s(0)">Gene ID</th>
            <th onclick="sortTable_%s(1)">Gene Name</th>
            <th onclick="sortTable_%s(2)">Mean Exp</th>
            <th onclick="sortTable_%s(3)">Mean Ctrl</th>
            <th onclick="sortTable_%s(4)">Log2 FC</th>
            <th onclick="sortTable_%s(5)">T-statistic</th>
            <th onclick="sortTable_%s(6)">P-value</th>
            <th onclick="sortTable_%s(7)">D-value</th>
            <th onclick="sortTable_%s(8)">Status</th>
          </tr>
        </thead>
        <tbody>
  ', file_name, 
     result$n_genes, result$n_samples_exp, result$n_samples_ctrl, 
     result$n_positive, result$n_negative,
     tools::file_path_sans_ext(file_name),
     tools::file_path_sans_ext(file_name),
     tools::file_path_sans_ext(file_name),
     gsub("[^a-zA-Z0-9]", "_", file_name),
     gsub("[^a-zA-Z0-9]", "_", file_name),
     gsub("[^a-zA-Z0-9]", "_", file_name),
     gsub("[^a-zA-Z0-9]", "_", file_name),
     gsub("[^a-zA-Z0-9]", "_", file_name),
     gsub("[^a-zA-Z0-9]", "_", file_name),
     gsub("[^a-zA-Z0-9]", "_", file_name),
     gsub("[^a-zA-Z0-9]", "_", file_name),
     gsub("[^a-zA-Z0-9]", "_", file_name),
     gsub("[^a-zA-Z0-9]", "_", file_name),
     gsub("[^a-zA-Z0-9]", "_", file_name),
     gsub("[^a-zA-Z0-9]", "_", file_name),
     gsub("[^a-zA-Z0-9]", "_", file_name),
     gsub("[^a-zA-Z0-9]", "_", file_name),
     gsub("[^a-zA-Z0-9]", "_", file_name)))
  
  # Sort by absolute log2FC and show top 50 significant
  sig_data <- result$data[result$data$Significant != "Not Significant", ]
  if (nrow(sig_data) > 0) {
    sig_data <- sig_data[order(-abs(sig_data$Log2FC)), ]
    sig_data <- head(sig_data, 50)
    
    for (i in 1:nrow(sig_data)) {
      row <- sig_data[i, ]
      row_class <- ""
      badge_class <- "badge-neutral"
      
      if (row$Significant == "Positive Hit") {
        row_class <- "positive-hit"
        badge_class <- "badge-positive"
      } else if (row$Significant == "Negative Hit") {
        row_class <- "negative-hit"
        badge_class <- "badge-negative"
      }
      
      html_content <- paste0(html_content, sprintf('
          <tr class="%s">
            <td>%s</td>
            <td><strong>%s</strong></td>
            <td>%.2f</td>
            <td>%.2f</td>
            <td><strong>%.3f</strong></td>
            <td>%.3f</td>
            <td>%.2e</td>
            <td><strong>%.3f</strong></td>
            <td><span class="badge %s">%s</span></td>
          </tr>
      ', row_class, row$GeneID, row$GeneName, row$Mean_Exp, row$Mean_Ctrl,
         row$Log2FC, row$T_statistic, row$P_value, row$D_value,
         badge_class, row$Significant))
    }
  }
  
  html_content <- paste0(html_content, '
        </tbody>
      </table>
    </div>
  ')
  
  # Add JavaScript for filtering and sorting
  safe_id <- gsub("[^a-zA-Z0-9]", "_", file_name)
  html_content <- paste0(html_content, sprintf('
    <script>
    function filterTable_%s() {
      var filter = document.getElementById("filter_%s").value;
      var search = document.getElementById("search_%s").value.toUpperCase();
      var table = document.getElementById("table_%s");
      var tr = table.getElementsByTagName("tr");
      
      for (var i = 1; i < tr.length; i++) {
        var showRow = true;
        var td = tr[i].getElementsByTagName("td");
        
        // Filter by status
        if (filter !== "all") {
          var statusCell = td[8].textContent;
          if (filter === "significant") {
            showRow = statusCell !== "Not Significant";
          } else {
            showRow = statusCell === filter;
          }
        }
        
        // Search filter
        if (showRow && search) {
          var found = false;
          for (var j = 0; j < td.length; j++) {
            if (td[j].textContent.toUpperCase().indexOf(search) > -1) {
              found = true;
              break;
            }
          }
          showRow = found;
        }
        
        tr[i].style.display = showRow ? "" : "none";
      }
    }
    
    function sortTable_%s(col) {
      var table = document.getElementById("table_%s");
      var rows = Array.from(table.rows).slice(1);
      var dir = table.dataset.sortDir === "asc" ? "desc" : "asc";
      table.dataset.sortDir = dir;
      
      rows.sort(function(a, b) {
        var aVal = a.cells[col].textContent;
        var bVal = b.cells[col].textContent;
        
        if (!isNaN(aVal) && !isNaN(bVal)) {
          aVal = parseFloat(aVal);
          bVal = parseFloat(bVal);
        }
        
        if (dir === "asc") {
          return aVal > bVal ? 1 : -1;
        } else {
          return aVal < bVal ? 1 : -1;
        }
      });
      
      rows.forEach(function(row) {
        table.tBodies[0].appendChild(row);
      });
    }
    </script>
  ', safe_id, safe_id, safe_id, safe_id, safe_id, safe_id))
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
rdata_output <- file.path(output_folder, "sam_analysis_results.RData")
save(results, delta, min_foldchange, file = rdata_output)

cat(sprintf("\n✓ SAM Pipeline complete!\n"))
cat(sprintf("  - Interactive HTML report: %s\n", html_output))
cat(sprintf("  - R data: %s\n", rdata_output))
cat(sprintf("  - CSV files saved for each dataset\n"))
cat(sprintf("\nSAM Analysis Summary:\n"))
cat(sprintf("  - Delta threshold: %.2f\n", delta))
cat(sprintf("  - Minimum fold change: %.2f\n", min_foldchange))
cat(sprintf("  - Permutations: 100\n"))
cat(sprintf("  - CSV files saved for each dataset\n"))
cat(sprintf("\nSAM Analysis Summary:\n"))
cat(sprintf("  - Delta threshold: %.2f\n", delta))
cat(sprintf("  - Minimum fold change: %.2f\n", min_foldchange))
cat(sprintf("  - Permutations: 100\n"))
