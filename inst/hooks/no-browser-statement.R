## Hook: no-browser-statement
## Blocks the commit if any .R file contains a browser() call. Uses R's
## parser (getParseData) so calls inside strings or comments don't trip
## false positives.

files <- commandArgs(trailingOnly = TRUE)
files <- files[grepl("\\.R$", files, ignore.case = TRUE)]
violations <- character()

for (f in files) {
  pd <- tryCatch(
    utils::getParseData(parse(file = f, keep.source = TRUE)),
    error = function(e) NULL
  )
  if (is.null(pd) || nrow(pd) == 0L) next
  hits <- pd[pd$token == "SYMBOL_FUNCTION_CALL" & pd$text == "browser", ,
             drop = FALSE]
  if (nrow(hits) > 0L) {
    violations <- c(
      violations,
      sprintf("  %s:%d:%d: browser()", f, hits$line1, hits$col1)
    )
  }
}

if (length(violations)) {
  cat("Found browser() calls (remove before committing):\n",
      paste(violations, collapse = "\n"), "\n", sep = "")
  quit(status = 1)
}
