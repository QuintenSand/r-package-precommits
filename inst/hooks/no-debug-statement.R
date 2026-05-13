## Hook: no-debug-statement
## Blocks the commit if any .R file contains a debug(), debugonce() or
## undebug() call.

files <- commandArgs(trailingOnly = TRUE)
files <- files[grepl("\\.R$", files, ignore.case = TRUE)]
forbidden <- c("debug", "debugonce", "undebug")
violations <- character()

for (f in files) {
  pd <- tryCatch(
    utils::getParseData(parse(file = f, keep.source = TRUE)),
    error = function(e) NULL
  )
  if (is.null(pd) || nrow(pd) == 0L) next
  hits <- pd[pd$token == "SYMBOL_FUNCTION_CALL" & pd$text %in% forbidden, ,
             drop = FALSE]
  if (nrow(hits) > 0L) {
    violations <- c(
      violations,
      sprintf("  %s:%d:%d: %s()", f, hits$line1, hits$col1, hits$text)
    )
  }
}

if (length(violations)) {
  cat("Found debug calls (remove before committing):\n",
      paste(violations, collapse = "\n"), "\n", sep = "")
  quit(status = 1)
}
