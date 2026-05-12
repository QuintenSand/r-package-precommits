## Hook: no-browser-statement
## Fails if any R file contains an uncommented browser() call.

files <- commandArgs(trailingOnly = TRUE)
violations <- character()

for (f in files) {
  lines <- readLines(f, warn = FALSE)
  # Match `browser(` not preceded by `#` on the same line (crude but effective).
  hits <- grep("^[^#]*\\bbrowser\\s*\\(", lines)
  if (length(hits)) {
    violations <- c(violations, sprintf("  %s:%d: %s", f, hits, lines[hits]))
  }
}

if (length(violations)) {
  cat("Found browser() calls:\n", paste(violations, collapse = "\n"), "\n", sep = "")
  quit(status = 1)
}
