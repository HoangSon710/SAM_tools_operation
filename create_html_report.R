#!/usr/bin/env Rscript

# Simple HTML Report Generator
# No additional libraries needed - uses base R

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
    .filter-group { display: flex; flex-direction: column; }
    .filter-group label { font-weight: 600; margin-bottom: 5px; color: #495057; }
    .filter-group input { padding: 8px 12px; border: 1px solid #ced4da; border-radius: 4px; font-size: 14px; width: 120px; }
    .filter-btn { padding: 10px 20px; background: #28a745; color: white; border: none; border-radius: 4px; cursor: pointer; font-weight: 600; margin-top: 20px; }
    .filter-btn:hover { background: #218838; }
    .reset-btn { background: #6c757d; }
    .reset-btn:hover { background: #5a6268; }
    .plot-container { margin: 30px 0; background: white; padding: 20px; border-radius: 8px; box-shadow: 0 1px 4px rgba(0,0,0,0.1); }
    #filtered-stats { display: none; margin-top: 20px; padding: 15px; background: #e7f3ff; border-left: 4px solid #3498db; border-radius: 4px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🔬 T-test Proteomics Analysis Report</h1>
    <p><strong>Generated:</strong> ', format(Sys.time(), "%Y-%m-%d %H:%M:%S"), '</p>
    <p><strong>Analysis Cutoffs:</strong> Log2 FC ≥ ±', log2fc_cutoff, ' | D-value ≥ ±', d_value_cutoff, '</p>
    
    <div class="filter-panel">
      <h3>🔍 Interactive Filtering</h3>
      <div class="filter-row">
        <div class="filter-group">
          <label for="minLog2FC">Min |Log2 FC|:</label>
          <input type="number" id="minLog2FC" value="0" step="0.1" min="0">
        </div>
        <div class="filter-group">
          <label for="minDValue">Min |D-value|:</label>
          <input type="number" id="minDValue" value="0" step="0.1" min="0">
        </div>
        <div class="filter-group">
          <label for="maxPValue">Max P-value:</label>
          <input type="number" id="maxPValue" value="1" step="0.01" min="0" max="1">
        </div>
        <div style="margin-top: 20px;">
          <button class="filter-btn" onclick="applyFilters()">Apply Filters</button>
          <button class="filter-btn reset-btn" onclick="resetFilters()">Reset</button>
        </div>
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
      <h3>Volcano Plot (Log2 FC vs -log10 P-value)</h3>
      <div id="volcanoPlot" style="height: 600px;"></div>
    </div>
    
    <div class="plot-container">
      <h3>MA Plot (Mean Expression vs Log2 FC)</h3>
      <div id="maPlot" style="height: 600px;"></div>
    </div>
    
    <div class="plot-container">
      <h3>D-value Distribution</h3>
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
    
    let positiveTable, negativeTable;
    
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
      
      // Create plots
      createVolcanoPlot(allData);
      createMAPlot(allData);
      createDvaluePlot(allData);
    });
    
    function applyFilters() {
      const minLog2FC = parseFloat(document.getElementById("minLog2FC").value) || 0;
      const minDValue = parseFloat(document.getElementById("minDValue").value) || 0;
      const maxPValue = parseFloat(document.getElementById("maxPValue").value) || 1;
      
      const filtered = allData.filter(d => 
        Math.abs(d.log2fc) >= minLog2FC && 
        Math.abs(d.dval) >= minDValue && 
        d.pval <= maxPValue
      );
      
      const posFiltered = filtered.filter(d => d.log2fc > 0 && d.dval > 0);
      const negFiltered = filtered.filter(d => d.log2fc < 0 && d.dval < 0);
      
      // Update statistics
      document.getElementById("filtered-stats").innerHTML = `
        <strong>Filtered Results:</strong> 
        ${filtered.length} total genes | 
        ${posFiltered.length} positive hits | 
        ${negFiltered.length} negative hits
      `;
      document.getElementById("filtered-stats").style.display = "block";
      
      // Update plots with filtered data
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
      document.getElementById("filtered-stats").style.display = "none";
      
      createVolcanoPlot(allData);
      createMAPlot(allData);
      createDvaluePlot(allData);
      
      positiveTable.clear();
      negativeTable.clear();
      location.reload(); // Reload to restore original data
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
      
      Plotly.newPlot("volcanoPlot", [trace3, trace1, trace2], layout);
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
      
      Plotly.newPlot("maPlot", [trace3, trace1, trace2], layout);
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
      
      Plotly.newPlot("dvaluePlot", [trace], layout);
    }
    </script>
  </div>
</body>
</html>', file = html_file, append = TRUE)

cat("HTML report created successfully!\n")
