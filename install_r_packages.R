#!/usr/bin/env Rscript

# R Package Installer for SAM Proteomics Pipeline
# This script installs all required R packages

cat("Installing R packages for SAM Proteomics Pipeline\n")
cat("==================================================\n\n")

# Required packages
required_packages <- c("samr")
bioc_packages <- c("impute")

# Install CRAN packages
cat("Installing CRAN packages...\n")
for (pkg in required_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("Installing %s...\n", pkg))
    install.packages(pkg, repos = "https://cloud.r-project.org", quiet = TRUE)
  } else {
    cat(sprintf("✓ %s already installed\n", pkg))
  }
}

# Install Bioconductor packages
cat("\nInstalling Bioconductor packages...\n")
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager", repos = "https://cloud.r-project.org", quiet = TRUE)
}

for (pkg in bioc_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("Installing %s...\n", pkg))
    BiocManager::install(pkg, update = FALSE, ask = FALSE)
  } else {
    cat(sprintf("✓ %s already installed\n", pkg))
  }
}

cat("\n✓ All R packages installed successfully!\n")
