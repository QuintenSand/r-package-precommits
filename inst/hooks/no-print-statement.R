## Hook: no-print-statement   (not enabled by default in the shared YAML)
## Blocks the commit if any .R file outside tests/, inst/, vignettes/
## contains a print() call. Encourage cli::cli_*() or message() in
## production code instead.

files <- commandArgs(trailingOnly = TRUE)
files <- files[grepl("\\.R$", files, ignore.case = TRUE)]
files <- files[!grepl("(^|/)(tests|inst|vignettes)/", files)]
violations <- character()

for (f in files) {
  pd <- tryCatch(
    utils::getParseData(parse(file = f, keep.source = TRUE)),
    error = function(e) NULL
  )
  if (is.null(pd) || nrow(pd) == 0L) next
  hits <- pd[pd$token == "SYMBOL_FUNCTION_CALL" & pd$text == "print", ,
             drop = FALSE]
  if (nrow(hits) > 0L) {
    violations <- c(
      violations,
      sprintf("  %s:%d:%d: print()", f, hits$line1, hits$col1)
    )
  }
}

if (length(violations)) {
  cat("Found print() calls (prefer cli::cli_alert/message):\n",
      paste(violations, collapse = "\n"), "\n", sep = "")
  quit(status = 1)
}
