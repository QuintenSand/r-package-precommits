## Hook: check-yaml
## Validates YAML files using the 'yaml' package.

files <- commandArgs(trailingOnly = TRUE)
files <- files[grepl("\\.(ya?ml)$", files, ignore.case = TRUE)]
if (length(files) == 0L) quit(status = 0)

if (!requireNamespace("yaml", quietly = TRUE)) {
  cat("yaml package not installed; skipping check-yaml.\n",
      "Install with: install.packages('yaml')\n",
      file = stderr())
  quit(status = 0)
}

errors <- character()
for (f in files) {
  out <- tryCatch(yaml::yaml.load_file(f), error = function(e) e)
  if (inherits(out, "error")) {
    errors <- c(errors, sprintf("  %s: %s", f, conditionMessage(out)))
  }
}

if (length(errors)) {
  cat("Invalid YAML:\n", paste(errors, collapse = "\n"), "\n", sep = "")
  quit(status = 1)
}
