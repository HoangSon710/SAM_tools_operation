#!/usr/bin/env Rscript

# SAM Analysis HTML Report Generator
# Generates interactive HTML reports for SAM (Significance Analysis of Microarrays) results

args <- commandArgs(trailingOnly = TRUE)
output_folder <- args[1]
delta <- as.numeric(args[2])
min_foldchange <- as.numeric(args[3])

# Read the CSV files
all_results <- read.csv(file.path(output_folder, "sam_input_all_results.csv"))
pos_hits <- read.csv(file.path(output_folder, "sam_input_positive_hits.csv"))
neg_hits <- read.csv(file.path(output_folder, "sam_input_negative_hits.csv"))

# Extract sample information from input file
input_file <- file.path(dirname(output_folder), "preprocessing_gpr", "sam_input.csv")
if (!file.exists(input_file)) {
  # Try alternative location
  input_file <- file.path("preprocessing_gpr", "sam_input.csv")
}

sample_names <- c()
exp_samples <- c()
ctrl_samples <- c()
n_exp <- 0
n_ctrl <- 0

if (file.exists(input_file)) {
  # Read first two rows to get groups and sample names
  header_data <- read.csv(input_file, header = FALSE, nrows = 2, stringsAsFactors = FALSE)
  
  # Extract group labels (row 1, skip first 2 columns which are gene ID/name)
  groups <- as.numeric(header_data[1, -c(1, 2)])
  
  # Get column names from the file header (if present)
  conn <- file(input_file, "r")
  first_line <- readLines(conn, n = 1)
  close(conn)
  
  # Parse sample names from column headers
  col_headers <- strsplit(first_line, ",")[[1]]
  if (length(col_headers) > 2) {
    sample_names <- col_headers[-c(1, 2)]  # Remove gene ID and gene name columns
    sample_names <- gsub('"', '', sample_names)  # Remove quotes
    
    # If sample names are empty or just numbers, generate default names
    if (all(sample_names == "" | grepl("^[0-9.]+$", sample_names))) {
      sample_names <- paste0("Sample_", seq_along(groups))
    }
    
    # Categorize samples by group
    exp_samples <- sample_names[groups == 1]
    ctrl_samples <- sample_names[groups == 2]
    n_exp <- length(exp_samples)
    n_ctrl <- length(ctrl_samples)
  }
}

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
  <script src="https://cdn.plot.ly/plotly-2.27.0.min.js"></script>
  <style>
    body { font-family: Arial, sans-serif; margin: 20px; background: #f5f5f5; }
    .container { max-width: 1600px; margin: 0 auto; background: white; padding: 30px; border-radius: 8px; box-shadow: 0 2px 8px rgba(0,0,0,0.1); }
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
    .filter-panel { background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; border: 2px solid #e9ecef; }
    .filter-row { display: flex; gap: 20px; align-items: center; flex-wrap: wrap; }
    .filter-group { display: flex; flex-direction: column; flex: 1; min-width: 250px; }
    .filter-group label { font-weight: 600; margin-bottom: 5px; color: #495057; display: flex; justify-content: space-between; }
    .filter-group input[type="range"] { width: 100%; }
    .slider-value { color: #3498db; font-weight: bold; }
    .filter-group input { padding: 8px 12px; border: 1px solid #ced4da; border-radius: 4px; font-size: 14px; width: 120px; }
    .filter-btn { padding: 10px 20px; background: #28a745; color: white; border: none; border-radius: 4px; cursor: pointer; font-weight: 600; margin-top: 20px; }
    .filter-btn:hover { background: #218838; }
    .reset-btn { background: #6c757d; }
    .reset-btn:hover { background: #5a6268; }
    .plot-container { margin: 30px 0; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 1px 4px rgba(0,0,0,0.1); }
    #filtered-stats { display: none; margin-top: 20px; padding: 15px; background: #e7f3ff; border-left: 4px solid #3498db; border-radius: 4px; }
    .auto-filter-notice { background: #d1ecf1; color: #0c5460; padding: 10px; border-radius: 4px; margin-bottom: 15px; font-size: 14px; border-left: 4px solid #17a2b8; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🔬 SAM Proteomics Analysis Report</h1>
    <p><strong>Generated:</strong> ', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '</p>
    <p><strong>Analysis Method:</strong> SAM (Significance Analysis of Microarrays)</p>
    <p><strong>Parameters:</strong> Delta = ', delta, ' | Min Fold Change = ', min_foldchange, '</p>
    
    <div style="background: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0; border-left: 4px solid #3498db;">
      <h3 style="margin-top: 0;">📋 Sample Information</h3>
      <div style="display: grid; grid-template-columns: 1fr 1fr; gap: 20px;">
        <div>
          <p><strong>Experimental Group (', n_exp, ' samples):</strong></p>
          <p style="margin-left: 20px; color: #2c5282;">', 
            if(length(exp_samples) > 0) paste(exp_samples, collapse = ", ") else "No samples", 
          '</p>
        </div>
        <div>
          <p><strong>Control Group (', n_ctrl, ' samples):</strong></p>
          <p style="margin-left: 20px; color: #2c5282;">', 
            if(length(ctrl_samples) > 0) paste(ctrl_samples, collapse = ", ") else "No samples", 
          '</p>
        </div>
      </div>
    </div>
    
    <div class="filter-panel">
      <h3>🔍 Interactive Filtering (Auto-Update)</h3>
      <div class="auto-filter-notice">
        ℹ️ Drag the sliders below to filter results in real-time. Tables and plots update automatically!
      </div>
      <div class="filter-row">
        <div class="filter-group">
          <label>
            <span>Min |Log2 FC|:</span>
            <span class="slider-value" id="log2fcValue">0.0</span>
          </label>
          <input type="range" id="minLog2FC" min="0" max="5" step="0.1" value="0" oninput="updateFilters()">
        </div>
        <div class="filter-group">
          <label>
            <span>Min |D-value|:</span>
            <span class="slider-value" id="dvalueValue">0.0</span>
          </label>
          <input type="range" id="minDValue" min="0" max="10" step="0.1" value="0" oninput="updateFilters()">
        </div>
        <div class="filter-group">
          <label>
            <span>Max P-value:</span>
            <span class="slider-value" id="pvalueValue">1.0</span>
          </label>
          <input type="range" id="maxPValue" min="0" max="1" step="0.01" value="1" oninput="updateFilters()">
        </div>
      </div>
      <div style="margin-top: 15px;">
        <button class="filter-btn reset-btn" onclick="resetFilters()">Reset All Filters</button>
      </div>
      <div id="filtered-stats"></div>
    </div>
    
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
    
    <h2>📊 Visualization Plots</h2>
    <div class="plot-container">
      <h3>🔥 Heatmap (Top 50 Significant Genes)</h3>
      <div id="heatmapPlot" style="height: 800px;"></div>
    </div>
    
    <div class="plot-container">
      <h3>🌋 Volcano Plot (Log2 FC vs -log10 P-value)</h3>
      <div id="volcanoPlot" style="height: 600px;"></div>
    </div>
    
    <div class="plot-container">
      <h3>📈 MA Plot (Mean Expression vs Log2 FC)</h3>
      <div id="maPlot" style="height: 600px;"></div>
    </div>
    
    <div class="plot-container">
      <h3>📊 D-value Distribution</h3>
      <div id="dvaluePlot" style="height: 500px;"></div>
    </div>
    
    <script>
    // All data for filtering and plotting
    const allData = [
', file = html_file, append = TRUE)

# Add all data as JavaScript array
for (i in 1:nrow(all_results)) {
  row <- all_results[i, ]
  cat(sprintf('      {geneID: "%s", geneName: "%s", meanExp: %.2f, meanCtrl: %.2f, log2fc: %.3f, tstat: %.3f, pval: %.6e, dval: %.3f},\n',
      row$GeneID, row$GeneName, row$Mean_Exp, row$Mean_Ctrl, row$Log2FC, 
      row$T_statistic, row$P_value, row$D_value), file = html_file, append = TRUE)
}

cat('    ];
    
    // Sample expression data for heatmap
    const sampleNames = [', 
    paste0('"', c(exp_samples, ctrl_samples), '"', collapse = ", "),
    '];
    const sampleGroups = [',
    paste0(rep(1, n_exp), collapse = ", "), ', ', paste0(rep(2, n_ctrl), collapse = ", "),
    '];
    
    let positiveTable, negativeTable;
    let currentFilteredData = allData;
    
    $(document).ready(function() {
      positiveTable = $("#positiveTable").DataTable({
        pageLength: 25,
        order: [[4, "desc"]],
        columnDefs: [
          { targets: [2,3,4,5,6,7], className: "dt-right" }
        ]
      });
      negativeTable = $("#negativeTable").DataTable({
        pageLength: 25,
        order: [[4, "asc"]],
        columnDefs: [
          { targets: [2,3,4,5,6,7], className: "dt-right" }
        ]
      });
      
      // Create plots with initial data
      createHeatmap(allData);
      createVolcanoPlot(allData);
      createMAPlot(allData);
      createDvaluePlot(allData);
      
      // Initialize filter displays
      updateFilters();
    });
    
    function updateFilters() {
      const minLog2FC = parseFloat(document.getElementById("minLog2FC").value) || 0;
      const minDValue = parseFloat(document.getElementById("minDValue").value) || 0;
      const maxPValue = parseFloat(document.getElementById("maxPValue").value) || 1;
      
      // Update slider value displays
      document.getElementById("log2fcValue").textContent = minLog2FC.toFixed(1);
      document.getElementById("dvalueValue").textContent = minDValue.toFixed(1);
      document.getElementById("pvalueValue").textContent = maxPValue.toFixed(2);
      
      // Apply filters
      applyFilters();
    }
    
    function applyFilters() {
      const minLog2FC = parseFloat(document.getElementById("minLog2FC").value) || 0;
      const minDValue = parseFloat(document.getElementById("minDValue").value) || 0;
      const maxPValue = parseFloat(document.getElementById("maxPValue").value) || 1;
      
      const filtered = allData.filter(d => 
        Math.abs(d.log2fc) >= minLog2FC && 
        Math.abs(d.dval) >= minDValue && 
        d.pval <= maxPValue
      );
      
      currentFilteredData = filtered;
      
      const posFiltered = filtered.filter(d => d.log2fc > 0 && d.dval > 0);
      const negFiltered = filtered.filter(d => d.log2fc < 0 && d.dval < 0);
      
      // Update statistics
      if (minLog2FC > 0 || minDValue > 0 || maxPValue < 1) {
        document.getElementById("filtered-stats").innerHTML = `
          <strong>📊 Filtered Results:</strong> 
          ${filtered.length} total genes | 
          <span style="color: #38ef7d;">▲ ${posFiltered.length} positive hits</span> | 
          <span style="color: #f45c43;">▼ ${negFiltered.length} negative hits</span>
        `;
        document.getElementById("filtered-stats").style.display = "block";
      } else {
        document.getElementById("filtered-stats").style.display = "none";
      }
      
      // Update plots with filtered data
      createHeatmap(filtered);
      createVolcanoPlot(filtered);
      createMAPlot(filtered);
      createDvaluePlot(filtered);
      
      // Update tables
      updateTable(positiveTable, posFiltered);
      updateTable(negativeTable, negFiltered);
    }
    
    function resetFilters() {
      document.getElementById("minLog2FC").value = 0;
      document.getElementById("minDValue").value = 0;
      document.getElementById("maxPValue").value = 1;
      updateFilters();
    }
    
    function updateTable(table, data) {
      table.clear();
      data.slice(0, 100).forEach(d => {
        table.row.add([
          d.geneID,
          `<strong>${d.geneName}</strong>`,
          d.meanExp.toFixed(2),
          d.meanCtrl.toFixed(2),
          `<strong>${d.log2fc.toFixed(3)}</strong>`,
          d.tstat.toFixed(3),
          d.pval.toExponential(2),
          `<strong>${d.dval.toFixed(3)}</strong>`
        ]);
      });
      table.draw();
    }
    
    function createHeatmap(data) {
      // Get top 50 most significant genes (by absolute D-value)
      const sortedData = [...data].sort((a, b) => Math.abs(b.dval) - Math.abs(a.dval)).slice(0, 50);
      
      if (sortedData.length === 0) {
        document.getElementById("heatmapPlot").innerHTML = "<p style=\'text-align: center; padding: 50px; color: #999;\'>No data to display. Adjust filters to see results.</p>";
        return;
      }
      
      // Create expression matrix (log2 normalized values for visualization)
      const geneNames = sortedData.map(d => d.geneName || d.geneID);
      const zValues = sortedData.map(d => {
        // Create row with exp samples then control samples
        const expVals = Array(sampleGroups.filter(g => g === 1).length).fill(d.meanExp);
        const ctrlVals = Array(sampleGroups.filter(g => g === 2).length).fill(d.meanCtrl);
        return [...expVals, ...ctrlVals];
      });
      
      // Create annotations for sample groups
      const sampleAnnotations = sampleNames.map((name, idx) => ({
        x: idx,
        y: -1,
        text: sampleGroups[idx] === 1 ? "Exp" : "Ctrl",
        showarrow: false,
        font: { size: 10, color: sampleGroups[idx] === 1 ? "#38ef7d" : "#f45c43" }
      }));
      
      const trace = {
        z: zValues,
        x: sampleNames,
        y: geneNames,
        type: "heatmap",
        colorscale: [
          [0, "#313695"],
          [0.25, "#4575b4"],
          [0.5, "#ffffbf"],
          [0.75, "#f46d43"],
          [1, "#a50026"]
        ],
        colorbar: {
          title: "Expression<br>(log2)",
          titleside: "right"
        },
        hoverongaps: false,
        hovertemplate: "Gene: %{y}<br>Sample: %{x}<br>Expression: %{z:.2f}<extra></extra>"
      };
      
      const layout = {
        title: {
          text: `Top ${sortedData.length} Genes by |D-value|`,
          font: { size: 16 }
        },
        xaxis: { 
          title: "Samples",
          tickangle: -45,
          side: "bottom"
        },
        yaxis: { 
          title: "Genes",
          automargin: true
        },
        margin: { l: 150, r: 100, t: 80, b: 120 },
        annotations: sampleAnnotations
      };
      
      Plotly.newPlot("heatmapPlot", [trace], layout, {responsive: true});
    }
    
    function createVolcanoPlot(data) {
      const posData = data.filter(d => d.log2fc > 0 && d.dval > 0);
      const negData = data.filter(d => d.log2fc < 0 && d.dval < 0);
      const nsData = data.filter(d => !(d.log2fc > 0 && d.dval > 0) && !(d.log2fc < 0 && d.dval < 0));
      
      const trace1 = {
        x: posData.map(d => d.log2fc),
        y: posData.map(d => -Math.log10(d.pval)),
        mode: "markers",
        type: "scatter",
        name: "Positive Hits",
        marker: { color: "#38ef7d", size: 6 },
        text: posData.map(d => `${d.geneName}<br>Log2FC: ${d.log2fc.toFixed(3)}<br>P-val: ${d.pval.toExponential(2)}<br>D-val: ${d.dval.toFixed(3)}`),
        hovertemplate: "%{text}<extra></extra>"
      };
      
      const trace2 = {
        x: negData.map(d => d.log2fc),
        y: negData.map(d => -Math.log10(d.pval)),
        mode: "markers",
        type: "scatter",
        name: "Negative Hits",
        marker: { color: "#f45c43", size: 6 },
        text: negData.map(d => `${d.geneName}<br>Log2FC: ${d.log2fc.toFixed(3)}<br>P-val: ${d.pval.toExponential(2)}<br>D-val: ${d.dval.toFixed(3)}`),
        hovertemplate: "%{text}<extra></extra>"
      };
      
      const trace3 = {
        x: nsData.map(d => d.log2fc),
        y: nsData.map(d => -Math.log10(d.pval)),
        mode: "markers",
        type: "scatter",
        name: "Not Significant",
        marker: { color: "#bdc3c7", size: 4, opacity: 0.5 },
        text: nsData.map(d => `${d.geneName}<br>Log2FC: ${d.log2fc.toFixed(3)}<br>P-val: ${d.pval.toExponential(2)}`),
        hovertemplate: "%{text}<extra></extra>"
      };
      
      const layout = {
        xaxis: { title: "Log2 Fold Change", zeroline: true },
        yaxis: { title: "-log10(P-value)" },
        hovermode: "closest",
        showlegend: true
      };
      
      Plotly.newPlot("volcanoPlot", [trace3, trace1, trace2], layout, {responsive: true});
    }
    
    function createMAPlot(data) {
      const posData = data.filter(d => d.log2fc > 0 && d.dval > 0);
      const negData = data.filter(d => d.log2fc < 0 && d.dval < 0);
      const nsData = data.filter(d => !(d.log2fc > 0 && d.dval > 0) && !(d.log2fc < 0 && d.dval < 0));
      
      const trace1 = {
        x: posData.map(d => (d.meanExp + d.meanCtrl) / 2),
        y: posData.map(d => d.log2fc),
        mode: "markers",
        type: "scatter",
        name: "Positive Hits",
        marker: { color: "#38ef7d", size: 6 },
        text: posData.map(d => `${d.geneName}<br>Mean: ${((d.meanExp + d.meanCtrl) / 2).toFixed(2)}<br>Log2FC: ${d.log2fc.toFixed(3)}`),
        hovertemplate: "%{text}<extra></extra>"
      };
      
      const trace2 = {
        x: negData.map(d => (d.meanExp + d.meanCtrl) / 2),
        y: negData.map(d => d.log2fc),
        mode: "markers",
        type: "scatter",
        name: "Negative Hits",
        marker: { color: "#f45c43", size: 6 },
        text: negData.map(d => `${d.geneName}<br>Mean: ${((d.meanExp + d.meanCtrl) / 2).toFixed(2)}<br>Log2FC: ${d.log2fc.toFixed(3)}`),
        hovertemplate: "%{text}<extra></extra>"
      };
      
      const trace3 = {
        x: nsData.map(d => (d.meanExp + d.meanCtrl) / 2),
        y: nsData.map(d => d.log2fc),
        mode: "markers",
        type: "scatter",
        name: "Not Significant",
        marker: { color: "#bdc3c7", size: 4, opacity: 0.5 },
        text: nsData.map(d => `${d.geneName}<br>Mean: ${((d.meanExp + d.meanCtrl) / 2).toFixed(2)}<br>Log2FC: ${d.log2fc.toFixed(3)}`),
        hovertemplate: "%{text}<extra></extra>"
      };
      
      const layout = {
        xaxis: { title: "Mean Expression (log2)", type: "log" },
        yaxis: { title: "Log2 Fold Change", zeroline: true },
        hovermode: "closest",
        showlegend: true
      };
      
      Plotly.newPlot("maPlot", [trace3, trace1, trace2], layout, {responsive: true});
    }
    
    function createDvaluePlot(data) {
      const dvalues = data.map(d => d.dval);
      
      const trace = {
        x: dvalues,
        type: "histogram",
        nbinsx: 50,
        marker: { color: "#3498db" },
        name: "D-value"
      };
      
      const layout = {
        xaxis: { title: "D-value (Effect Size)" },
        yaxis: { title: "Frequency" },
        bargap: 0.05
      };
      
      Plotly.newPlot("dvaluePlot", [trace], layout, {responsive: true});
    }
    </script>
  </div>
</body>
</html>', file = html_file, append = TRUE)

cat("HTML report created successfully!\n")
