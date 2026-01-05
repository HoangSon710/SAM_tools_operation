#!/bin/bash

# Alternative installation methods for samr package
# This script provides multiple ways to install samr if the standard method fails

echo "================================================"
echo "Alternative samr Installation Methods"
echo "================================================"
echo ""

# Method 1: Direct R installation with multiple mirrors
echo "Method 1: Installing from CRAN with multiple mirrors..."
Rscript -e '
mirrors <- c(
  "https://cloud.r-project.org",
  "https://cran.rstudio.com",
  "https://cran.r-project.org",
  "https://mirror.las.iastate.edu/CRAN/"
)

for (mirror in mirrors) {
  cat(sprintf("Trying mirror: %s\n", mirror))
  tryCatch({
    install.packages("samr", repos = mirror)
    if (requireNamespace("samr", quietly = TRUE)) {
      cat("✓ samr installed successfully!\n")
      quit(save = "no", status = 0)
    }
  }, error = function(e) {
    cat(sprintf("Failed: %s\n", e$message))
  })
}
cat("Method 1 failed\n")
' && echo "✓ Method 1 succeeded!" && exit 0

echo ""
echo "Method 2: Installing from source tarball..."
wget https://cran.r-project.org/src/contrib/samr_3.0.tar.gz -O /tmp/samr_3.0.tar.gz
R CMD INSTALL /tmp/samr_3.0.tar.gz && echo "✓ Method 2 succeeded!" && exit 0

echo ""
echo "Method 3: Installing via BiocManager..."
Rscript -e '
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager")
}
BiocManager::install("samr", update = FALSE, ask = FALSE)
if (requireNamespace("samr", quietly = TRUE)) {
  cat("✓ samr installed successfully via BiocManager!\n")
  quit(save = "no", status = 0)
}
' && echo "✓ Method 3 succeeded!" && exit 0

echo ""
echo "Method 4: Installing from GitHub..."
Rscript -e '
if (!requireNamespace("remotes", quietly = TRUE)) {
  install.packages("remotes")
}
remotes::install_github("cran/samr")
if (requireNamespace("samr", quietly = TRUE)) {
  cat("✓ samr installed successfully from GitHub!\n")
  quit(save = "no", status = 0)
}
' && echo "✓ Method 4 succeeded!" && exit 0

echo ""
echo "Method 5: Installing via devtools..."
Rscript -e '
if (!requireNamespace("devtools", quietly = TRUE)) {
  install.packages("devtools")
}
devtools::install_version("samr", version = "3.0")
if (requireNamespace("samr", quietly = TRUE)) {
  cat("✓ samr installed successfully via devtools!\n")
  quit(save = "no", status = 0)
}
' && echo "✓ Method 5 succeeded!" && exit 0

echo ""
echo "================================================"
echo "⚠ All installation methods failed"
echo "================================================"
echo ""
echo "Manual installation steps:"
echo "1. Open R console: R"
echo "2. Run: install.packages('samr')"
echo "3. Or try: BiocManager::install('samr')"
echo ""
echo "System requirements:"
echo "- R >= 4.0.0"
echo "- gcc/gfortran compiler"
echo "- Development tools (build-essential on Ubuntu)"
echo ""
echo "Install build tools:"
echo "  Ubuntu/Debian: sudo apt-get install build-essential gfortran"
echo "  CentOS/RHEL: sudo yum install gcc gcc-gfortran"
echo "  macOS: xcode-select --install"
echo ""

exit 1
