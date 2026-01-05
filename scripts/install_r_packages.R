#!/usr/bin/env Rscript

# R Package Installer for SAM Proteomics Pipeline
# This script installs all required R packages with multiple fallback methods

cat("Installing R packages for SAM Proteomics Pipeline\n")
cat("==================================================\n\n")

# Required packages
required_packages <- c("samr")
bioc_packages <- c("impute")

# Multiple CRAN mirrors for fallback
cran_mirrors <- c(
  "https://cloud.r-project.org",
  "https://cran.rstudio.com",
  "https://cran.r-project.org",
  "https://mirror.las.iastate.edu/CRAN/"
)

# Function to install package with multiple methods
install_package_robust <- function(pkg) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("✓ %s already installed\n", pkg))
    return(TRUE)
  }
  
  cat(sprintf("Installing %s...\n", pkg))
  
  # Method 1: Try CRAN mirrors
  for (mirror in cran_mirrors) {
    tryCatch({
      install.packages(pkg, repos = mirror, quiet = TRUE)
      if (requireNamespace(pkg, quietly = TRUE)) {
        cat(sprintf("✓ %s installed from %s\n", pkg, mirror))
        return(TRUE)
      }
    }, error = function(e) {
      cat(sprintf("  Failed with mirror %s\n", mirror))
    })
  }
  
  # Method 2: Try from source (GitHub)
  if (pkg == "samr") {
    cat("  Trying GitHub installation...\n")
    tryCatch({
      if (!requireNamespace("remotes", quietly = TRUE)) {
        install.packages("remotes", repos = cran_mirrors[1], quiet = TRUE)
      }
      remotes::install_github("cran/samr", quiet = TRUE)
      if (requireNamespace(pkg, quietly = TRUE)) {
        cat(sprintf("✓ %s installed from GitHub\n", pkg))
        return(TRUE)
      }
    }, error = function(e) {
      cat("  GitHub installation failed\n")
    })
  }
  
  # Method 3: Try BiocManager as fallback
  cat("  Trying BiocManager...\n")
  tryCatch({
    if (!requireNamespace("BiocManager", quietly = TRUE)) {
      install.packages("BiocManager", repos = cran_mirrors[1], quiet = TRUE)
    }
    BiocManager::install(pkg, update = FALSE, ask = FALSE)
    if (requireNamespace(pkg, quietly = TRUE)) {
      cat(sprintf("✓ %s installed via BiocManager\n", pkg))
      return(TRUE)
    }
  }, error = function(e) {
    cat("  BiocManager installation failed\n")
  })
  
  return(FALSE)
}

# Install CRAN packages
cat("Installing CRAN packages...\n")
for (pkg in required_packages) {
  if (!install_package_robust(pkg)) {
    cat(sprintf("✗ Failed to install %s - please install manually\n", pkg))
    cat(sprintf("  Try: install.packages('%s')\n", pkg))
  }
}

# Install Bioconductor packages
cat("\nInstalling Bioconductor packages...\n")
if (!requireNamespace("BiocManager", quietly = TRUE)) {
  install.packages("BiocManager", repos = cran_mirrors[1], quiet = TRUE)
}

for (pkg in bioc_packages) {
  if (!requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("Installing %s...\n", pkg))
    tryCatch({
      BiocManager::install(pkg, update = FALSE, ask = FALSE)
      cat(sprintf("✓ %s installed\n", pkg))
    }, error = function(e) {
      cat(sprintf("✗ Failed to install %s\n", pkg))
      cat(sprintf("  Error: %s\n", e$message))
    })
  } else {
    cat(sprintf("✓ %s already installed\n", pkg))
  }
}

# Verify installations
cat("\n==================================================\n")
cat("Verifying installations...\n")
all_packages <- c(required_packages, bioc_packages)
failed <- character(0)
for (pkg in all_packages) {
  if (requireNamespace(pkg, quietly = TRUE)) {
    cat(sprintf("✓ %s is available\n", pkg))
  } else {
    cat(sprintf("✗ %s is NOT available\n", pkg))
    failed <- c(failed, pkg)
  }
}

if (length(failed) > 0) {
  cat("\n⚠ Some packages failed to install:\n")
  cat("Manual installation commands:\n")
  for (pkg in failed) {
    if (pkg %in% bioc_packages) {
      cat(sprintf("  BiocManager::install('%s')\n", pkg))
    } else {
      cat(sprintf("  install.packages('%s')\n", pkg))
    }
  }
} else {
  cat("\n✓ All R packages installed successfully!\n")
}
