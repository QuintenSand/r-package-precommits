## Hook: check-merge-conflict
## Detects leftover `<<<<<<<`, `=======`, `>>>>>>>` markers.

files <- commandArgs(trailingOnly = TRUE)
violations <- character()

for (f in files) {
  if (!file.exists(f) || dir.exists(f)) next
  lines <- tryCatch(
    readLines(f, warn = FALSE, encoding = "UTF-8"),
    error = function(e) NULL
  )
  if (is.null(lines)) next
  hits <- grep("^(<{7}|={7}|>{7})( |$)", lines)
  if (length(hits)) {
    violations <- c(
      violations,
      sprintf("  %s:%d: %s", f, hits, lines[hits])
    )
  }
}

if (length(violations)) {
  cat("Found merge-conflict markers:\n",
      paste(violations, collapse = "\n"), "\n", sep = "")
  quit(status = 1)
}
