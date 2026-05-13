## Hook: check-added-large-files
## Blocks files larger than max_kb (default 2 MB) from being committed.

files <- commandArgs(trailingOnly = TRUE)
max_kb <- 2048L
violations <- character()

for (f in files) {
  if (!file.exists(f) || dir.exists(f)) next
  size_kb <- file.info(f)$size / 1024
  if (isTRUE(size_kb > max_kb)) {
    violations <- c(
      violations,
      sprintf("  %s: %.1f KB (> %d KB limit)", f, size_kb, max_kb)
    )
  }
}

if (length(violations)) {
  cat("Large file(s) detected. Use git-lfs or add to .gitignore:\n",
      paste(violations, collapse = "\n"), "\n", sep = "")
  quit(status = 1)
}
